#!/usr/bin/env python
from __future__ import print_function

import argparse
import logging
import os
import sys
import time
from minio import Minio
try:
    from os import scandir
except ImportError:
    from scandir import scandir

def profile_s3(endpoint_domain,
            region_name,
            keypair,
            proxy_url,
            path):

    log = logging.getLogger(__name__)

    with open(keypair) as f:
        access_key = f.readline().rstrip()
        secret_key = f.readline().rstrip()

    if proxy_url is None:
        http_client = None
    else:
        import urllib3
        http_client = urllib3.ProxyManager(
                                proxy_url,
                                timeout=urllib3.Timeout.DEFAULT_TIMEOUT,
                                cert_reqs='CERT_REQUIRED',
                                retries=urllib3.Retry(
                                    total=5,
                                    backoff_factor=0.2,
                                    status_forcelist=[500, 502, 503, 504]
                                )
                     )
    client = Minio(
                 endpoint_domain,
                 access_key=access_key,
                 secret_key=secret_key,
                 http_client=http_client)

    # Split provided path into bucket and source folder "prefix"
    path_list = path.lstrip('/').split('/', 1)
    bucket_name = path_list[0]
    if len(path_list) == 1:
        prefix = ''
    else:
        prefix = path_list[1]
    log.info('prefix is [{0}]'.format(prefix))
    itr = client.list_objects_v2(bucket_name, prefix=prefix, recursive=True)

    log.debug('starting profile_s3 for [{0}]'.format(path))
    stats = { 'folders': 0, 'objects': 0 }
    for entry in itr:
        if entry.object_name.endswith('/'):
            log.debug('folder - '+entry.object_name)
            stats['folders'] += 1
        else:
            log.debug('object - '+entry.object_name)
            stats['objects'] += 1
    log.debug('{0} s3 stats'.format(stats))
    log.debug('leaving profile_s3 for [{0}]'.format(path))
    return stats

def profile_local(path, stats=None):
    log = logging.getLogger(__name__)
    log.debug('starting profile_local for [{0}]'.format(path))
    if stats is None:
        stats = { 'dirs': 0, 'files': 0, 'symlinks': 0, 'dirs_without_permission': 0, 'files_without_permission': 0 }
    try:
         itr = scandir(path)
    except NotADirectoryError:
        log.error('[{0}] is not a directory'.format(path))
        sys.exit(1)
    try:
        for entry in itr:
            if entry.is_dir():
                stats['dirs'] += 1
                stats = profile_local(entry.path, stats)
            if entry.is_file():
                stats['files'] += 1
            if entry.is_symlink():
                stats['symlinks'] += 1
    except PermissionError as e:
        log.debug('permission denied: [{0}]'.format(e))
        stats['dirs_without_permission'] += 1
    except OSError as e:
        log.error('os error: [{0}]'.format(e))
        sys.exit(1)
    log.debug('{0} local stats'.format(stats))
    log.debug('leaving profile_local for [{0}]'.format(path))
    return stats

def main():
    # configure arguments
    parser = argparse.ArgumentParser()
    parser.add_argument('physical_path', action='store', type=str, default=None, help='Physical path to be profiled')
    group = parser.add_mutually_exclusive_group()
    group.add_argument('-q', '--quiet', action='store_true', help='Print less information to stdout')
    group.add_argument('-v', '--verbose', action='store_true', help='Print more information to stdout')
    parser.add_argument('--s3_endpoint_domain', action="store", type=str, default='s3.amazonaws.com', help='S3 endpoint domain')
    parser.add_argument('--s3_region_name', action="store", type=str, default='us-east-1', help='S3 region name')
    parser.add_argument('--s3_keypair', action='store', type=str, default=None, help='Path to S3 keypair file')
    parser.add_argument('--s3_proxy_url', action='store', type=str, default=None, help='URL to proxy for S3 access')
    args = parser.parse_args()
    if not args.physical_path.startswith('/'):
        parser.error("physical_path [{0}] must be an absolute path".format(args.physical_path))

    # configure logging
    log = logging.getLogger()
    if args.verbose:
        log.setLevel(logging.DEBUG)
    elif args.quiet:
        log.setLevel(logging.WARNING)
    else:
        log.setLevel(logging.INFO)
    ch = logging.StreamHandler(sys.stdout)
    formatter = logging.Formatter('%(levelname)s - %(message)s')
    ch.setFormatter(formatter)
    log.addHandler(ch)

    # timer start
    start_time = time.time()

    # s3
    if args.s3_keypair is not None:
        log.debug('s3_endpoint_domain  [{0}]'.format(args.s3_endpoint_domain))
        log.debug('s3_region_name      [{0}]'.format(args.s3_region_name))
        log.debug('s3_keypair          [{0}]'.format(args.s3_keypair))
        log.debug('s3_proxy_url        [{0}]'.format(args.s3_proxy_url))
        log.debug('s3 physical_path    [{0}]'.format(args.physical_path))
        stats = profile_s3(args.s3_endpoint_domain,
                args.s3_region_name,
                args.s3_keypair,
                args.s3_proxy_url,
                args.physical_path)
        stats['s3_physical_path'] = args.physical_path
    # local
    else:
        log.debug('local physical_path [{0}]'.format(args.physical_path))
        stats = profile_local(args.physical_path)
        stats['local_physical_path'] = args.physical_path

    # timer finish
    elapsed_time = time.time() - start_time
    stats['elapsed_time'] = time.strftime("%H:%M:%S", time.gmtime(elapsed_time))

    # done
    log.info(stats)

if __name__ == '__main__':
    sys.exit(main())

