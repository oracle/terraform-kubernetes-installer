#!/usr/bin/python
#
# Populates dynamic files for the given environment.
#

import helpers
import argparse
import traceback

# Check parameters
parser = argparse.ArgumentParser(description='Populate dynamic files for an environment')
parser.add_argument('env_name', type=str, help='Name of the environment')
args = parser.parse_args()

helpers.logger = helpers.setup_logging('populate_env.log')
helpers.log('Populating environment: ' + args.env_name, bold=True)

try:
    helpers.populate_env(args.env_name)
except Exception, e:
    helpers.logger.debug('Failure: ' + str(e) + ", exception: " + traceback.format_exc().replace('\n', ' | '))
    raise



