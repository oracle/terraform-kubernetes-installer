#!/usr/bin/python
#
# Deploys Ansible changes to the given environment.
#

import helpers
import sys
import traceback
import argparse
import health

# Check parameters
parser = argparse.ArgumentParser(description='Deploy Ansible Changes to Environment')
parser.add_argument('env_name', type=str, help='Name of the environment')
parser.add_argument('--tags', type=str, default='', help='Command-separated list of tags to apply', required=False)
parser.add_argument('--force', help='Whether to force the operation without prompt', action='store_true')
parser.add_argument('--healthcheck', help='Whether to do health check', action='store_true')
parser.add_argument('--logdir', type=str, default='/tmp', help='Directory to stash logs', required=False)
parser.add_argument('--playbook', type=str, default='site.yml', help='Playbook to execute', required=False)
parser.add_argument('--extra_vars', type=str, default='', help='Extra variables for the playbook', required=False)


args = parser.parse_args()
env_name = args.env_name
if not args.force and not helpers.yes_or_no('Are you SURE you want to deploy %s to environment: %s with tags: \'%s\' ?'
    % (args.playbook, env_name, args.tags)):
    sys.exit(1)

# Global default logger
logger = helpers.setup_logging('ansible_deploy_env.log', log_dir=args.logdir)
helpers.logger = logger
health.logger = logger

helpers.log('[%s] Ready to deploy Ansible changes' % env_name, as_banner=True, bold=True)

# Populate the environment
try:
    helpers.populate_env(env_name)
except Exception, e:
    logger.error('Failure: ' + str(e) + ", exception: " + traceback.format_exc().replace('\n', ' | '))
    raise Exception('[%s] Populate failed' % env_name)

try:
    # Deploy Ansible
    helpers.log('[%s] Deploying Ansible' % env_name, as_banner=True)
    cmd = 'ansible-playbook -i envs/%s/hosts -vv %s' % (env_name, args.playbook)
    if len(args.tags) > 0:
        cmd += ' --tags ' + args.tags
    if len(args.extra_vars) > 0:
        cmd += ' --extra-vars "' + args.extra_vars + '"'
    (stdout, stderr, returncode) = helpers.run_command(cmd=cmd, verbose=True, logger=logger)
    if returncode != 0:
        logger.error('[%s] Deployment failed' % env_name)
        raise Exception('[%s] Deployment failed' % env_name)
    else:
        logger.info('[%s] Deployment succeeded' % env_name)

    # Health Check
    if args.healthcheck:
        try:
            helpers.log('[%s] Checking health' % env_name, as_banner=True)
            health.health('envs/%s/files/health.json' % env_name, 'all', logger)
            logger.info('[%s] Health Check succeeded' % env_name)
        except Exception, e:
            logger.error('[%s] Health Check failed.' % env_name)
            raise Exception('[%s] Health Check failed' % env_name)

finally:
    # Unpopulate the environment
    try:
        helpers.unpopulate_env(env_name)
    except Exception, e:
        logger.error('Failure: ' + str(e) + ", exception: " + traceback.format_exc().replace('\n', ' | '))
        raise
