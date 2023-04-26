#!/usr/bin/env bash
set -eu
org=localhost-ca
domain=localhost
path="$HOME/.aspnet/https"

if [ ! -d $path ]
then
	mkdir -p $path
fi

openssl genpkey -algorithm RSA -out "$path/ca.key"
openssl req -x509 -key "$path/ca.key" -out "$path/ca.crt" \
   -subj "/CN=$org/O=$org"

openssl genpkey -algorithm RSA -out "$path/$domain".key
openssl req -new -key "$path/$domain".key -out "$path/$domain".csr \
    -subj "/CN=$domain/O=$org"

openssl x509 -req -in "$path/$domain".csr -days 365 -out "$path/$domain".crt \
    -CA "$path/ca.crt" -CAkey "$path/ca.key" -CAcreateserial \
    -extfile <(cat <<END
basicConstraints = CA:FALSE
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid,issuer
subjectAltName = DNS:$domain
END
    )

openssl pkcs12 -export -out "$path/$domain".pfx -inkey "$path/$domain".key -in "$path/$domain".crt

certutil -d "sql:$HOME/.pki/nssdb" -A -i $path/ca.crt -n 'Localhost CA' -t C,,
sudo trust anchor $HOME/.aspnet/https/ca.crt
sudo update-ca-trust
