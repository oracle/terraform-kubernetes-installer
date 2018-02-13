#!/usr/bin/env python
#
# Generally useful helper routines
#

import select
import subprocess
import time
import re
import os
import json
import logging
import textwrap
import glob as _glob
import string
import random
import ConfigParser
import errno
import shutil
import filecmp
import fileinput
import base64

DIR = os.path.abspath(os.path.dirname(__file__))
PROJECT_ROOT_DIR = os.path.abspath(DIR + '/..')
SCRIPTS_DIR = PROJECT_ROOT_DIR + '/scripts'
TEMPLATES_DIR = SCRIPTS_DIR + '/templates'
ENVS_DIR = os.path.abspath(DIR + '/..') + '/envs'
HOSTS_FILE_NAME = 'hosts'
FILES_DIR_NAME = 'files'
HEALTH_FILE_NAME = 'health.json'
TF_STATE_FILE_NAME = 'terraform.tfstate'
ID_RSA_FILE = 'id_rsa'
CA_CERT_FILE = 'ca.pem'
CA_KEY_FILE = 'ca-key.pem'
API_SERVER_CERT_FILE = 'apiserver.pem'
API_SERVER_KEY_FILE = 'apiserver-key.pem'
DECRYPTED_BACKUP_EXT = ".decrypted"
MANAGED_ENVS = ['dev', 'integ', 'prod']
PROXY_REGIONS = ['eu-frankfurt-1']

class ConsoleFormatter(object):
    """
    Custom formatter for console logging.
    """
    def format(self, record):
        if record.levelname != 'INFO':
            return ('%s - %s' % (record.levelname, record.msg))
        else:
            return record.msg

def setup_logging(log_file_name='log.log', log_dir=None,
                  file_logging_level=logging.DEBUG, console_logging_level=logging.INFO):
    """
    Creates and returns a logger of the given name, which logs to both a file and the console.
    """
    # remove log file if exist
    log_path = '%s/%s' % (log_dir or '/tmp' , log_file_name)
    if os.path.exists(log_path):
        os.remove(log_path)

    # create logger
    logger = logging.getLogger(log_file_name)
    logger.setLevel(logging.DEBUG)
    # create file handler - if log dir not specified, we'll pick one
    if log_dir != None:
        try:
            if not os.path.isdir(log_dir):
                os.mkdir(log_dir)
        except OSError as exc:
            if not (exc.errno == errno.EEXIST and os.path.isdir(log_dir)):
                raise 'Failed to create directory: %s' % log_dir
        fh = logging.FileHandler('%s/%s' % (log_dir, log_file_name))
    else:
        try:
            fh = logging.FileHandler('/var/log/%s' % log_file_name)
        except IOError, e:
            # if error try to open logger in /tmp
            try:
                fh = logging.FileHandler('/tmp/%s' % log_file_name)
            except IOError, e:
                # cannot get a fh throw it all away
                fh = logging.FileHandler('/dev/null')
    fh.setLevel(file_logging_level)

    # Add handlers if not already added
    if not len(logger.handlers):
        ch = logging.StreamHandler()
        ch.setLevel(console_logging_level)
        # create formatters and add them to the handlers
        formatter = logging.Formatter('%(asctime)s - %(levelname)s - %(message)s')
        ch.setFormatter(ConsoleFormatter())
        fh.setFormatter(formatter)
        # add the handlers to logger
        logger.addHandler(ch)
        logger.addHandler(fh)
    return logger

# Global default logger
logger = setup_logging('helpers.log')

def banner(as_banner, bold):
    """
    Logs a banner message.
    """
    if as_banner:
        if bold:
            logger.info('********************************************************')
        else:
            logger.info('--------------------------------------------------------')

def log(string, as_banner=False, bold=False):
    banner(as_banner, bold)
    logger.info(string)
    banner(as_banner, bold)

def verify_file_exists(file):
    if not os.path.exists(file):
        raise Exception('File %s doesn\'t exist' % file)

