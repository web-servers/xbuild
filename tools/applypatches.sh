#!/bin/sh
# Copyright(c) 2021 Red Hat, Inc.
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
# Apply patches defined in .spec file
# This utility searches for %patchNN lines
# inside .spec file and combines them with corresponding
# PatchNN: file.patch lines and call 'patch' for each
# matched line.
#
# Using applypatches.sh:
# Step 1: Download sources eg. mkdir build && rhpkg sources --outdir build
# Step 2: cd to build directory
# Step 3: uncompress source file(s)
#         eg. tar jzf httpd-*.tar.bz2
# Step 4: cd to uncompressed source directory
#         eg. cd httpd-2.4.51
# Step 4: [sh ../../]applypatches.sh
#
set +e +x

pdir="`cd ../.. && pwd`"
cdir="`pwd`"

lf='
'

xbexit()
{
    e=$1; shift;
    echo "$@" 1>&2
    exit $e
}

outlog="../.applypatches.log"
runlog="../.appliedpatches.log"

specfile=`ls -1 $pdir/*.spec 2>/dev/null`
test ".$specfile" = . && xbexit 1 "Cannot find .spec file in \`$pdir'"
echo "# Applying patches from `basename $specfile`" > $outlog
echo "#" >> $outlog

_ifs=$IFS

IFS=$lf
pruns=`cat $specfile | grep '^%patch[0-9]*[[:blank:]]' | sed 's;^%patch;;'`

echo "# Applied patches" > $runlog
echo "#" >> $runlog
for i in $pruns
do
  IFS=$_ifs
  pp="`echo \"$i\" | sed -e 's;\w*[[:blank:]];;' -e 's;-p1;-p 1;;' -e 's;-b[[:blank:]];-b -B;;'`"
  pn="`echo \"$i\" | sed 's;[[:blank:]].*;;'`"
  pf="`cat $specfile | grep \"^Patch$pn:[[:blank:]]\" | sed 's;\w*:[[:blank:]];;'`"
  if [ ".$pf" != "." ]
  then
    patch $pp -i $pdir/$pf >> $outlog
    test $? -ne 0 && exit 1
    echo "$pf" >> $runlog
  fi
done

