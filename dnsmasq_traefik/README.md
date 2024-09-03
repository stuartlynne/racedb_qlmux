# racedb_qlmux/dnsmasq_traefik

This contains the configuration for the dnsmasq container.

The dnsmasq container is used to provide DNS resolution for clients on the local network. It is configured to
provide DNS resolution for hosts defined in the /etc/hosts file. This allows for the use of hostnames
to be used instead of IP addresses. Which is a requirement to correctly access the applications
via HTTPS through the Traefik proxy.

While some clients (e.g. Windows) can have a hosts file that can be used to define hostnames, it is not
possible to do this on all devices. 

Specifically Chromebooks do not have a hosts file that can be modified. This means that the only way to
access the applications is to use the IP address or by name with a DNS lookup. 

The dnsmasq container provides a centralised way to provide DNS resolution


## DNS Servers

Set the DNS servers to forward queries to.
See docker.env:
```
# External DNS servers to forward queries to
DNSSERVERS=1.1.1.1,8.8.8.8
```

## Hosts File

See hosts.txt
```
# IPaddr hostname
192.168.40.51 racedb.wimsey.online
192.168.40.51 qlmuxproxy.wimsey.online

```

## Client Configuration

To use the DNS server, the client needs to be configured to use the IP address of the host running the dnsmasq container as the DNS server.

Typically this is done by setting the DNS server in the DHCP configuration of the router or by modifying client WiFi setting to add
the IP address of the server running this container.
