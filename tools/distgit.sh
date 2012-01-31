#!/bin/bash

n=distgit-`date +%F`
sources=no
distro=no
dclear=no
dmaint=yes
branch=jb-ep-6-xb
lookaside=http://pkgs.devel.redhat.com/repo/pkgs

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
        -a|--anon* )
            dmaint=no
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
    rpms="ssh://$USERNAME@pkgs.devel.redhat.com/rpms"
fi

test -f .branch || echo $branch > .branch

for i in $d
do
    if [ .$dclear = .yes ]
    then
        rm -rf $i 2>/dev/null || true
        continue
    fi
    if [ -d $i/.git ]
    then
        pushd $i
        git pull
        popd
    else
        git clone -b $branch $rpms/$i $i
    fi

    if [ .$sources = .yes -a -d $i ]
    then
        pushd $i
        make sources
        popd
    fi
    echo "Updated: \`$i'"
done

if [ .$distro = .yes ]
then
    tar cfz $n.tar.gz $d distgit.sh
fi
