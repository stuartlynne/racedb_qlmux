#!/bin/sh
#
echo CSRF_TRUSTED_ORIGINS = [\"${CSRF_TRUSTED_ORIGINS}\", ]  >> /RaceDB/RaceDB/settings.py
