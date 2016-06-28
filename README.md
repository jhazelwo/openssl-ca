# openssl-ca
## Scripted OpenSSL Certificate Authority

* All of the steps from
https://jamielinux.com/docs/openssl-certificate-authority/
\([@jamielinux](https://github.com/jamielinux)\)
in an automated script, values defined in the included Dockerfile.


## Prerequisites:
1. git
2. Docker


## Usage:
1. `git clone https://github.com/jhazelwo/openssl-ca.git`
2. `cd openssl-ca/docker`
3. Edit values in ./Dockerfile to match your cert needs.
    * (optional) edit ./Env and change the _$volumes_ variable map a directory of your choice (instead of /tmp/).
4. `./Build`
5. `./Run`
6. Your cert bundle will be in /tmp/ of the host.

### Dockerfile preview:
```
FROM centos:7
MAINTAINER "John Hazelwood" <jhazelwo@users.noreply.github.com>
RUN yum clean all && yum -y upgrade && yum -y install which yum-utils tar curl openssl
COPY spool/* /root/

# Vars used for the certs.
ENV Country='US'
ENV State='Washington'
ENV City='New York'
ENV Company='ACME'
ENV Department='DevOps'
ENV Domain='*.this.edu'
ENV Certname='wildcard.this.edu'

CMD /bin/sh -eux /root/generate.sh
````
