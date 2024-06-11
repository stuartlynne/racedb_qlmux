# Makefile

The Makefile contains the following commands:

- make up - start traefik_racedb container
- make down - stop traefik_racedb container
- make clean - remove traefik_racedb container
- make really-clean - remove traefik_racedb container 
- make bash - start a bash shell in traefik_racedb container
- make logs - show container logs
- make test - show variables


## Configuration

The Makefile will set environment variables from the docker.env file in the current directory.  
The docker.env file can be used to set the following variables:

```
CONTAINER = $(shell basename $(CURDIR))

# Make the container name available to the docker-compose, note that this is the default container name
# and can be overridden by setting the CONTAINER variable in the docker.env or $(CONTAINER).env file
export CONTAINER_NAME := $(CONTAINER)

# make the contents of docker.env or $(CONTAINER).env available to docker-compose 
IMAGE = $(shell basename $(CURDIR)):private
ENV = $(shell basename $(CURDIR)).env

# Include the docker.env and $CONTAINER.env file if they exist
-include docker.env
-include $(ENV)

```

