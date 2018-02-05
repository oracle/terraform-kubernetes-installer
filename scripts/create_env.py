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
import time
import re

SCRIPTS_DIR = helpers.PROJECT_ROOT_DIR + '/scripts'
TEMPLATES_DIR = SCRIPTS_DIR + '/templates'
ANSIBLE_VAULT_CHALLENGE_FILE = SCRIPTS_DIR + '/ansible-vault-challenge.txt'
RESUMABLE_FILE_NAME = 'resumeable.txt'
RESUME_SECTION = 'RESUME'
K8S_SECTION = 'K8S'
DESTROY_FILE_NAME = 'destroy.sh'
PREFS_FILE_DEFAULT = os.path.expanduser('~') + '/.k8s/config'

helpers.logger = helpers.setup_logging('create_env.log')

def parse_managed_env_name(env_name):
    """
    Parse a full managed environment name, and return the following for the environment: 
    1) stage (dev|integ|prod) 2) region (us-ashburn-1|us-phoenix-1|eu-frankfurt-1|etc) 3) team name (oke|sre|etc)
    Note - an environment without an explicit region specified in the stage *directory* is assumed 
    to be in the "default region".
    """
    match = re.search('(?P<stage_dir_name>.*?)/(?P<team_name>.*)', env_name)
    if len(match.groups()) != 2:
        raise Exception('Managed environment name must be in the form: stage(-region)/team')
    (stage_dir_name, team_name) = match.groups()
    if stage_dir_name not in helpers.MANAGED_ENV_DIRS:
        raise Exception('%s is not a valid stage dir for a managed environment. '
                        'Valid stages are: %s' % (stage_dir_name, helpers.MANAGED_ENV_DIRS))

    stage_dir_name_match = re.search('(?P<stage_name>.*?)-(?P<stage_region>.*)', stage_dir_name)
    if(len(stage_dir_name_match.groups()) != 2):
        raise Exception('%s is not a valid stage dir for a managed environment. '
                        'Valid stages are: %s' % (stage_dir_name, helpers.MANAGED_ENV_DIRS))
    (stage_name, stage_region) = stage_dir_name_match.groups()
    return (stage_name, stage_region, team_name)

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
    params['self_signed_certs'] = {'help': 'Whether to use self-signed certs', 'type': bool}
    params['tenancy_ocid'] = {'help': 'OCI Tenancy OCID', 'type': str}
    params['compartment_ocid'] = {'help':'OCI Compartment OCID', 'type': str}
    params['user_ocid'] = {'help':'OCI User OCID', 'type': str}
    params['fingerprint'] = {'help':'OCI API Fingerprint', 'type': str}
    params['private_key_file'] = {'help':'OCI Private Key File', 'type': str}
    params['region'] = {'help':'OCI Region to use', 'type': str}
    params['shape'] = {'help':'OCI Compute node shape to use', 'type': str}
    params['logging_ad'] = {'help':'OCI Availability Domain to use for logging node', 'type': str}
    params['monitoring_ad'] = {'help':'OCI Availability Domain to use for monitoring node', 'type': str}
    params['admin_user'] = {'help':'Admin user to create for this environment', 'type': str}
    params['admin_password'] = {'help':'Admin password to create for this environment', 'type': str}
    params['external_domain'] = {'help':'External domain name for this environment', 'type': str}
    params['certs_dir'] = {'help':'Certs directory for this environment', 'type': str}
    params['skip_branch'] = {'help': 'Whether to skip creation of a new branch with a managed environment\'s files', 'type': bool}

    for param in params:
        if params[param]['type'] == str:
            parser.add_argument('--' + param, help=params[param]['help'], type=params[param]['type'],
                                required=False)
        elif params[param]['type'] == bool:
            parser.add_argument('--' + param, help=params[param]['help'], action='store_const', const=True)
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
        (stage_name, region, team_name) = parse_managed_env_name(args.env_name)

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
        env_name_tokens = args.env_name.split('/')
        if env_name_tokens[0] in helpers.MANAGED_ENV_DIRS:
            raise Exception('Can\'t create an unmanaged environment in one of the directories reserved for '
                            ' managed environments: %s' % helpers.MANAGED_ENV_DIRS)
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
    param_defaults['logging_ad'] = '1'
    param_defaults['monitoring_ad'] = '1'

    if args.managed:
        if args.shape != None:
            raise Exception('Shape is pre-set for managed environments')
        param_defaults['region'] = region
        param_defaults['admin_user'] = team_name
        param_defaults['admin_password'] = helpers.generate_password()
        param_defaults['external_domain'] = '%s.%s.k8s.%s.oracledx.com' % (stage_name, team_name, region)
    else:
        param_defaults['shape'] = 'VM.Standard1.2'
        local_user = getpass.getuser()
        param_defaults['region'] = 'us-ashburn-1'
        param_defaults['admin_user'] = local_user
        param_defaults['admin_password'] = helpers.generate_password()
        param_defaults['external_domain'] = '%s.sandbox.k8s.%s.oracledx.com' % (local_user, params['region'])
    for param in param_defaults:
        if getattr(args, param) is None:
            setattr(args, param, helpers.prompt_for_value(params[param]['help'], param_defaults[param]))

    # Certs dir - a special case
    if args.managed:
        if args.certs_dir is None:
            args.certs_dir = helpers.prompt_for_value(params['certs_dir']['help'])
    else:
        if args.certs_dir is None and not args.self_signed_certs and helpers.yes_or_no('Attach real certs'):
            args.certs_dir = helpers.prompt_for_value(params['certs_dir']['help'])
    if not args.certs_dir == None:
        # Check certs dir
        if not os.path.isdir(args.certs_dir):
            raise Exception('Local certs directory %s doesn\'t exist' % args.certs_dir)

        key_files = helpers.glob(args.certs_dir + '/*.key')
        crt_files = helpers.glob(args.certs_dir + '/*.crt')
        if len(key_files) != 1 or len(crt_files) != 1:
            raise Exception('Exactly one .crt and one .key file not found under %s' % args.certs_dir)
    return args

