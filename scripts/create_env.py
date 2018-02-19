#!/usr/bin/python
#
# Creates a new managed environment from scratch.
#

import helpers
import traceback
import argparse
import os
import shutil
import json
import getpass
import fileinput
from collections import OrderedDict

SCRIPTS_DIR = helpers.PROJECT_ROOT_DIR + '/scripts'
TEMPLATES_DIR = SCRIPTS_DIR + '/templates'
PARAMS_JSON = SCRIPTS_DIR + '/create_env_params.json'
ANSIBLE_VAULT_CHALLENGE_FILE = SCRIPTS_DIR + '/ansible-vault-challenge.txt'
RESUMABLE_FILE_NAME = 'resumeable.txt'
RESUME_SECTION = 'RESUME'
K8S_SECTION = 'K8S'
DESTROY_FILE_NAME = 'destroy.sh'
PREFS_FILE_DEFAULT = os.path.expanduser('~') + '/.k8s/config'
NUM_ADS = 3

helpers.logger = helpers.setup_logging('create_env.log')

def get_git_branch_name(env_name):
    (stage_name, team_name) = env_name.split('/')
    return '%s/create-%s-%s-env' % (getpass.getuser(), stage_name, team_name)

def generate_destroy_env_script(args):
    env_dir = helpers.ENVS_DIR + '/' + args.env_name
    destroy_file = env_dir + '/' + DESTROY_FILE_NAME
    f = open(destroy_file, 'w')
    f.write('set -e\n')
    f.write('cd %s\n' % env_dir)
    f.write('terragrunt destroy -force -state=`pwd`/terraform.tfstate -var disable_auto_retries=true ' +
            '-var fingerprint=%s -var private_key_path=%s -var user_ocid=%s\n' % (args.fingerprint,
            args.private_key_file, args.user_ocid))
    f.close()
    os.chmod(destroy_file, 0o775)

def get_num_per_ad_list(string):
    num_per_ad_list = map(int, string.split(','))
    if len(num_per_ad_list) != NUM_ADS:
        raise Exception('Expected %d entries, corresponding to number of ADs, got %d' % (NUM_ADS, len(num_per_ad_list)))
    return num_per_ad_list

def parse_args():
    """
    Parses and verifies arguments and checks prereqs.
    """
    #
    # Parse command line args
    #
    parser = argparse.ArgumentParser(description='Create New Managed Environment')
    parser.add_argument('env_name', type=str, help='Name of the environment')

    # Load all possible params from params file, preserving ordering from params file in help output, for readability
    f = open(PARAMS_JSON, 'r')
    params = json.load(f, object_pairs_hook=OrderedDict)
    for param in params:
        # We don't actually use argparse "defaults" here, to give us the chance to interactively prompt
        # for certain unspecified values below
        if params[param]['type'] == "boolean":
            parser.add_argument('--' + param, help=params[param]['help'], type=helpers.str2bool, nargs='?', const=True)
        else:
            parser.add_argument('--' + param, help=params[param]['help'], type=str, required=False)
    args = parser.parse_args()

    #
    # Short-circuit the prompting if we're resuming a previously started environment
    #
    env_dir = helpers.ENVS_DIR + '/' + args.env_name
    if args.resume:
        resumable_file = env_dir + '/' + RESUMABLE_FILE_NAME
        if not os.path.exists(resumable_file):
            raise Exception('The last execution of the given environment was not resumable')
        helpers.load_attributes_from_file(args, resumable_file, params, RESUME_SECTION)
        os.remove(resumable_file)
        return args

    if os.path.isdir(env_dir):
        raise Exception('Directory %s for the specified environment already exists' % env_dir)

    #
    # Load arguments from preferences file, if specified
    #
    args.prefs = PREFS_FILE_DEFAULT if args.prefs == None else args.prefs
    if os.path.exists(args.prefs):
        helpers.logger.info('Loading preferences from %s...' % args.prefs)
        helpers.load_attributes_from_file(args, args.prefs, params, K8S_SECTION, overwrite=False)

    # Process any remaining args that haven't been specified yet
    for param in params:
        if getattr(args, param) is None:
            if params[param]['prompt']:
                if params[param]['type'] == 'boolean':
                    setattr(args, param, helpers.yes_or_no(params[param]['help']))
                else:
                    setattr(args, param, helpers.prompt_for_value(params[param]['help'], params[param]['default']))
            else:
                setattr(args, param, params[param]['default'])

    # Ensure all expected boolean types have boolean values (no Nones)
    for param in params:
        if params[param]['type'] == 'boolean':
            setattr(args, param, bool(getattr(args, param)))

    #
    # Handle prereqs that differ between managed/unmanaged environments.
    #
    if args.managed:
        # Ensure ansible-vault password set
        if not 'ANSIBLE_VAULT_PASSWORD_FILE' in os.environ:
            raise Exception('ANSIBLE_VAULT_PASSWORD_FILE must be set as an environment variable '
                            'in order to create managed environments')
            # Only process the file if it's been encrypted - otherwise just return
        cmd = ('ansible-vault decrypt --output=- %s' % ANSIBLE_VAULT_CHALLENGE_FILE)
        (_, stderr, returncode) = helpers.run_command(cmd=cmd, verbose=False, silent=True)
        if returncode != 0:
            raise Exception('Looks like you have the wrong Ansible Vault password - please take your grubby hands '
                            'off of our managed environments')

        # Creating a managed environment involves creating a Git commit, so ensure that
        # the current environment doesn't have any staged files to begin with
        cmd = 'git diff --cached'
        (stdout, _, _) = helpers.run_command(cmd=cmd, verbose=False, silent=True)
        if stdout.strip() != '':
            raise Exception('Can\'t create a managed environment with existing staged Git files')
    else:
        if args.env_name in helpers.MANAGED_ENVS:
            raise Exception('Can\'t create an unmanaged environment using one of the names reserved for '
                            ' managed environments: %s' % helpers.MANAGED_ENVS)

    #
    # Addition validation of certain params
    #
    if sum(get_num_per_ad_list(args.k8s_masters)) <= 0:
        raise Exception('At least one K8S master must be specified')

    return args

