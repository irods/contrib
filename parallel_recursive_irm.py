#!/usr/bin/env python

import argparse
import datetime
import os
import pprint
import re
import subprocess
import ssl
import sys

try:
    from irods.exception import CollectionDoesNotExist
    from irods.session import iRODSSession
except ImportError as e:
    print('ERROR: python-irodsclient module is missing, try:')
    print('  pip install python-irodsclient')
    sys.exit(1)


def log(x):
    if (args.verbose == True):
        pp = pprint.PrettyPrinter(indent=4)
        pp.pprint(x)

def add_to_tree(tree, collection, level):
    if level not in tree:
        tree[level] = set()
    # add collection
    tree[level].add(collection)
    # add any subcollections
    for c in collection.subcollections:
        tree = add_to_tree(tree, c, level + 1)
    return tree

def produce_commands_for_tree(tree, operation):
    # prepare target command directory
    cmd_dir = 'irm_' + operation + '_' + datetime.datetime.now().strftime('%Y%m%dT%H%M%S')
    os.mkdir(cmd_dir)
    log(['command directory', os.path.realpath(cmd_dir)])
    # prepare command string
    if operation == 'unregister':
        cmd = 'irm -r -U "{0}"\n'
    elif operation == 'trash':
        cmd = 'irm -r "{0}"\n'
    elif operation == 'force':
        cmd = 'irm -r -f "{0}"\n'
    else:
        print('operation [{0}] not implemented'.format(operation))
        sys.exit(1)
    # walk tree
    for i in tree:
        filename = '{0}/{1}.sh'.format(cmd_dir, i)
        with open(filename, 'w') as f:
            for c in tree[i]:
                escaped_path = c.path.replace('$','\$').replace('"','\\"')
                f.write(cmd.format(escaped_path))
    return cmd_dir

def filename_to_int(f):
    return int(re.sub('[^0-9]','', f))

def run_commands(cmd_dir):
    # run files
    for i in sorted(os.listdir(cmd_dir), key=filename_to_int, reverse=True):
        cmd_file = os.path.join(cmd_dir, i)
        log(['running...', cmd_file])
        try:
            subprocess.Popen(['parallel'], stdin=open(cmd_file), shell=False).communicate()
        except OSError as e:
            if e.errno == os.errno.ENOENT:
                print('ERROR: gnu parallel not found in your $PATH')
                sys.exit(1)
            else:
                raise

########################

start_time = datetime.datetime.now()

d = '''Parallel Recursive Removal of a Logical Path

- Requires GNU Parallel
- Requires irm

- Available Operations:
  - 'unregister' (only remove from the catalog)
  - 'trash' (move to the trash, in both catalog and storage)
  - 'force' (really remove, from both catalog and storage)
'''
parser = argparse.ArgumentParser(description=d, formatter_class=argparse.RawTextHelpFormatter)
parser.add_argument('logical_path', help='Absolute Logical Path (Collection)')
parser.add_argument('operation', help='Operation Mode for irm', choices=['unregister', 'trash', 'force'])
parser.add_argument('-v', '--verbose', help="print more information to stdout", action="store_true")
args = parser.parse_args()

# get environment
try:
    env_file = os.environ['IRODS_ENVIRONMENT_FILE']
except KeyError:
    env_file = os.path.expanduser('~/.irods/irods_environment.json')

# get connection
ssl_context = ssl.create_default_context(purpose=ssl.Purpose.SERVER_AUTH, cafile=None, capath=None, cadata=None)
ssl_settings = {'ssl_context': ssl_context}
with iRODSSession(irods_env_file=env_file, **ssl_settings) as session:
    try:
        # get clean logical path
        lp = args.logical_path.rstrip('/')
        coll = session.collections.get(lp)
        log(['target_collection_path', coll.path])
        # build the tree
        tree = add_to_tree({}, coll, 0)
        log(['tree',tree])
        # produce directory of files with commands
        log(['operation', args.operation])
        cmd_dir = produce_commands_for_tree(tree, args.operation)
        # run commands
        run_commands(cmd_dir)
    except CollectionDoesNotExist:
        print('logical path ['+lp+'] does not exist')
        sys.exit(1)

end_time = datetime.datetime.now()
elapsed_seconds = datetime.datetime.utcfromtimestamp((end_time - start_time).total_seconds())

final_output = {}
final_output['logical_path'] = lp
final_output['levels'] = len(tree.keys())
final_output['elapsed_time'] = elapsed_seconds.strftime("%H:%M:%S")
final_output['operation'] = args.operation
print(final_output)
