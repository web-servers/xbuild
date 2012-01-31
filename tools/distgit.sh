#!/bin/bash

n=distgit-`date +%F`
sources=no
distro=no
dclear=no
dmaint=no
branch=jb-ep-6-xb

for o
do
    case "$o" in
        -d|--di* )
            distro=yes
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
        -m|--ma* )
            dmaint=yes
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

if [ .$dmaint = .no ]
then
    rpms="git://pkgs.devel.redhat.com/rpms"
else
    rpms="ssh://pkgs.devel.redhat.com/rpms"
fi

for i in $d
do
    if [ .$dclear = .yes ]
    then
        rm -rf $i 2>/dev/null || true
        continue
    fi
    if [ -d $i/$branch/.git ]
    then
        pushd $i/$branch
        git pull
        popd
    else
        git clone -b $branch $rpms/$i $i/$branch
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
    tar cfz $n.tar.gz $d distgit.sh
fi
