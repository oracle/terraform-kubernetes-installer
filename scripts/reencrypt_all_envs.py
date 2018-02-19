#!/usr/bin/python
#
# Re-encrypts (git checkout) encrypted files for all live environments.
#

import helpers
import traceback
import argparse
import glob
import os

# Check parameters
parser = argparse.ArgumentParser(description='Re-encrypt all environments')
args = parser.parse_args()

helpers.logger = helpers.setup_logging('reencrypt_all_envs.log')
helpers.log('Re-encrypting all environments', as_banner=True, bold=True)

# Collect list of all live environments

for managed_dir in helpers.MANAGED_ENV_DIRS:
    env_dirs = glob.glob('%s/%s/*' % (helpers.ENVS_DIR, managed_dir))
    ignore_words = ['common_vars']
    for env_dir in env_dirs:
        env_dir_words = env_dir.split('/')
        if os.path.isdir(env_dir) and not any(x in ignore_words for x in env_dir_words):
            env_name = '/'.join(env_dir_words[-2:])
            helpers.logger.info('Re-encrypting %s...' % env_name)
            try:
                helpers.reencrypt_env(env_name)
            except Exception, e:
                helpers.logger.debug('Failure: ' + str(e) + ", exception: " + traceback.format_exc().replace('\n', ' | '))
                raise


