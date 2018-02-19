#!/usr/bin/python
#
# Unpopulates dynamic files for the given environment.
#

import helpers
import traceback
import argparse

# Check parameters
parser = argparse.ArgumentParser(description='Unpopulate dynamic files for an environment')
parser.add_argument('env_name', type=str, help='Name of the environment')
args = parser.parse_args()

helpers.logger = helpers.setup_logging('unpopulate_env.log')
helpers.log('Unopulating environment: %s' % args.env_name, as_banner=True, bold=True)

try:
    helpers.unpopulate_env(args.env_name)
except Exception, e:
    helpers.logger.debug('Failure: ' + str(e) + ", exception: " + traceback.format_exc().replace('\n', ' | '))
    raise