def stamp_out_env_dir(args):
    """
    Stamps out directory structure for the given environment.
    """
    env_dir = helpers.ENVS_DIR + '/' + args.env_name
    helpers.log('Creating directory structure at %s ' % env_dir, as_banner=True, bold=True)
    os.makedirs(env_dir)

    tfvars_file = '%s/terraform.tfvars' % TEMPLATES_DIR
    shutil.copyfile(tfvars_file, env_dir + '/terraform.tfvars')
    os.makedirs(env_dir + '/group_vars/all')
    all_yml_file = env_dir + '/group_vars/all/all.yml'
    shutil.copyfile(TEMPLATES_DIR + '/all.yml', all_yml_file)

    if args.vars_file:
        # Append custom vars file to generated all.yml
        with open(all_yml_file, 'a') as fo:
            fo.write(open(args.vars_file, 'r').read())

    #
    # Create dictionary of name/value pairs to be filled into templates
    #
    token_values = {}
    # Load all specified params as uppercase template values
    for param in args.__dict__:
        if type(args.__dict__[param]) == bool:
            token_values[param.upper()] = str(args.__dict__[param]).lower()
        else:
            token_values[param.upper()] = args.__dict__[param]
    # Load a few computed template values
    token_values['PROJECT_ROOT_DIR'] = helpers.PROJECT_ROOT_DIR
    num_masters_per_ad = get_num_per_ad_list(args.k8s_masters)
    num_workers_per_ad = get_num_per_ad_list(args.k8s_workers)
    num_etcds_per_ad = get_num_per_ad_list(args.etcds)
    for i in range(0, NUM_ADS):
        token_values['K8S_MASTER_AD%s_COUNT' % (i + 1)] = num_masters_per_ad[i]
        token_values['K8S_WORKER_AD%d_COUNT' % (i + 1)] = num_workers_per_ad[i]
        token_values['ETCD_AD%d_COUNT' % (i + 1)] = num_etcds_per_ad[i]
    env_name_tokens = args.env_name.split('/')
    if not args.managed:
        # Terraform prefix for objects will start with the local user name
        token_values['ENV_PREFIX'] = '-'.join([getpass.getuser()] + list(reversed(env_name_tokens)))
    else:
        # Terraform prefix for objects will be in the form <team>-<stage_dir_name>
        token_values['ENV_PREFIX'] = '-'.join(list(reversed(env_name_tokens)))

    # Fill in Terraform and Ansible templates
    for file in (env_dir + '/terraform.tfvars', all_yml_file):
        for line in fileinput.FileInput(file, inplace=1):
            for token in token_values:
                value = "" if token_values[token] == None else str(token_values[token])
                line = line.replace('<%s>' % str(token), value)
            print line.strip('\n')

def deploy_terraform(args):
    """
    Deploys Terraform for the given environment.
    """
    env_dir = helpers.ENVS_DIR + '/' + args.env_name
    helpers.log('Rolling out Terraform for %s ' % args.env_name, as_banner=True, bold=True)
    cmd = 'terragrunt plan -state=%s/terraform.tfstate' % env_dir
    env = os.environ.copy()
    env['TF_VAR_fingerprint'] = args.fingerprint
    env['TF_VAR_private_key_path'] = args.private_key_file
    env['TF_VAR_user_ocid'] = args.user_ocid
    (stdout, stderr, returncode) = helpers.run_command(cmd=cmd, env=env, cwd=env_dir, verbose=True)
    if returncode != 0:
        raise Exception('Terraform plan failed')
    if not '0 to destroy' in stdout:
        raise Exception('Terraform plan indicated changes, too scared to continue!')

    # Generate destroy script for unmanaged environments for easy cleanup
    if not args.managed:
        generate_destroy_env_script(args)

    cmd = 'terragrunt apply --terragrunt-non-interactive --state=%s/terraform.tfstate' % env_dir
    (stdout, stderr, returncode) = helpers.run_command(cmd=cmd, env=env, cwd=env_dir, verbose=True)
    if returncode != 0:
        raise Exception('Terraform deployment failed')

