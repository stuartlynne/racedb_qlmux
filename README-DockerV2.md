# Docker Compose V2

## Introduction

Docker has deprecated the `docker-compose` command in favor of `docker compose`. 

The current Linux Mint 22 installs docker-compose v2.

Assuming you have a `docker-compose.yml` file, you can run the following command:

```
docker compose up
```

## Makefile-docker and Makefile-docker-v2

This project has two Makefiles: `Makefile-docker` and `Makefile-docker-v2`.

Depending on which version of `docker-compose` you have installed, you can use the appropriate Makefile
in each container directory.


For docker-compose-v2.:
```
cd qlmux_proxy
ln -sf ../Makefile-docker-v2 Makefile
ls
.gitignore
README.md
Makefile -> Makefile-docker-v2
Dockerfile
docker-compose.yml
docker.env
```

For docker-compose.:
```
cd qlmux_proxy
ln -sf ../Makefile-docker Makefile
ls
.gitignore
README.md
Makefile -> Makefile-docker-v2
Dockerfile
docker-compose.yml
docker.env
```


