# openssl-ca
## Scripted OpenSSL Certificate Authority

* All of the steps from
https://jamielinux.com/docs/openssl-certificate-authority/
in an automated script, values defined in the included Dockerfile.


## Prerequisites:
1. git
2. Docker


## Usage:
1. `git clone https://github.com/jhazelwo/openssl-ca.git`
2. `cd openssl-ca/docker`
3. Edit the ENV values in ./Dockerfile to match your cert needs.
    * (optional) edit ./Env and change the _$volumes_ variable map a directory of your choice (instead of /tmp/).
4. `./Build`
5. `./Run`
6. Your cert bundle will be in /tmp/ of the host.
