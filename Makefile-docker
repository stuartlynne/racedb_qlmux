
# N.b. This Makefile is set up to build containers and images with same name as the directory.
#
# To define container:
#
#    1. Optional Dockerfile - Dockerfile to build the CONTAINER:private image if required 
#    2. docker-compose.yml - docker-compose file to create the CONTAINER:private container
#    3. docker.env - environment variables to pass to docker-compose when creating the container
#    4. CONTAINER.env - environment variables to pass to docker-compose when creating the container
#
CONTAINER = $(shell basename $(CURDIR))

# Make the container name available to the docker-compose, note that this is the default container name
# and can be overridden by setting the CONTAINER variable in the docker.env or $(CONTAINER).env file
export CONTAINER_NAME := $(CONTAINER)

# make the contents of docker.env or $(CONTAINER).env available to docker-compose 
IMAGE = $(shell basename $(CURDIR)):private
ENV = $(shell basename $(CURDIR)).env

-include docker.env
-include $(ENV)

.PHONY: all build up down clean really-clean bash logs test

all:
	@echo "make build - build $(IMAGE) image"
	@echo "make up - start $(CONTAINER) container"
	@echo "make down - stop $(CONTAINER) container"
	@echo "make clean - remove $(CONTAINER) container"
	@echo "make really-clean - remove $(CONTAINER) container and $(IMAGE) image"
	@echo "make bash - start a bash shell in $(CONTAINER) container"
	@echo "make logs - show container logs"
	@echo "make test - show variables"

test:
	@echo CONTAINER:$(CONTAINER)
	@echo IMAGE:$(IMAGE)
	@echo DOCKERBUILDARGS:$(DOCKERBUILDARGS)
	@echo CSRF_TRUSTED_ORIGINS:$(CSRF_TRUSTED_ORIGINS)
	echo
	env

# build the image
build:
	echo BUILD
	if [ -s 'Dockerfile' ]; then docker build ${DOCKERBUILDARGS} --tag $(IMAGE) .;  fi

#	if [ -s 'Dockerfile' ]; then docker build --build-arg CSRF_TRUSTED_ORIGINS=$(CSRF_TRUSTED_ORIGINS) --tag $(IMAGE) .;  fi

# start the container
up:
	if [ -s 'Dockerfile' ]; then docker image inspect $(IMAGE) > /dev/null 2>&1 || make build; fi
	docker-compose up -d

# stop the container
down:
	docker-compose down

# remove the container
clean:
	-docker container rm --force --volumes $(CONTAINER) 

# remove the container and image
really-clean: clean
	-docker image rm --force $(IMAGE)
	

## docker helpers
bash:
	docker exec -it $(CONTAINER) bash

logs:
	docker logs -f $(CONTAINER)

