#!/usr/local/bin/python

import sys
import os

try:
    CSRF_TRUSTED_ORIGINS = os.environ.get('CSRF_TRUSTED_ORIGINS', '').split(',')
except Exception as e:
    print('Error:', e)
    sys.exit(1)

print()
print('# CSRF_TRUSTED_ORIGINS is required by django to allow an https proxy to work correctly')
print('# This is added by /csrf.py during docker-compose up')
print('# See the docker.env file in the build directory for the container to customize')
print('CSRF_TRUSTED_ORIGINS = [\"%s", ]' % '\", \"'.join(CSRF_TRUSTED_ORIGINS))  
print()
