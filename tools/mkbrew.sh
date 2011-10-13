#!/bin/sh
#
TAG=jb-ep-5-win-candidate
VM=jboss-natives-20110516-1
for o
do
    case $o in
        --tag=* )
            TAG="`sed 's/.*=//'`"            
        ;;
        --vm=* )
            VM="`sed 's/.*=//'`"
        ;;
        * )
          echo "Unknown option $o"
          exit 1
        ;;
    esac
done
HEAD=`svn info http://anonsvn.jboss.org/repos/xbuild/trunk | grep Revision: | sed 's/.*: //'`
echo "$TAG svn+http://anonsvn.jboss.org/repos/xbuild?trunk#$HEAD $VM"
brew win-build $TAG svn+http://anonsvn.jboss.org/repos/xbuild?trunk#$HEAD $VM
