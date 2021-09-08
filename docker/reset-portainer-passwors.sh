#!/bin/bash

set -x
docker run --rm -v portainer_data:/data portainer/helper-reset-password

