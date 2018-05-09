#!/bin/bash

# dependencies in the right other...
d="\
#xbuild \
zlib \
pcre \
expat \
libxml2 \
openssl \
nghttp2 \
curl \
db4 \
cyrus-sasl \
openldap \
krb5 \
lua \
apr \
apr-util \
httpd \
mod_auth_kerb \
mod_bmx \
mod_cluster-native \
mod_jk \
mod_rt \
mod_security \
jbcs-httpd24-httpd \
#jbcs-httpd24-src \
#jbcs-httpd24-webserver-connectors \
#jboss-logging \
#wildfly-openssl-solaris \
#jakarta-commons-daemon \
"

for dir in $d
do
  echo $dir
  if [ -d $dir ]; then
     (cd $dir; make sunbuild)
  fi
done
