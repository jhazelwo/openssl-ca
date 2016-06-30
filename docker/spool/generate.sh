#!/bin/sh -uex
#
# All of the steps from https://jamielinux.com/docs/openssl-certificate-authority/
# in an automated no-input-needed script.
#
# Once complete all items are tar-ed up in a file and placed in /tmp/ (default)
# of your host.
#
# Safe to re-run as needed. All items are put in their own temp dir.
#
randpw(){ < /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c${1:-128};echo;}

root_subj="/C=${Country}/ST=${State}/L=${City}/O=${Company}/OU=${Department}/CN=${Company} Root CA"
intr_subj="/C=${Country}/ST=${State}/L=${City}/O=${Company}/OU=${Department}/CN=${Company} Intermediate CA"
cert_subj="/C=${Country}/ST=${State}/L=${City}/O=${Company}/OU=${Department}/CN=${Domain}"

cd `mktemp -d`
rootcadir=`pwd`

# OpenSSL will modify and create files on its own, so we must specify a umask
# sicne we cannot manually install those files with the right modes.
umask 0077

install -d -m 0700 -o 0 -g 0 certs crl newcerts private intermediate passwords

install -m 0600 -o 0 -g 0 /dev/null index.txt
install -m 0600 -o 0 -g 0 /dev/null serial
echo 1000 > serial

install -m 0600 -o 0 -g 0 /dev/null openssl.cnf
# curl -sSL https://jamielinux.com/docs/openssl-certificate-authority/_downloads/root-config.txt
cat /root/root-config.txt > openssl.cnf
sed -i "s#= /root/ca#= ${rootcadir}#g" openssl.cnf

install -m 0600 -o 0 -g 0 /dev/null passwords/ca.key.pem
randpw > passwords/ca.key.pem

install -m 0600 -o 0 -g 0 /dev/null private/ca.key.pem
openssl genrsa \
  -passout file:passwords/ca.key.pem \
  -aes256 \
  -out private/ca.key.pem 4096

install -m 0600 -o 0 -g 0 /dev/null passwords/ca.cert.pem
randpw > passwords/ca.cert.pem

install -m 0600 -o 0 -g 0 /dev/null certs/ca.cert.pe
openssl req \
  -passin file:passwords/ca.key.pem \
  -passout file:passwords/ca.cert.pem \
  -config openssl.cnf \
  -key private/ca.key.pem \
  -new -x509 -days 7300 -sha256 -extensions v3_ca \
  -out certs/ca.cert.pem \
  -subj "${root_subj}"

cd intermediate
install -d -m 0700 -o 0 -g 0 certs crl csr newcerts private
install -m 0600 -o 0 -g 0 /dev/null index.txt
install -m 0600 -o 0 -g 0 /dev/null serial
echo 1000 > serial

install -m 0600 -o 0 -g 0 /dev/null crlnumber
echo 1000 > crlnumber

install -m 0600 -o 0 -g 0 /dev/null openssl.cnf
# curl -sSL https://jamielinux.com/docs/openssl-certificate-authority/_downloads/intermediate-config.txt
cat /root/intermediate-config.txt > openssl.cnf
sed -i "s#= /root/ca#= ${rootcadir}#g" openssl.cnf

cd ..

install -m 0600 -o 0 -g 0 /dev/null passwords/intermediate.key.pem
randpw > passwords/intermediate.key.pem

install -m 0400 -o 0 -g 0 /dev/null intermediate/private/intermediate.key.pem
openssl genrsa \
  -passout file:passwords/intermediate.key.pem \
  -aes256 \
  -out intermediate/private/intermediate.key.pem 4096

install -m 0600 -o 0 -g 0 /dev/null passwords/intermediate.csr.pem
randpw > passwords/intermediate.csr.pem


install -m 0400 -o 0 -g 0 /dev/null intermediate/csr/intermediate.csr.pem
openssl req \
  -passin file:passwords/intermediate.key.pem \
  -passout file:passwords/intermediate.csr.pem \
  -config intermediate/openssl.cnf \
  -new -sha256 \
  -key intermediate/private/intermediate.key.pem \
  -out intermediate/csr/intermediate.csr.pem \
  -subj "${intr_subj}"

install -m 0400 -o 0 -g 0 /dev/null intermediate/certs/intermediate.cert.pem
openssl ca \
  -batch \
  -passin file:passwords/ca.key.pem \
  -config openssl.cnf -extensions v3_intermediate_ca \
  -days 3650 -notext -md sha256 \
  -in intermediate/csr/intermediate.csr.pem \
  -out intermediate/certs/intermediate.cert.pem

openssl x509 \
  -noout \
  -text \
  -in intermediate/certs/intermediate.cert.pem

openssl verify \
  -CAfile certs/ca.cert.pem \
  intermediate/certs/intermediate.cert.pem

install -m 0400 -o 0 -g 0 /dev/null intermediate/certs/ca-chain.cert.pem
cat intermediate/certs/intermediate.cert.pem \
  certs/ca.cert.pem > intermediate/certs/ca-chain.cert.pem

install -m 0400 -o 0 -g 0 /dev/null intermediate/private/${Certname}.key.pem
openssl genrsa \
  -out intermediate/private/${Certname}.key.pem 2048

install -m 0400 -o 0 -g 0 /dev/null intermediate/csr/${Certname}.csr.pem
openssl req \
  -config intermediate/openssl.cnf \
  -key intermediate/private/${Certname}.key.pem \
  -new -sha256 -out intermediate/csr/${Certname}.csr.pem \
  -subj "${cert_subj}"

install -m 0400 -o 0 -g 0 /dev/null intermediate/certs/${Certname}.cert.pem
openssl ca \
  -batch \
  -passin file:passwords/intermediate.key.pem \
  -config intermediate/openssl.cnf \
  -extensions server_cert -days 375 -notext -md sha256 \
  -in intermediate/csr/${Certname}.csr.pem \
  -out intermediate/certs/${Certname}.cert.pem

openssl x509 \
  -noout -text \
  -in intermediate/certs/${Certname}.cert.pem

openssl verify \
  -CAfile intermediate/certs/ca-chain.cert.pem \
  intermediate/certs/${Certname}.cert.pem

tname=`basename $rootcadir`
cd /tmp
tar cfzv /mnt/${tname}.tar.gz $tname
set +x
echo "

Saved all work to:
`ls -lh /mnt/${tname}.tar.gz`
    which should map to /tmp/ of your system.

Files you need to deploy are:
    intermediate/certs/ca-chain.cert.pem
    intermediate/private/${Certname}.key.pem
    intermediate/certs/${Certname}.cert.pem
"

rm -rf $rootcadir
