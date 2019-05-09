#!/usr/bin/env python

import argparse
import datetime
import os
import pprint
import subprocess
import sys

from irods.exception import CollectionDoesNotExist
from irods.session import iRODSSession

def log(x):
    if (args.verbose == True):
        pp = pprint.PrettyPrinter(indent=4)
        pp.pprint(x)

def add_to_tree(tree, collection, level, max_depth):
    if level not in tree:
        tree[level] = set()
    # add collection
    tree[level].add(collection)
    # dig to max_depth
    if level < max_depth:
        # add any subcollections
        for c in collection.subcollections:
            tree = add_to_tree(tree, c, level + 1, max_depth)
    return tree

def produce_commands_for_tree(tree, operation):
    # prepare target command directory
    cmd_dir = 'irm_' + operation + '_' + datetime.datetime.now().strftime('%Y%m%dT%H%M%S')
    os.mkdir(cmd_dir)
    log(os.path.realpath(cmd_dir))
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
        filename = '{0}/{1}.txt'.format(cmd_dir, i)
        with open(filename, 'w') as f:
            for c in tree[i]:
                f.write(cmd.format(c.path))
    return cmd_dir

def run_commands(cmd_dir):
    # run files
    for i in sorted(os.listdir(cmd_dir), reverse=True):
        cmd_file = os.path.join(cmd_dir, i)
        log('running {0}...'.format(cmd_file))
        subprocess.Popen(['parallel'], stdin=open(cmd_file), shell=False).communicate()

d = '''Parallel Recursive Removal of a Logical Path

- Available Operations:
  - 'unregister' (default)
  - 'trash' (move to the trash)
  - 'force' (unlink from storage)
'''
parser = argparse.ArgumentParser(description=d, formatter_class=argparse.RawTextHelpFormatter)
parser.add_argument('logical_path', help='Absolute Logical Path (Collection)')
parser.add_argument('starting_depth', help='Starting Depth for Parallelism', type=int)
parser.add_argument('-v', '--verbose', help="print more information to stdout", action="store_true")
args = parser.parse_args()

# get environment
try:
    env_file = os.environ['IRODS_ENVIRONMENT_FILE']
except KeyError:
    env_file = os.path.expanduser('~/.irods/irods_environment.json')

# connect and apply catalog filesystem metadata to collection
with iRODSSession(irods_env_file=env_file) as session:
    try:
        lp = args.logical_path.rstrip('/')
        coll = session.collections.get(lp)
        log(['target_collection_path', coll.path])
        log(['starting_depth', args.starting_depth])
        # build the tree
        tree = add_to_tree({}, coll, 0, args.starting_depth)
        log(tree)
        # produce directory of files with commands
        cmd_dir = produce_commands_for_tree(tree, 'unregister')
        # run commands
        run_commands(cmd_dir)
    except CollectionDoesNotExist:
        print('logical path ['+lp+'] does not exist')
        sys.exit(1)
