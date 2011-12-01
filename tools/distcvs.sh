#!/bin/sh

n=distcvs-`date +%F`
sources=no
distro=no
dclear=no
branch=JB-EP-6-XB

for o
do
    case "$o" in
        --tgz )
            distro=yes
            sources=yes
            shift
        ;;
        -s|--so* )
            sources=yes
            shift
        ;;
        -c|--cl* )
            dclear=yes
            shift
        ;;
        * )
            break
        ;;
    esac
done

d="xbuild cyrus-sasl db4 httpd jakarta-commons-daemon \
    jboss-eap-native jboss-ews-dist krb5 libiconv \
    mod_auth_kerb mod_cluster mod_cluster-native mod_jk mod_nss \
    nspr nss nss-softokn nss-util \
    openldap openssl sqlite \
    tanukiwrapper tomcat-native zlib"

export CVSROOT=":pserver:anonymous@cvs.devel.redhat.com:/cvs/dist"

for i in $d
do
    if [ .$dclear = .yes ]
    then
        rm -rf $i 2>/dev/null || true
        continue
    fi
    if [ -d $i/CVS ]
    then
        pushd $i
        cvs up -dP
        popd
    else
        cvs co $i
    fi

    if [ .$sources = .yes -a -d $i/$branch ]
    then
        pushd $i/$branch
        make sources
        popd
    fi
    echo "Updated: \`$i'"
done

if [ .$distro = .yes ]
then
    tar cfz $n.tar.gz $d distcvs.sh
fi
