#!/usr/bin/python
#
# Decrypts encrypted files for the given environment.
#

import helpers
import traceback
import argparse

# Check parameters
parser = argparse.ArgumentParser(description='Decrypt environment files')
parser.add_argument('env_name', type=str, help='Name of the environment')
args = parser.parse_args()


helpers.logger = helpers.setup_logging('decrypt_env.log')
helpers.log('Decrypting environment: ' + args.env_name, as_banner=True, bold=True)

try:
    helpers.decrypt_env(args.env_name)
except Exception, e:
    helpers.logger.debug('Failure: ' + str(e) + ", exception: " + traceback.format_exc().replace('\n', ' | '))
    raise