def write_cert_file(file_contents, file):
    f = open(file, 'w')
    f.write(file_contents + '\n')
    f.close()
    os.chmod(file, 0o600)

def process_stream(stream, read_fds, global_buf, line_buf, verbose=True, logger=logger):
    char = stream.read(1)
    if char == '':
        read_fds.remove(stream)
    global_buf.append(char)
    line_buf.append(char)
    if char == '\n':
        msg = ''.join(line_buf[0:-1])
        if verbose:
            logger.info(msg)
        else:
            logger.debug(msg)
        line_buf = []
    return line_buf

def poll(stdout, stderr, verbose=True, logger=logger):
    stdoutbuf = []
    stdoutbuf_line = []
    stderrbuf = []
    stderrbuf_line = []
    read_fds = [stdout, stderr]
    x_fds = [stdout, stderr]
    while read_fds:
        rlist, _, _ = select.select(read_fds, [], x_fds)
        if rlist:
            for stream in rlist:
                if stream == stdout:
                    stdoutbuf_line = process_stream(stream, read_fds, stdoutbuf, stdoutbuf_line, verbose=verbose, logger=logger)
                if stream == stderr:
                    stderrbuf_line = process_stream(stream, read_fds, stderrbuf, stderrbuf_line, verbose=verbose, logger=logger)
    return (''.join(stdoutbuf), ''.join(stderrbuf))

def run_command(cmd, cwd=os.getcwd(), env=os.environ, verbose=True, silent=False, logger=logger, verify_return_code=False):
    """
    Runs the given comand, returning the resulting stdout, stderr, and return code.
    """
    if not silent:
        logger.info(cmd)
    process = subprocess.Popen(cmd, stdout=subprocess.PIPE,
            stderr=subprocess.PIPE, shell=True, cwd=cwd, env=env)
    (stdout, stderr) = poll(process.stdout, process.stderr, verbose=verbose, logger=logger)
    returncode = process.wait()
    if verify_return_code and returncode != 0:
        raise Exception('Failed to run "%s" - error: %s' % (cmd, stderr))
    return (stdout, stderr, returncode)

def wait_until(predicate, timeout_seconds, delay_seconds=0.25, *args, **kwargs):
    """
    Calls a predicate repeatedly, up until a specified number of seconds,
    until it returns true, throgin an error if true is never returned by the predicate.  
    :param predicate: the predicate to evaluate
    :param timeout_seconds: seconds before timing out
    :param delay_seconds: seconds between evaluations
    """
    mustend = time.time() + timeout_seconds
    last_exception = None
    while time.time() < mustend:
        try:
            predicate(*args, **kwargs)
            return
        except Exception, e:
            last_exception = e
        time.sleep(delay_seconds)

    raise Exception('Condition not met within %i seconds, last Exception: %s' % (timeout_seconds, last_exception))

def find_value_in_yml_file(input_file, variable):
    """
    Returns the value corresponding to the given variable in the given YAML file.  Special 
    care is given to parsing ansible-vault secrets.  Using a YAML parsing library is another
    option, but it gets confused reading ansible-vault secret values.
    """

    # Do a multi-line regex to find the end of the value - once indentations _stop_
    with open(input_file, 'r') as myfile:
        file_content = myfile.read()
    m = re.search('^%s: (.*(\n .*)*)' % variable, file_content, re.MULTILINE)
    if m == None:
        return None
    value = m.groups()[0]

    if value.startswith("!vault"):
        # Ansible-vault values must have the first line chopped, and the rest dedented
        return textwrap.dedent('\n'.join(value.split('\n')[1:]))
    else:
        # For normal value, just return the token value, minus quotes
        if re.findall(r'"(.*)"', value):
            return value[1:-1]
        else:
            return value

def utf_encode_list(list):
    return [s.encode('UTF8') for s in list]

