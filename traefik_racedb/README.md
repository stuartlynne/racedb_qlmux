# Traefik Container

This contains the configuration for the Traefik container.

## Configuration

- docker.env - copy from docker.env-template and fill in the values
- dnschallenge.env - copy from dnschallenge.env-template and fill in the values

## docker-compose

The docker-compose file is configured to use the Traefik container. To reduce the complexity of this
project the container is configured through the use of commands and labels. Specifically it does
not use a traefik configuration file (e.g. traefik.toml or traefik.yaml). And does not use the
dynamic configuration feature of Traefik for the routing and services.

Keeping the configuration in the docker-compose file is a trade-off between simplicity and flexibility 
and allows the use of environment variables to configure the container.

The environment variables are set in the docker.env file. Copy the docker.env-template file to docker.env

## Traefik DNS Challenge

DNS Challenge is required to obtain a wildcard certificate. This is done using the Traefik DNS Challenge.
Which in turn requires a DNS provider that supports the ACME DNS-01 challenge.

Testing of the DNS Challenge was done with a *Namecheap* account. 
The example uses the required NAMECHEAP_API_USER and NAMECHEAP_API_KEY values.
They will have to be replaced with your the appropriate DNS provider keys.

For more information on the Traefik DNS Challenge see:
[ACME DNS](https://doc.traefik.io/traefik/user-guides/docker-compose/acme-dns/)
[DNS Providers](https://doc.traefik.io/traefik/https/acme/#providers)



## Sample Docker Environment Variables
```
export TRAEFIK_EMAIL=stuart.lynne@gmail.com
export TRAEFIK_DNS_PROVIDER=namecheap
export WILDCARD_DOMAIN=*.wimsey.dev

# Hostnames and ports for RaceDB and QLMuxProxy, 
export RACEDB_HOSTNAME="racedb.wimsey.dev"
export RACEDB_PORT=9080
export QLMUXPROXY_HOSTNAME="qlmuxproxy.wimsey.dev"
export QLMUXPROXY_PORT=9180

# Traefik configuration
export TRAEFIK_LOG_LEVEL=DEBUG
export TRAEFIK_DNS_DELAY_BEFORE_CHECK=60
```

## DNS Challenge

- dnschallenge.env-template - template for dnschallenge.env

## Sample DNS Challenge

```
# Namecheap configuration
export NAMECHEAP_API_USER=YOUR_NAMECHEAP_USERNAME
export NAMECHEAP_API_KEY=f1282039d149419ba1ae8a38d79e3180
```


## Makefile

The Makefile contains the following commands:

- make up - start traefik_racedb container
- make down - stop traefik_racedb container
- make clean - remove traefik_racedb container
- make really-clean - remove traefik_racedb container 
- make bash - start a bash shell in traefik_racedb container
- make logs - show container logs
- make test - show variables
