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
