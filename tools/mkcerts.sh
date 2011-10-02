#!/bin/sh
# Copyright(c) 2011 Red Hat, Inc.
#
# This is free software; you can redistribute it and/or
# modify it under the terms of the GNU Lesser General Public
# License as published by the Free Software Foundation; either
# version 2 of the License, or (at your option) any later version.
#
# This software is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# Lesser General Public License for more details.
#
# You should have received a copy of the GNU Lesser General Public
# License along with this library in the file COPYING.LIB;
# if not, write to the Free Software Foundation, Inc.,
# 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA
#
# @author Mladen Turk
#
# This is the configuration file to treate the CA certificate of the
# _DEMONSTRATION ONLY_ 'Tequila' Certificate Authority.
# This CA is used to sign the localhost.crt and user.crt
# because self-signed server certificates are not accepted by all browsers.
# NEVER USE THIS CA YOURSELF FOR REAL LIFE! INSTEAD EITHER USE A PUBLICALLY
# KNOWN CA OR CREATE YOUR OWN CA!

o_nokey=true
passphrase="pass:secret"

for o
do
    case "$o" in
        -*=*) a=`echo "$o" | sed 's/^[-_a-zA-Z0-9]*=//'` ;;
        *) a='' ;;
    esac
    case "$o" in
        -k|--key        ) o_nokey=false;         shift ;;
        --password=*    ) passphrase="pass:$a";  shift ;;
        *  ) break ;;
    esac
done

currdir=`pwd`
if [ -n "$1" ]; then
    if [ ! -d "$1" ]; then
        mkdir "$1"
    fi
    cd "$1"
fi

test ".$OPENSSL" = . && OPENSSL=openssl
# Encrypt all keys
if $o_nokey; then
    GENRSA="$OPENSSL genrsa"
else
    GENRSA="$OPENSSL genrsa -des3"
fi

NREQ="$OPENSSL req -new"
X509="$OPENSSL x509"
MKCA="$OPENSSL ca"

$OPENSSL rand -out rnd 8192
$GENRSA -passout $passphrase -out ca.key -rand rnd 1024

cat >ca.cfg <<EOT
[ ca ]
default_ca                      = default_db
[ default_db ]
dir                             = .
certs                           = .
new_certs_dir                   = ca.certs
database                        = ca.index
serial                          = ca.serial
RANDFILE                        = rnd
certificate                     = ca.crt
private_key                     = ca.key
default_days                    = 365
default_crl_days                = 30
default_md                      = md5
preserve                        = no
name_opt                        = ca_default
cert_opt                        = ca_default
unique_subject                  = no
[ server_policy ]
countryName                     = supplied
stateOrProvinceName             = supplied
localityName                    = supplied
organizationName                = supplied
organizationalUnitName          = supplied
commonName                      = supplied
emailAddress                    = supplied
[ server_cert ]
subjectKeyIdentifier            = hash
authorityKeyIdentifier          = keyid:always
extendedKeyUsage                = serverAuth,clientAuth,msSGC,nsSGC
basicConstraints                = critical,CA:false
[ user_policy ]
commonName                      = supplied
emailAddress                    = supplied
[ user_cert ]
subjectAltName                  = email:copy
basicConstraints                = critical,CA:false
authorityKeyIdentifier          = keyid:always
extendedKeyUsage                = clientAuth,emailProtection

[ req ]
default_bits                    = 1024
default_keyfile                 = ca.key
distinguished_name              = default_ca
x509_extensions                 = extensions
string_mask                     = nombstr
req_extensions                  = req_extensions
input_password                  = secret
output_password                 = secret
[ default_ca ]
countryName                     = Country Code
countryName_value               = US
countryName_min                 = 2
countryName_max                 = 2
stateOrProvinceName             = State Name
stateOrProvinceName_value       = Nort Carolina
localityName                    = Locality Name
localityName_value              = Raleigh
organizationName                = Organization Name
organizationName_value          = Red Hat, Inc.
organizationalUnitName          = Organizational Unit Name
organizationalUnitName_value    = Red Hat
commonName                      = Common Name
commonName_value                = Example demo root CA
commonName_max                  = 64
emailAddress                    = Email Address
emailAddress_value              = tequila@sunrise.jboss.org
emailAddress_max                = 40
[ extensions ]
subjectKeyIdentifier            = hash
authorityKeyIdentifier          = keyid:always
basicConstraints                = critical,CA:true
[ req_extensions ]
nsCertType                      = objsign,email,server
EOT

