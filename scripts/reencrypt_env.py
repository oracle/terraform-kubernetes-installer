#!/usr/bin/python
#
# Re-encrypts (git checkout) encrypted files for the given environment.
#

import helpers
import traceback
import argparse

# Check parameters
parser = argparse.ArgumentParser(description='Decrypt environment files')
parser.add_argument('env_name', type=str, help='Name of the environment')
args = parser.parse_args()


helpers.logger = helpers.setup_logging('reencrypt_env.log')
helpers.log('Re-encrypting environment: %s' % args.env_name, as_banner=True, bold=True)

try:
    helpers.reencrypt_env(args.env_name)
except Exception, e:
    helpers.logger.debug('Failure: ' + str(e) + ", exception: " + traceback.format_exc().replace('\n', ' | '))
    raise


