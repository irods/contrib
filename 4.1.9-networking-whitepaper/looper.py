from __future__ import print_function
import errno
import logging
import optparse
import os
import subprocess
import sys
import time

script_path = os.path.dirname(os.path.realpath(__file__))

def mkdir_p(path):
    try:
        os.makedirs(path)
    except OSError as exc: # Python >2.5
        if exc.errno == errno.EEXIST and os.path.isdir(path):
            pass
        else: raise

def run_cmd(cmd, run_env=False, unsafe_shell=False, check_rc=False):
    log = logging.getLogger(__name__)
    # run it
    if run_env == False:
        run_env = os.environ.copy()
    log.debug('run_env: {0}'.format(run_env))
    log.info('running: {0}, unsafe_shell={1}, check_rc={2}'.format(cmd, unsafe_shell, check_rc))
    if unsafe_shell == True:
        p = subprocess.Popen(cmd, env=run_env, stdout=subprocess.PIPE, stderr=subprocess.PIPE, shell=True)
    else:
        p = subprocess.Popen(cmd, env=run_env, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
    (out, err) = p.communicate()
    log.info('  stdout: {0}'.format(out.strip()))
    log.info('  stderr: {0}'.format(err.strip()))
    log.info('')
    if check_rc != False:
        if p.returncode != 0:
            log.error(check_rc)
            sys.exit(p.returncode)
    return p.returncode

def set_delay(device, milliseconds):
    run_cmd(['sudo', 'tc', 'qdisc', 'del', 'dev', device, 'root', 'netem'], check_rc=True)
    run_cmd(['sudo', 'tc', 'qdisc', 'add', 'dev', device, 'root', 'netem', 'delay', '{0}ms'.format(milliseconds)], check_rc=True)



def set_tcp_settings(connection_string, size):
    if size == 'default':
        cmds = [
                ['sudo', 'sysctl', 'net.ipv4.tcp_rmem=\'4096        87380   6291456\''],
                ['sudo', 'sysctl', 'net.ipv4.tcp_wmem=\'4096        16384   4194304\''],
                ['sudo', 'sysctl', 'net.core.rmem_max=212992'],
                ['sudo', 'sysctl', 'net.core.wmem_max=212992']
        ]
    elif size == 'big':
        cmds = [
                ['sudo', 'sysctl', 'net.ipv4.tcp_rmem=\'4096        87380   104857600\''],
                ['sudo', 'sysctl', 'net.ipv4.tcp_wmem=\'4096        87380   104857600\''],
                ['sudo', 'sysctl', 'net.core.rmem_max=104857600'],
                ['sudo', 'sysctl', 'net.core.wmem_max=104857600']
        ]
    else:
        sys.exit('invalid tcp setting [{0}]'.format(size))
    for cmd in cmds:
        run_cmd(" ".join(cmd), unsafe_shell=True, check_rc=True)
    for cmd in cmds:
        remotecmd = ['ssh', '-t', connection_string, " ".join(cmd)]
        run_cmd(remotecmd, check_rc=True)


def set_parallel_buffer_size(connection_string, megabytes):
    keyname='irods_transfer_buffer_size_for_parallel_transfer_in_megabytes'

    # remote
    sedcmd = 'sed -i -e \'s,{0}": [0-9]*,{0}": {1},\''.format(keyname, megabytes)
    filename='/var/lib/irods/.irods/irods_environment.json'
    remotecmd=['sudo', '{0} {1}'.format(sedcmd, filename)]
    sshcmd=['ssh', '-t', connection_string]
    sshcmd.extend(remotecmd)
    run_cmd(sshcmd, check_rc=True)

    # local
    filename=os.path.expanduser('~/.irods/irods_environment.json')
    localcmd=['sed', '-i', '-e', 's,{0}": [0-9]*,{0}": {1},'.format(keyname, megabytes)]
    localcmd.extend([filename])
    run_cmd(localcmd, check_rc=True)


def main():
    # check parameters
    usage = 'Usage: %prog [options] user@host delay_device results_file'
    parser = optparse.OptionParser(usage)
    parser.add_option('-q', '--quiet', action='store_const', const=0, dest='verbosity', help='print less information to stdout')
    parser.add_option('-v', '--verbose', action='count', dest='verbosity', default=1, help='print more information to stdout')
    (options, args) = parser.parse_args()
    if len(args) != 3:
        parser.error('incorrect number of arguments')
    if len(args) == 0:
        parser.print_usage()
        return 1

    # configure logging
    log = logging.getLogger()
    if options.verbosity >= 2:
        log.setLevel(logging.DEBUG)
    elif options.verbosity == 1:
        log.setLevel(logging.INFO)
    else:
        log.setLevel(logging.WARNING)
    ch = logging.StreamHandler()
    formatter = logging.Formatter('%(levelname)s - %(message)s')
    ch.setFormatter(formatter)
    log.addHandler(ch)

    # setup
    connection_string = args[0]
    delay_device = args[1]
    results_file = args[2]
    targetdir = 'results'
    itargetdir = 'speedtest'

    filesize_array    = ['1', '5', '10']
    delay_array       = ['0', '50', '100']
    tcp_size_array    = ['default', 'big']
    buffer_size_array = ['4', '50', '100']
    num_threads_array = ['1', '2', '3', '4', '8', '16']
    runs_of_each      = 3

    # csv headers
    with open(os.path.join(script_path, results_file), 'a') as f:
        f.write('GB,delay,tcp_size,parallel_buffer,N,run,seconds\n')

    # BIGLOOP
    for filesize in filesize_array:
        filename = '{0}Gfile'.format(filesize)
        run_cmd(['truncate', '-s{0}G'.format(filesize), filename], check_rc=True)
        mkdir_p(os.path.join(script_path, targetdir, '{0}G'.format(filesize)))
        for delay in delay_array:
            set_delay(delay_device, delay)
            for tcp_size in tcp_size_array:
                set_tcp_settings(connection_string, tcp_size)
                for buffer_size in buffer_size_array:
                    set_parallel_buffer_size(connection_string, buffer_size)
                    for num_threads in num_threads_array:
                        for run in range(1, runs_of_each+1):
                            run_cmd(['imkdir', '-p', itargetdir], check_rc=True)
                            ifilename = '{0}/N{1}'.format(itargetdir, num_threads)
                            cmd = ['iput', '-v', '-N{0}'.format(num_threads), filename, ifilename]
                            start = time.time()
                            run_cmd(cmd, check_rc=True)
                            end = time.time()
                            duration = end - start
                            with open(os.path.join(script_path, results_file), 'a') as f:
                                line = [filesize, delay, tcp_size, buffer_size, num_threads, str(run), str(duration)]
                                f.write(','.join(line))
                                f.write('\n')
                            run_cmd(['irm', '-rf', itargetdir], check_rc=True)
        os.unlink(filename)


if __name__ == '__main__':
    sys.exit(main())