$NREQ -x509 -days 3650 -batch -config ca.cfg -key ca.key -out ca.crt

# Create cabundle.crt that can be used for CAfile
cat >cabundle.crt <<EOT
Example demo root CA
=========================================
`$X509 -noout -fingerprint -in ca.crt`
PEM Data:
`$X509 -in ca.crt`
`$X509 -noout -text -in ca.crt`
EOT

$GENRSA -passout $passphrase -out localhost.key  -rand rnd 1024

cat >localhost.cfg <<EOT
[ req ]
default_bits                    = 1024
distinguished_name              = localhost
string_mask                     = nombstr
req_extensions                  = extensions
input_password                  = secret
output_password                 = secret
[ localhost ]
countryName                     = Country Code
countryName_value               = US
countryName_min                 = 2
countryName_max                 = 2
stateOrProvinceName             = State Name
stateOrProvinceName_value       = North Carolina
localityName                    = Locality Name
localityName_value              = Raleigh
organizationName                = Organization Name
organizationName_value          = Red Hat, Inc.
organizationalUnitName          = Organizational Unit Name
organizationalUnitName_value    = Red Hat
commonName                      = Common Name
commonName_value                = Example localhost secure demo server
commonName_max                  = 64
emailAddress                    = Email Address
emailAddress_value              = tequila@sunrise.jboss.org
emailAddress_max                = 40
[ extensions ]
nsCertType                      = server
basicConstraints                = critical,CA:false
EOT

$NREQ -passin $passphrase -batch -config localhost.cfg -key localhost.key -out localhost.csr

#  make sure environment exists
if [ ! -d ca.certs ]; then
    mkdir ca.certs
    echo '01' >ca.serial
    cp /dev/null ca.index
fi

$MKCA -passin $passphrase -batch -config ca.cfg -extensions server_cert -policy server_policy  -out x.crt -infiles localhost.csr
$X509 -in x.crt -out localhost.crt
# Create PKCS12 localhost certificate
$OPENSSL pkcs12 -export -passout $passphrase -passin $passphrase -in localhost.crt -inkey localhost.key -certfile ca.crt -out localhost.p12

$GENRSA -passout $passphrase -out user.key -rand rnd 1024

cat >user.cfg <<EOT
[ req ]
default_bits            = 1024
distinguished_name      = admin
string_mask             = nombstr
req_extensions          = extensions
input_password          = secret
output_password         = secret
[ admin ]
commonName              = User Name
commonName_value        = Localhost Administrator
commonName_max          = 64
emailAddress            = Email Address
emailAddress_value      = admin@localhost.edu
emailAddress_max        = 40
[ extensions ]
nsCertType              = client,email
basicConstraints        = critical,CA:false
EOT

$NREQ -passin $passphrase -batch -config user.cfg -key user.key -out user.csr
$MKCA -passin $passphrase -batch -config ca.cfg -extensions user_cert -policy user_policy  -out u.crt -infiles user.csr
$X509 -in u.crt -out user.crt

# $OPENSSL verify -CAfile ca.crt localhost.crt
# $OPENSSL verify -CAfile ca.crt user.crt

# Create PKCS12 user certificate
$OPENSSL pkcs12 -export -passout $passphrase -passin $passphrase -in user.crt -inkey user.key -certfile ca.crt -out user.p12

rm -f *.cfg
rm -f ca.index.attr
rm -f *.old >/dev/null 2>&1
rm -f rnd

exit 0
