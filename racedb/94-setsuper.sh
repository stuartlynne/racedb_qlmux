#!/bin/bash

#set -x
cd /RaceDB
#python manage.py set_password super racedb
python manage.py set_password super super
python manage.py set_password reg reg

