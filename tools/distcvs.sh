#!/bin/sh

if [ ".$1" = ".-d" ]
then
    n=distcvs-`date +%F`
else
    n=distcvs
fi
mkdir $n 2>/dev/null || true
cd $n
d="cyrus-sasl db4 httpd jakarta-commons-daemon \
    jboss-eap-native jboss-ews-dist \
    libiconv mod_cluster mod_cluster-native mod_jk openldap openssl \
    tanukiwrapper tomcat-native xbuild zlib"

CVSROOT=":pserver:anonymous@cvs.devel.redhat.com:/cvs/dist"
export CVSROOT
for i in $d
do
    if [ -d $i/CVS ]
    then
    (
        cd $i
        cvs up -dP
    )
    else
        cvs co $i
    fi

done

cd ..
if [ ".$1" = ".-d" ]
then
    cp distcvs.sh $n
    tar cfz $n.tar.gz $n
fi
