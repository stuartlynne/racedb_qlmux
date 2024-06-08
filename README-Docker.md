# Docker 

Docker uses Images and Containers.

Images are used to package up an application and all its dependencies. 

Containers are instances of Images that are running as a process on the host machine.

If an public image is being used that does not contain the necessary dependencies, 
a new image can be created that extends the public image and adds the necessary dependencies.

This repository contains support various applications and services that can be run in Docker containers.
Each application or service has its own directory containing an optional Dockerfile and a docker-compose.yml file.

The optional Dockerfile is used to build an image for the application or service, typically by extending
a public image that does the heavy lifting create a base image for the application. The local version 
will contain additional dependencies or configuration that are not included in the public image.

The docker-compose.yml file is used to define the services that are to be run in containers. It will only define
the operating parameters for the services, such as the image to use, the ports to expose, and the volumes to mount.


## Makefile-docker

The Makefile-docker contains a number of targets that can be used to build and run the applications and services in Docker containers.

It is used in each subdirectory to build and run the application or service in a container.

```
    ln -s ../Makefile-docker Makefile
```

The following targets are available:
- build: Build the image for the application or service
- up: Start the application or service in a container, will build the image if it does not exist
- down: Stop the application or service in a container
- clean: Remove the container.
- really-clean: Remove the container and the image.

Helper targers:
- bash: Start a bash shell in the container
- logs: Show the logs for the container
