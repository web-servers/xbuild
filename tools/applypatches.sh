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
_ifs=$IFS

xbexit()
{
    e=$1; shift;
    echo "$@" 1>&2
    exit $e
}

srcdir="`basename $cdir`"
runlog="$cdir/appliedpatches.log"
specfn="`find $pdir -maxdepth 1 -name '*.spec' -type f -exec basename '{}' \;`"

test ".$specfn" = . && xbexit 1 "Cannot find .spec file in \`$pdir'"
specfile="$pdir/$specfn"
echo "Applying patches from $specfn"
if [ -f "$pdir/.git/config" ]
then
  bname="`cat \"$pdir/.git/config\" | grep '\[branch "' | sed 's;\[branch "\(.*\)"\];\1;'`"
else
  bname="unknown"
fi
echo "Applied patches for $srcdir from $bname/$specfn" > $runlog

IFS=$lf
hasas="`cat $specfile | grep -A 5 '^%prep$' | grep '^%autosetup' | sed 's;%autosetup.*;yes;'`"
if [ ".$hasas" == ".yes" ]
then
  pruns=`cat $specfile | grep '^Patch[0-9]*:[[:blank:]]*' | sed 's;\w*:[[:blank:]]*;;'`
else
  pruns=`cat $specfile | grep '^%patch[0-9]*[[:blank:]]*' | sed 's;^%patch;;'`
fi

cnt=0
for i in $pruns
do
  IFS=$_ifs
  if [ ".$hasas" == ".yes" ]
  then
    pp="-p 1"
    pf="$i"
  else
    pp="`echo \"$i\" | sed 's;.*-p\([0-9]\).*;-p \1;;'`"
    pn="`echo \"$i\" | sed 's;[[:blank:]].*;;'`"
    pf="`cat $specfile | grep \"^Patch$pn:[[:blank:]]\" | sed 's;\w*:[[:blank:]]*;;'`"
  fi
  if [ ".$pf" != "." ]
  then
    patch $pp -i $pdir/$pf
    test $? -ne 0 && xbexit 1 "Cannot apply $pf"
    echo "$pf" >> $runlog
    let "cnt=cnt+1"
  fi
done

echo "Applied $cnt patches"

