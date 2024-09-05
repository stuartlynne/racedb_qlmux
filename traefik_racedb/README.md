# racedb\_qlmux/traefik\_racedb container

This contains the configuration for the Traefik container.

It is setup to support two other application containers, providing HTTPS access to them:
- racedb\_qllabels
- qlmux\_proxy

## DNS Requirements
  
The *traefik* container is configured to use a DNS challenge to obtain certificates from LetsEncrypt. 
This requires that you have a DNS provider that allows for API access to update the DNS records.
The *traefik* container will use the *acme-dns* challenge to obtain the certificates. 

N.b. Only a single domain is required. The wildcard certificate will be used for all subdomains.

E.g.:
Required to be registered:
- wimsey.online - the main domain

Will be used by the Traefik container, these can be optionally used to access the applications
from the Internet:
- racedb.wimsey.online - the RaceDB application
- qlmuxproxy.wimsey.online - the QLMux Proxy application

If Internet access is required add a CNAME record for the subdomains pointing to the external IP address of the server.

E.g.:
```
racedb.wimsey.online CNAME whiskey.duckdns.org
qlmuxproxy.wimsey.online CNAME whiskey.duckdns.org
```

N.b. Port 443 must be open on the server to allow access to the applications. This may require port forwarding
if behind a (for example) NAT router.


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
The example uses the required NAMECHEAP\_API\_USER and NAMECHEAP\_API\_KEY values.
They will have to be replaced with your the appropriate DNS provider keys.

For more information on the Traefik DNS Challenge see:
[ACME DNS](https://doc.traefik.io/traefik/user-guides/docker-compose/acme-dns/)
[DNS Providers](https://doc.traefik.io/traefik/https/acme/#providers)



## Sample Docker Environment Variables
```
export TRAEFIK_EMAIL=stuart.lynne@gmail.com
export TRAEFIK_DNS_PROVIDER=namecheap
export WILDCARD_DOMAIN=*.wimsey.pro

# Hostnames and ports for RaceDB and QLMuxProxy, 
export RACEDB_HOSTNAME="racedb.wimsey.pro"
export RACEDB_PORT=9080
export QLMUXPROXY_HOSTNAME="qlmuxproxy.wimsey.pro"
export QLMUXPROXY_PORT=9180

# Traefik configuration
export TRAEFIK_LOG_LEVEL=DEBUG
export TRAEFIK_DNS_DELAY_BEFORE_CHECK=60
```

## RaceDB CSRF
RaceDB is built with *django* which will defaults to not allowing HTTPS connections
from unknown domains. *CSRF\_TRUSTED\_ORIGINS* must be present and specify the
*racedb.wimsey.pro* domain.

N.b. See *racedb_qllabels* docker.env file, and Dockerfile which runs *csrf.py* 
when building the RaceDb private image.


## DNS Challenge

- dnschallenge.env-template - template for dnschallenge.env

## Sample DNS Challenge

```
# Namecheap configuration
export NAMECHEAP_API_USER=YOUR_NAMECHEAP_USERNAME
export NAMECHEAP_API_KEY=f1282039d149419ba1ae8a38d79e3180
```

## systemd-resolved 
The *systemd-resolved* can be used to provide a local DNS server for other clients on the local network.

In the /etc/systemd/resolved.conf file add the following lines (with your IP address):
```
DNSStubListenerExtra=192.168.40.51
```
N.b. This is a recent change to the systemd-resolved service. Testing with Ubuntu 24.04, systemd 247.

## Client DNS
The client DNS should be set to the IP address of the server running the *systemd-resolved* service.


## Makefile

The Makefile contains the following commands:

- make up - start traefik\_racedb container
- make down - stop traefik\_racedb container
- make clean - remove traefik\_racedb container
- make really-clean - remove traefik\_racedb container 
- make bash - start a bash shell in traefik\_racedb container
- make logs - show container logs
- make test - show variables


## namecheap.com
*namecheap.com* is a low cost DNS provider that allows for API access to update the DNS records.

You will require an API key from *namecheap.com* to use the DNS challenge and at least one domain name
registered with *namecheap.com*.

namecheap allows access to the API if you have at least 20 (?) domains registered with them or if
you have $50US in your account. Low cost domains (such as xxx.online) can be purchased for less than $2US/year.