def glob(pattern, excludes=None):
    """
    Standard Python glob function, with string exclusion.
    """
    glob_list = _glob.glob(pattern)
    if excludes != None:
        tmp_list = []
        for element in glob_list:
            if not any(exclude in element for exclude in excludes):
                tmp_list.append(element)
        glob_list = tmp_list
    return glob_list

def write_attributes_to_file(object, file, section):
    """
    Write attributes of the given object to the given file.
    """
    f = open(file, 'w')
    f.write('[%s]\n' % section)
    for attr in dir(object):
        if not attr.startswith('_'):
            f.write('%s=%s\n' % (attr, getattr(object, attr)))
    f.close()

def load_attributes_from_file(object, file, params, section, overwrite=True):
    """
    Loads attributes into the given object from the the given file.
    """
    config = ConfigParser.ConfigParser()
    try:
        config.readfp(open(file))
    except ConfigParser.MissingSectionHeaderError, e:
        raise Exception('No header %s found in file %s' % (section, file))
    for param in params:
        if config.has_option(section, param) and (overwrite or getattr(object, param) == None):
            if params[param]['type'] == str:
                    value = config.get(section, param)
            elif params[param]['type'] == int:
                value = config.getint(section, param)
            elif params[param]['type'] == bool:
                value = config.getboolean(section, param)
            setattr(object, param, value)

def get_terraform_output(env_name, output_name, as_list=False):
    """
    Returns the Terraform output with the given name for the given environment.
    """
    env_dir = ENVS_DIR + '/' + env_name
    command = ('terraform output %s' % output_name)
    (stdout, stderr, returncode) = run_command(command, cwd=env_dir, verbose=False, silent=True)

    # in case of error we log the error and send back ''
    if returncode != 0:
        raise Exception('Error getting Terraform output: %s' % stderr)
    if as_list:
        if stdout.strip() == "":
            return []
        else:
            return [element.strip(', ') for element in stdout.splitlines()]
    else:
        return stdout.strip()

def git_checkout(file):
    """
    Performs a git checkout of the given file.  A failure to checkout the file is not
    considered an error, as to allow for running harmlessly against local files.
    """
    if not os.path.exists(file):
        raise Exception('File %s doesn\'t exist' % file)

    # First check if the file is tracked in Git - if not, don't bother
    cmd = ('git ls-files --error-unmatch %s' % file)
    (_, _, returncode) = run_command(cmd=cmd, cwd=PROJECT_ROOT_DIR, verbose=False, silent=True)
    if returncode != 0:
        return

    cmd = ('git checkout %s' % file)
    (_, stderr, returncode) = run_command(cmd=cmd, cwd=PROJECT_ROOT_DIR, verbose=False, logger=logger)
    if returncode != 0:
        raise Exception('Failed to checkout %s - error: %s' % (file, stderr))

def yes_or_no(question):
    """
    Prompts stdin with a yes/no question.
    """
    reply = str(raw_input(question + ' (y/n): ')).lower().strip()
    if reply[0] == 'y':
        return True
    if reply[0] == 'n':
        return False
    else:
        return yes_or_no("Please enter 'y' or 'n' only. " + question)

def prompt_for_value(name, default_value=None):
    """
    Prompts stdin with a yes/no question.
    """
    if default_value == None:
        value = str(raw_input('%s: ' % name)).strip()
        if value == '':
          value = prompt_for_value(name, default_value=default_value)
    else:
        value = str(raw_input('%s [%s]: ' % (name, default_value))).strip()
        if value == '':
            value = default_value
    return value

def verify_ansible_vault_password_env():
    """
    Verifies that the current environment has been set to run ansible-vault.
    """
    verify_env_variable_set('ANSIBLE_VAULT_PASSWORD_FILE')

def verify_env_variable_set(name):
    """
    Verifies that the given environment variable is set.
    """
    if not name in os.environ:
        raise Exception('%s environment variable not set' % name)

