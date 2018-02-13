#!/usr/bin/python
#
# Creates a new managed environment from scratch.
#

import helpers
import traceback
import argparse
import os
import shutil
import collections
import getpass
import fileinput

SCRIPTS_DIR = helpers.PROJECT_ROOT_DIR + '/scripts'
TEMPLATES_DIR = SCRIPTS_DIR + '/templates'
ANSIBLE_VAULT_CHALLENGE_FILE = SCRIPTS_DIR + '/ansible-vault-challenge.txt'
RESUMABLE_FILE_NAME = 'resumeable.txt'
RESUME_SECTION = 'RESUME'
K8S_SECTION = 'K8S'
DESTROY_FILE_NAME = 'destroy.sh'
PREFS_FILE_DEFAULT = os.path.expanduser('~') + '/.k8s/config'

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

def parse_args():
    """
    Parses and verifies arguments and checks prereqs.
    """
    #
    # Parse command line args
    #
    parser = argparse.ArgumentParser(description='Create New Managed Environment')
    parser.add_argument('env_name', type=str, help='Name of the environment')
    params = {}
    params['managed'] = {'help': 'Whether to create a managed environment', 'type': bool}
    params['unmanaged'] = {'help': 'Whether to create an unmanaged environment', 'type': bool}
    params['resume'] = {'help': 'Whether to resume execution of a failed previous run', 'type': bool}
    params['prefs'] = {'help': 'File containing user preferences', 'type': str}
    params['tenancy_ocid'] = {'help': 'OCI Tenancy OCID', 'type': str}
    params['compartment_ocid'] = {'help':'OCI Compartment OCID', 'type': str}
    params['user_ocid'] = {'help':'OCI User OCID', 'type': str}
    params['fingerprint'] = {'help':'OCI API Fingerprint', 'type': str}
    params['private_key_file'] = {'help':'OCI Private Key File', 'type': str}
    params['region'] = {'help':'OCI Region to use', 'type': str}
    params['k8s_master_shape'] = {'help':'OCI Compute node shape to use for K8S master nodes', 'type': str}
    params['k8s_worker_shape'] = {'help':'OCI Compute node shape to use for K8S worker nodes', 'type': str}
    params['etcd_shape'] = {'help':'OCI Compute node shape to use for Etcd nodes', 'type': str}
    params['k8s_master_ad1_count'] = {'help':'Number of K8S master nodes in AD1', 'type': int}
    params['k8s_master_ad2_count'] = {'help':'Number of K8S master nodes in AD2', 'type': int}
    params['k8s_master_ad3_count'] = {'help':'Number of K8S master nodes in AD3', 'type': int}
    params['k8s_worker_ad1_count'] = {'help':'Number of K8S worker nodes in AD1', 'type': int}
    params['k8s_worker_ad2_count'] = {'help':'Number of K8S worker nodes in AD2', 'type': int}
    params['k8s_worker_ad3_count'] = {'help':'Number of K8S worker nodes in AD3', 'type': int}
    params['etcd_ad1_count'] = {'help':'Number of Etcd nodes in AD1', 'type': int}
    params['etcd_ad2_count'] = {'help':'Number of Etcd nodes in AD2', 'type': int}
    params['etcd_ad3_count'] = {'help':'Number of Etcd nodes in AD3', 'type': int}
    params['vars_file'] = {'help':'Ansible vars file to append to the generated environment\"s vars file', 'type': str}
    params['skip_branch'] = {'help': 'Whether to skip creation of a new branch with a managed environment\'s files', 'type': bool}

    for param in params:
        if params[param]['type'] == bool:
            parser.add_argument('--' + param, help=params[param]['help'], action='store_const', const=True)
        else:
            parser.add_argument('--' + param, help=params[param]['help'], type=params[param]['type'],
                                required=False)
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

    #
    # Load arguments from preferences file, if specified
    #
    args.prefs = PREFS_FILE_DEFAULT if args.prefs == None else args.prefs
    if os.path.exists(args.prefs):
        helpers.logger.info('Loading preferences from %s...' % args.prefs)
        helpers.load_attributes_from_file(args, args.prefs, params, K8S_SECTION, overwrite=False)

    # Ensure all expected boolean types have boolean values (no Nones)
    for param in params:
        if params[param]['type'] == bool:
            setattr(args, param, bool(getattr(args, param)))

    #
    # Handle prereqs that differ between managed/unmanaged environments.
    #
    if args.managed and args.unmanaged:
        raise Exception('Both managed and unmanaged options were specified')
    if not args.managed and not args.unmanaged:
        args.managed = helpers.yes_or_no('Create "managed" environment')
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
    if os.path.isdir(env_dir):
       raise Exception('Directory %s for the specified environment already exists' % env_dir)

    #
    # Prompt for params not specified on the command line
    #

    # Params with no defaults
    if args.managed:
        if args.tenancy_ocid != None or args.compartment_ocid != None:
            raise Exception('Compartment and Tenancy are pre-set for managed environments')
    else:
       for param in ('tenancy_ocid', 'compartment_ocid'):
           if getattr(args, param) is None:
               setattr(args, param, helpers.prompt_for_value(params[param]['help']))
    for param in ('user_ocid', 'fingerprint', 'private_key_file'):
        if getattr(args, param) is None:
            setattr(args, param, helpers.prompt_for_value(params[param]['help']))

    # Params with defaults
    param_defaults = collections.OrderedDict()
    param_defaults['k8s_master_ad1_count'] = '0'
    param_defaults['k8s_master_ad2_count'] = '0'
    param_defaults['k8s_master_ad3_count'] = '0'
    param_defaults['k8s_worker_ad1_count'] = '0'
    param_defaults['k8s_worker_ad2_count'] = '0'
    param_defaults['k8s_worker_ad3_count'] = '0'
    param_defaults['etcd_ad1_count'] = '0'
    param_defaults['etcd_ad2_count'] = '0'
    param_defaults['etcd_ad3_count'] = '0'
    param_defaults['k8s_master_shape'] = 'VM.Standard1.2'
    param_defaults['k8s_worker_shape'] = 'VM.Standard1.2'
    param_defaults['etcd_shape'] = 'VM.Standard1.2'
    param_defaults['region'] = 'us-ashburn-1'

    for param in param_defaults:
        if getattr(args, param) is None:
            setattr(args, param, helpers.prompt_for_value(params[param]['help'], param_defaults[param]))

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

    token_values = {}
    token_values['ENV_NAME'] = args.env_name
    token_values['REGION'] = args.region
    token_values['K8S_MASTER_AD1_COUNT'] = args.k8s_master_ad1_count
    token_values['K8S_MASTER_AD2_COUNT'] = args.k8s_master_ad2_count
    token_values['K8S_MASTER_AD3_COUNT'] = args.k8s_master_ad3_count
    token_values['K8S_WORKER_AD1_COUNT'] = args.k8s_worker_ad1_count
    token_values['K8S_WORKER_AD2_COUNT'] = args.k8s_worker_ad2_count
    token_values['K8S_WORKER_AD3_COUNT'] = args.k8s_worker_ad3_count
    token_values['ETCD_AD1_COUNT'] = args.etcd_ad1_count
    token_values['ETCD_AD2_COUNT'] = args.etcd_ad2_count
    token_values['ETCD_AD3_COUNT'] = args.etcd_ad3_count
    token_values['K8S_MASTER_SHAPE'] = args.k8s_master_shape
    token_values['K8S_WORKER_SHAPE'] = args.k8s_worker_shape
    token_values['ETCD_SHAPE'] = args.etcd_shape
    token_values['TENANCY_OCID'] = args.tenancy_ocid
    token_values['COMPARTMENT_OCID'] = args.compartment_ocid
    token_values['PROJECT_ROOT_DIR'] = helpers.PROJECT_ROOT_DIR
    env_name_tokens = args.env_name.split('/')
    if not args.managed:
        # Terraform prefix for objects will start with the local user name
        token_values['ENV_PREFIX'] = '-'.join([getpass.getuser()] + list(reversed(env_name_tokens)))
    else:
        # Terraform prefix for objects will be in the form <team>-<stage_dir_name>
        token_values['ENV_PREFIX'] = '-'.join(list(reversed(env_name_tokens)))

    for file in (env_dir + '/terraform.tfvars', all_yml_file):
        for line in fileinput.FileInput(file, inplace=1):
            for token in token_values:
                line = line.replace('<%s>' % str(token), str(token_values[token]))
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
