#!/bin/sh

n=distcvs
sources=no
datedir=no
branch=JB-EP-6-XB

for o
do
    case "$o" in
        -d|--da* )
            n=distcvs-`date +%F`
            datedir=yes
            shift
        ;;
        -s|--so* )
            sources=yes
            shift
        ;;
        * )
            break
        ;;
    esac
done

mkdir $n 2>/dev/null || true
cd $n
d="xbuild cyrus-sasl db4 httpd jakarta-commons-daemon \
    jboss-eap-native jboss-ews-dist \
    libiconv mod_cluster mod_cluster-native mod_jk openldap openssl \
    tanukiwrapper tomcat-native zlib"

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

    if [ .$sources = .yes -a -d $i/$branch ]
    then
    (
        cd $i/$branch
        make OSTYPE=windows sources
    )
    fi
    echo "Updated: \`$i'"
done

cd ..
if [ .$datedir = .yes ]
then
    cp distcvs.sh $n
    tar cfz $n.tar.gz $n
fi