def decrypt_file(file, silent=False):
    """
    Decrypts the given file with ansible-vault.
    """
    verify_ansible_vault_password_env()
    # Only process the file if it's been encrypted - otherwise just return
    if 'ANSIBLE_VAULT' in open(file).read():
        if file.startswith(PROJECT_ROOT_DIR):
            # Prevent an encrpyted file that hasn't been committed from being processed
            cmd = 'git diff --name-only %s' % file
            (stdout, stderr, returncode) = run_command(cmd=cmd, cwd=PROJECT_ROOT_DIR, verbose=False, silent=True, logger=logger)
            if stdout.strip() != "":
                raise Exception(('Refusing to decrypt %s - this is an encrypted file that has not ' +
                                'been committed to Git.  Please commit it, then rerun.') % file)
            if returncode != 0:
                raise Exception('Error running command %s: %s' % (cmd, stderr))

        cmd = ('ansible-vault decrypt %s' % file)
        (_, stderr, returncode) = run_command(cmd=cmd, verbose=False, silent=silent, logger=logger)

        # Make a copy of the decrypted file for extra safety when reencrypting later on
        shutil.copyfile(file, file + DECRYPTED_BACKUP_EXT)
        if returncode != 0:
            raise Exception('Error running ansible-vault: %s' % stderr)

def decrypt_string(string):
    """
    Decrypts the given string with ansible-vault.
    """
    # Only process the string if it's been encrypted - otherwise just return the original string
    if 'ANSIBLE_VAULT' in string:
        verify_ansible_vault_password_env()

        # Write string to a temporary file, and run decrypt on that file (using decrypt_string
        # is problematic
        import tempfile
        tmp_file = tempfile.NamedTemporaryFile(delete=False)
        tmp_file.write(string)
        tmp_file.close()
        try:
            decrypt_file(tmp_file.name, silent=True)
            with open(tmp_file.name, 'r') as content_file:
                return content_file.read()
        finally:
            os.remove(tmp_file.name)
    else:
        return string
    return content

def decrypt_env(env_name):
    """
    Decrypts files for the given environment with ansible-vault.
    """
    verify_ansible_vault_password_env()

    # Verify necessary env dir exists for this environment
    env_dir = ENVS_DIR + '/' + env_name
    if not os.path.isdir(env_dir):
        raise Exception('Directory %s for this environment doesn\'t exist' % env_dir)

    # Process Terraform state and certs for the environment
    for file in os.listdir(env_dir):
        if file.startswith(TF_STATE_FILE_NAME):
            decrypt_file(env_dir + '/' + file)
    certs_dir = env_dir + '/certs'
    if os.path.isdir(certs_dir):
        for file in os.listdir(certs_dir):
            if file.endswith('.pem'):
                decrypt_file(certs_dir + '/' + file)

def reencrypt_env(env_name):
    """
    Re-encrypts (git checkout) files for the given environment.
    """
    # Verify necessary env dir exists for this environment
    env_dir = ENVS_DIR + '/' + env_name
    if not os.path.isdir(env_dir):
        raise Exception('Directory %s for this environment doesn\'t exist' % env_dir)

    # Gather all files to be reencrypt, then do it
    files_to_reencrypt = []
    for file in os.listdir(env_dir):
        if file.startswith(TF_STATE_FILE_NAME) and not file.endswith(DECRYPTED_BACKUP_EXT):
            files_to_reencrypt.append(env_dir + '/' + file)
    certs_dir = env_dir + '/certs'
    if os.path.isdir(certs_dir):
        for file in os.listdir(certs_dir):
            if file.endswith('.pem'):
                files_to_reencrypt.append(certs_dir + '/' + file)

    for file in files_to_reencrypt:
        if 'ANSIBLE_VAULT' in open(file).read():
            logger.warning('Skipping already encrypted file: %s' % file)
        elif os.path.exists(file + DECRYPTED_BACKUP_EXT) and not filecmp.cmp(file, file + DECRYPTED_BACKUP_EXT):
            logger.warning('Skipping file that has changed from its original unencrpyted version: %s' % file)
        else:
            git_checkout(file)
            if os.path.exists(file + DECRYPTED_BACKUP_EXT):
                os.remove(file + DECRYPTED_BACKUP_EXT)