def stamp_out_env_dir(args):
    """
    Stamps out directory structure for the given environment.
    """

    env_dir = helpers.ENVS_DIR + '/' + args.env_name
    helpers.log('Creating directory structure at %s ' % env_dir, as_banner=True, bold=True)
    os.makedirs(env_dir)

    # Use a different template tfvars file for managed environments
    if args.managed:
        (stage_name, _, _) = parse_managed_env_name(args.env_name)
        tfvars_file = '%s/terraform-%s.tfvars' % (TEMPLATES_DIR, stage_name)
    else:
        tfvars_file = TEMPLATES_DIR + '/terraform-unmanaged.tfvars'
    shutil.copyfile(tfvars_file, env_dir + '/terraform.tfvars')
    os.makedirs(env_dir + '/group_vars/all')
    shutil.copyfile(TEMPLATES_DIR + '/all.yml', env_dir + '/group_vars/all/all.yml')

    if args.managed:
        # Sym link common vars for the stage
        os.symlink('../../../common_vars/vars.yml', env_dir + '/group_vars/all/stage_common.yml')

    # Copy in certs
    os.mkdir(env_dir + '/certs')
    if args.certs_dir is None:
        # Allow self-signed certs to be used for unmanaged environments
        self_signed_certs_dir = SCRIPTS_DIR + '/certs'
        cert_key_file = self_signed_certs_dir + '/selfsigned.ca-key.pem'
        cert_pem_file = self_signed_certs_dir + '/selfsigned.ca.pem'
    else:
        cert_key_file = helpers.glob(args.certs_dir + '/*.key')[0]
        cert_pem_file = helpers.glob(args.certs_dir + '/*.crt')[0]
    shutil.copyfile(cert_pem_file, '%s/certs/ca.pem' % env_dir)
    shutil.copyfile(cert_key_file, '%s/certs/ca-key.pem' % env_dir)

    # Fill in tokenized values in environment files
    if args.managed:
        # Encrypt password
        cmd = 'ansible-vault encrypt_string "%s"' % args.admin_password
        (stdout, stderr, returncode) = helpers.run_command(cmd=cmd, verbose=False)
        if returncode != 0:
            raise Exception('Failed to encrypt password - error: %s' % stderr)
        args.admin_password = stdout
    token_values = {}
    token_values['ENV_NAME'] = args.env_name
    token_values['REGION'] = args.region
    token_values['LOGGING_AD'] = args.logging_ad
    token_values['MONITORING_AD'] = args.monitoring_ad
    token_values['EXTERNAL_DOMAIN_NAME'] = args.external_domain
    token_values['API_USER'] = args.admin_user
    token_values['API_PASSWORD'] = args.admin_password
    token_values['PAGERDUTY_KEY'] = 'TBD'

    env_name_tokens = args.env_name.split('/')
    if not args.managed:
        token_values['TENANCY_OCID'] = args.tenancy_ocid
        token_values['COMPARTMENT_OCID'] = args.compartment_ocid
        token_values['SHAPE'] = args.shape
        token_values['PROJECT_ROOT_DIR'] = helpers.PROJECT_ROOT_DIR
        # Terraform prefix for objects will start with the local user name
        token_values['ENV_PREFIX'] = '-'.join([getpass.getuser()] + list(reversed(env_name_tokens)))
    else:
        # Terraform prefix for objects will be in the form <team>-<stage_dir_name>
        token_values['ENV_PREFIX'] = '-'.join(list(reversed(env_name_tokens)))

    for file in (env_dir + '/terraform.tfvars', env_dir + '/group_vars/all/all.yml'):
        for line in fileinput.FileInput(file, inplace=1):
            for token in token_values:
                line = line.replace('<%s>' % token, token_values[token])
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

    cmd = 'terragrunt apply -state=%s/terraform.tfstate' % env_dir
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
    cmd = 'ansible-vault encrypt %s/certs/*' % env_dir
    (_, _, returncode) = helpers.run_command(cmd=cmd, verbose=True)
    if returncode != 0:
        raise Exception('Failed to encrypt certs')

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
