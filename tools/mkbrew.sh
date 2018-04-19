#!/bin/sh
#
TARGET=jws-5.0-win-candidate
VM=jboss-natives-20110516-1
CMD=win-build
for o
do
    case $o in
        --target=* )
            TAG="`sed 's/.*=//'`"
            shift
        ;;
        --vm=* )
            VM="`sed 's/.*=//'`"
            shift
        ;;
        --*    )
            CMD="$CMD $o"
            shift
        ;;
        *      )
          echo "Unknown option $o"
          exit 1
        ;;
    esac
done
HEAD=`git ls-remote https://github.com/web-servers/xbuild  | grep HEAD | awk '{print $1}'`
echo "$CMD $TARGET https://github.com/web-servers/xbuild#$HEAD $VM"
brew $CMD $TARGET https://github.com/web-servers/xbuild#$HEAD $VM
