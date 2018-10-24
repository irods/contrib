import argparse
import os
import subprocess
from irods.session import iRODSSession

def log(x):
    if (args.verbose == True):
        print(x)

def recover_collection(c):
    log(['collection',c.path])
    for d in c.data_objects:
        recover_data_object(d)
    for s in c.subcollections:
        recover_collection(s)

def recover_data_object(d):
    log(['data_object', d.path])
    for r in d.replicas:
        if (r.resource_name == args.target_resource):
            for m in d.metadata.items():
                if (m.name == 'filesystem::perms'):
                    log(['PERMS',m.value,r.path])
                    subprocess.Popen(['chmod',m.value,r.path]).communicate()
                if (m.name == 'filesystem::owner'):
                    log(['OWNER',m.value,r.path])
                    subprocess.Popen(['chown',m.value,r.path]).communicate()
                if (m.name == 'filesystem::group'):
                    log(['GROUP',m.value,r.path])
                    subprocess.Popen(['chgrp',m.value,r.path]).communicate()
                if (m.name == 'filesystem::atime'):
                    log(['ATIME',m.value,r.path])
                    subprocess.Popen(['touch','-c',r.path,'-a','-d',m.value]).communicate()
                if (m.name == 'filesystem::mtime'):
                    log(['MTIME',m.value,r.path])
                    subprocess.Popen(['touch','-c',r.path,'-m','-d',m.value]).communicate()

# set up arguments
d = '''Recover filesystem attributes for iRODS data objects.

Will restore permissions, owner, group, atime, and ctime from
the iRODS Catalog to files located on target_resource.

Must be run as root (due to chown).

1) Create valid local iRODS environment JSON file (e.g. rootenv.json)
{
    "irods_host": "x.x.x.x",
    "irods_port": 1247,
    "irods_user_name": "xxxxx",
    "irods_zone_name": "xxxxxZone",
    "irods_authentication_file": "/full/path/to/rootA"
}

2) Initialize iRODS authentication file
$ sudo IRODS_ENVIRONMENT_FILE=rootenv.json iinit
Enter your current iRODS password:

3) Execute this script via sudo
$ sudo IRODS_ENVIRONMENT_FILE=rootenv.json python restore_unixstat_to_resource.py <logical_path> <resource_name>

'''
parser = argparse.ArgumentParser(description=d, formatter_class=argparse.RawTextHelpFormatter)
parser.add_argument('logical_path', help='Logical Path (Collection)')
parser.add_argument('target_resource', help='Target Resource Name')
parser.add_argument('-v', '--verbose', help="print more information to stdout", action="store_true")
args = parser.parse_args()

# get environment
try:
    env_file = os.environ['IRODS_ENVIRONMENT_FILE']
except KeyError:
    env_file = os.path.expanduser('~/.irods/irods_environment.json')

# connect and apply catalog filesystem metadata to collection
with iRODSSession(irods_env_file=env_file) as session:
    coll = session.collections.get(args.logical_path.rstrip('/'))
    log(['initial',coll.path])
    recover_collection(coll)