def populate_health_config(kubeconfig, master_address_list, worker_address_list):
    """
    Constructs and returns a health configuration for the given Sauron instance, specified
    in the health_config dictionary.
    """
    health_config = {
        'k8s': {
            'kubeconfig': kubeconfig,
            'worker-address-list': worker_address_list,
            'master-address-list': master_address_list
        }
        # Details of other installed components here...
    }
    return health_config

def populate_env(env_name):
    """
    Populates Ansible dynamic files for the given environment.
    """
    if env_name in MANAGED_ENVS:
        log('[%s] Decrypting environment files' % env_name, as_banner=True)
        verify_ansible_vault_password_env()
        decrypt_env(env_name)

    # Verify necessary env dir exists for this environment
    env_dir = ENVS_DIR + '/' + env_name
    if not os.path.isdir(env_dir):
        raise Exception('Directory %s for this environment doesn\'t exist' % env_dir)
    if not os.path.exists(env_dir + '/' + TF_STATE_FILE_NAME):
        raise Exception('Terraform state doesn\'t exist in %s' % env_dir)

    # Extract details from Terragrunt
    log('[%s] Extracting outputs from Terraform into %s' % (env_name, env_dir), as_banner=True)

    ssh_private_key = get_terraform_output(env_name=env_name, output_name='ssh_private_key')
    ca_cert = get_terraform_output(env_name=env_name, output_name='root_ca_pem')
    ca_key = get_terraform_output(env_name=env_name, output_name='root_ca_key')
    api_server_cert = get_terraform_output(env_name=env_name, output_name='api_server_cert_pem')
    api_server_key = get_terraform_output(env_name=env_name, output_name='api_server_private_key_pem')
    k8s_master_public_ips = get_terraform_output(env_name=env_name, output_name='k8s_master_public_ips', as_list=True)
    k8s_worker_public_ips = get_terraform_output(env_name=env_name, output_name='k8s_worker_public_ips', as_list=True)
    etcd_public_ips = get_terraform_output(env_name=env_name, output_name='k8s_etcd_public_ips', as_list=True)
    region = get_terraform_output(env_name=env_name, output_name='region')

    # Some regions cannot be reached through the oracle proxy
    proxy_append = ''
    if region in PROXY_REGIONS:
        # Determine the local SSH version, which will determine which Ansible SSH proxy flags to specify
        log('Environment: %s needs a proxy to connect, see the hosts file for added instructions' % env_name)
        (stdout, stderr, returncode) = run_command('ssh -V', verbose=False, silent=True)
        if returncode != 0:
            raise Exception('Failed to fetch local SSH verion - error: %s' % stderr)
        if 'libressl' in (stdout + stderr).lower():
            proxy_append = ' ansible_ssh_common_args=\'-o ProxyCommand="nc -X connect -x www-proxy.us.oracle.com:80 %h %p" -o ConnectTimeout=100\''
        else:
            proxy_append = ' ansible_ssh_common_args=\'-o ProxyCommand="nc --proxy-type http --proxy www-proxy.us.oracle.com:80 %h %p" -o ConnectTimeout=100\''
        
    # Write hosts file
    log('[%s] Generating Ansible environment files' % env_name, as_banner=True)
    hosts_file = '%s/%s/%s' % (ENVS_DIR, env_name, HOSTS_FILE_NAME)
    f = open(hosts_file, 'w')
    f.write('[k8s-master]\n')
    for master_address in k8s_master_public_ips:
        f.write("%s%s\n" % (master_address, proxy_append))
    f.write('[k8s-worker]\n')
    for worker_address in k8s_worker_public_ips:
        f.write("%s%s\n" % (worker_address, proxy_append))

    # If not explicit Etcd nodes found, we'll use the k8smasters as the Etcds
    f.write('[etcd]\n')
    for etcd_address in (etcd_public_ips if len(etcd_public_ips) > 0 else k8s_master_public_ips):
        f.write("%s%s\n" % (etcd_address, proxy_append))
    f.close()

    # Generate keys and certs
    files_dir = '%s/%s/%s' % (ENVS_DIR, env_name, FILES_DIR_NAME)
    if not os.path.exists(files_dir):
        os.makedirs(files_dir)

    write_cert_file(ssh_private_key, files_dir + '/' + ID_RSA_FILE)
    write_cert_file(ca_cert, files_dir + '/' + CA_CERT_FILE)
    write_cert_file(ca_key, files_dir + '/' + CA_KEY_FILE)
    write_cert_file(api_server_cert, files_dir + '/' + API_SERVER_CERT_FILE)
    write_cert_file(api_server_key, files_dir + '/' + API_SERVER_KEY_FILE)

    # Generate kubeconfig
    kubeconfig = files_dir + '/kubeconfig'
    log('[%s] Generating kubeconfig: %s' % (env_name, kubeconfig), as_banner=True)
    client_key_file = files_dir + '/k8s-client-key.pem'
    client_file = files_dir + '/k8s-client.pem'
    client_csr_file = files_dir + '/k8s-client.csr'

    # Generate local client certs
    run_command("openssl genrsa -out %s 2048" % client_key_file, verbose=False, silent=True, verify_return_code=True)
    run_command('openssl req -new -key %s -out %s -subj "/CN=k8s-client"' %
                (client_key_file, client_csr_file), verbose=False, silent=True, verify_return_code=True)
    run_command('openssl x509 -req -in %s -CA %s -CAkey %s -CAcreateserial -out %s -days 1000 -extensions v3_req' %
                (client_csr_file, files_dir + '/' + CA_CERT_FILE, files_dir + '/' + CA_KEY_FILE, client_file),
                verbose=False, silent=True, verify_return_code=True)

    kubeconfig_template = TEMPLATES_DIR + '/kubeconfig'
    shutil.copyfile(kubeconfig_template, kubeconfig)
    token_values = {}
    # TODO - use an LB here instead of the first instance of a master
    token_values['MASTER_URL'] = 'https://%s:443' % k8s_master_public_ips[0]
    token_values['CLIENT_CERT_DATA'] = base64.b64encode(open(client_file, 'r').read())
    token_values['CLIENT_KEY_DATA'] = base64.b64encode(open(client_key_file, 'r').read())
    for line in fileinput.FileInput(kubeconfig, inplace=1):
        for token in token_values:
            line = line.replace('<%s>' % token, token_values[token])
        print line.strip('\n')

    # Populate health config
    health_config = populate_health_config(kubeconfig, k8s_master_public_ips, k8s_worker_public_ips)

    # Write health file
    health_config_file = files_dir + '/' + HEALTH_FILE_NAME
    f = open(health_config_file, 'w')
    f.write(json.dumps(health_config))
    f.close()

def unpopulate_env(env_name):
    """
    Unpopulates Ansible dynamic files for the given environment.
    """
    log('[%s] Removing dynamic files' % env_name, as_banner=True)

    # Verify necessary env dir exists for this environment
    env_dir = ENVS_DIR + '/' + env_name
    if not os.path.isdir(env_dir):
        raise Exception('Directory %s for this environment doesn\'t exist' % env_dir)

    for file in [HOSTS_FILE_NAME]:
        if os.path.exists(env_dir + '/' + file):
            os.remove(env_dir + '/' + file)
    for file in ['files']:
        if os.path.exists(env_dir + '/' + file):
            shutil.rmtree(env_dir + '/' + file)

    if env_name in MANAGED_ENVS:
        log('[%s] Re-encrypting environment files' % env_name, as_banner=True)
        reencrypt_env(env_name)
