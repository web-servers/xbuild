#!/bin/bash

n=distgit-`date +%F`
sources=no
distro=no
dclear=no
dmaint=yes
branch=jb-ep-5-xb
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
        -b|--branch )
            shift
            branch=$1
            shift
        ;;
        * )
            break
        ;;
    esac
done

d="cyrus-sasl db4 httpd jboss-eap \
   jboss-eap-native mod_cluster mod_cluster-native mod_jk \
   openldap openssl sqlite tomcat-native zlib"

if [ .$dmaint = .no ]
then
    rpms="git://pkgs.devel.redhat.com/rpms"
else
    rpms="ssh://$USERNAME@pkgs.devel.redhat.com/rpms"
fi

test -f .branch || echo $branch > .branch

i=xbuild
if [ -d $i/.git ]
then
    pushd $i
    git pull
    popd
else
    git clone -b $branch $rpms/$i $i
fi
if [ .$sources = .yes ]
then
    pushd $i
    make xbuild
    popd
fi

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

    if [ .$sources = .yes -a -s $i/sources ]
    then
        pushd $i
        if [ -f Makefile ]
        then
            make sources
        else
            rhpkg sources
        fi
        popd
    fi
    echo "Updated: \`$i'"
done

if [ .$distro = .yes ]
then
    tar cfz $n.tar.gz $d distgit.sh
fi