def deploy_ansible(args):
    """
    Deploys Ansible for the given environment.
    """
    env_dir = helpers.ENVS_DIR + '/' + args.env_name
    helpers.log('Rolling out Ansible for %s ' % args.env_name, as_banner=True, bold=True)

    helpers.log('Populating dynamic files for %s ' % args.env_name, as_banner=True)
    helpers.populate_env(args.env_name)

    cmd = 'ansible-playbook -i %s/hosts -vv site.yml' % env_dir
    (stdout, stderr, returncode) = helpers.run_command(cmd=cmd, verbose=True)
    if returncode != 0:
        raise Exception('Ansible deployment failed')

def commit_changes(args):
    """
    Prepares files for checkin for the given environment, including encrypting and 
    creating a Git commit.
    """
    # Nothing to do for unmanaged environments
    if not args.managed:
        return

    env_dir = helpers.ENVS_DIR + '/' + args.env_name
    helpers.log('Preparing environment files for check-in', as_banner=True, bold=True)
    helpers.log('Encrypting sensitive files', as_banner=True)
    cmd = 'ansible-vault encrypt %s/terraform.tfstate' % env_dir
    (_, _, returncode) = helpers.run_command(cmd=cmd, verbose=True)
    if returncode != 0:
        raise Exception('Failed to encrypt Terraform state')

    if not args.skip_branch:
        helpers.log('Creating branch', as_banner=True)
        cmd = 'git checkout -b %s' % get_git_branch_name(args.env_name)
        (_, _, returncode) = helpers.run_command(cmd=cmd, verbose=True)
        if returncode != 0:
            raise Exception('Failed to create branch')

    helpers.log('Staging environment files', as_banner=True)
    cmd = 'git add %s' % env_dir
    (_, _, returncode) = helpers.run_command(cmd=cmd, verbose=True)
    if returncode != 0:
        raise Exception('Failed to stage environment files')

    helpers.log('Creating commit for new environment files', as_banner=True)
    cmd = 'git commit -m "Environment files for %s"' % args.env_name
    (_, _, returncode) = helpers.run_command(cmd=cmd, verbose=True)
    if returncode != 0:
        raise Exception('Failed to commit environment files')

#
# Main Logic
#

args = parse_args()
env_dir = helpers.ENVS_DIR + '/' + args.env_name

# Stamp out the environment and run Terraform if we are not resuming a previous run
if not args.resume:
    stamp_out_env_dir(args)
    try:
        deploy_terraform(args)
    except Exception, e:
        helpers.logger.debug('Failure: ' + str(e) + ", exception: " + traceback.format_exc().replace('\n', ' | '))
        # Generate destroy script for any env (managed or unmanaged) that failed Terraform
        generate_destroy_env_script(args)
        err = ('Something went wrong with the Terraform deployment - see above output for details. We don\'t support '
               'resuming from a Terraform failure, so you\'ll need to destroy this environment manually, which you can '
               'do by running %s/%s, removing the environment directory, and then rerunning this script from scratch.'
               % (env_dir, DESTROY_FILE_NAME))
        helpers.logger.error(err)
        raise

# Run Ansible
try:
    deploy_ansible(args)
except Exception, e:
    helpers.logger.debug('Failure: ' + str(e) + ", exception: " + traceback.format_exc().replace('\n', ' | '))
    helpers.logger.error('Something went wrong with the Ansible deployment - see above output for details. '
                         'You can rerun this script against the this environment using the --resume option.')
    # Write the current args to a file to indicate the creation of this environment can be resumed, to prevent
    # running anything later against an unwanted environment
    args.resume = True
    helpers.write_attributes_to_file(args, env_dir + '/' + RESUMABLE_FILE_NAME, RESUME_SECTION)
    raise

commit_changes(args)

helpers.log('Success!', as_banner=True, bold=True)
helpers.logger.info('See %s/%s/files/health.json for details about connecting to this environment.' % (helpers.ENVS_DIR, args.env_name))
helpers.logger.info('You can set kubectl client to this environment by running:\n  export KUBECONFIG=%s/%s/files/kubeconfig'
                    % (helpers.ENVS_DIR, args.env_name))
if args.managed:
    if args.skip_branch:
        helpers.logger.info('Environment files have been committed to the current branch. '
                            'Proceed by creating/pushing a branch and creating an MR.')
    else:
        helpers.logger.info('Environment files have been committed to the local branch %s. '
                            'Proceed by pushing this branch and creating an MR.' % get_git_branch_name(args.env_name))
else:
    helpers.logger.info('You can destroy this environment by running %s/%s, then removing the environment directory.'
                        % (env_dir, DESTROY_FILE_NAME))
