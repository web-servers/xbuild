#!/bin/sh
# Copyright(c) 2012 Red Hat, Inc.
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
# Extract source and header files info from the .dsp
#
#
dos2unix -n $1 $1.tmp
sIFS=$IFS
IFS="
"

dll="`grep 'out:.*\.dll' $1.tmp | head -1 | sed 's;.*[/\\]\(.*\.dll\).*;\1;' | sed 's;\.dll;;'`"
lib="`grep 'out:.*\.lib' $1.tmp | head -1 | sed 's;.*[/\\]\(.*\.lib\).*;\1;' | sed 's;\.lib;;'`"
printf "\n"
test ".$dll" != "." && echo "DLL_NAME=$dll"
test ".$lib" != "." && echo "LIB_NAME=$lib"
printf "\n"

printf 'OBJECTS ='
for i in `grep -e '^SOURCE=.*\.c$' -e '^SOURCE=.*\.c"$' $1.tmp`
do
    IFS=$sIFS
    f=`echo $i | sed 's;^SOURCE=;;' | sed 's;";;g'`
    f=`echo $f | sed 's;.*\\\\\(.*\.c$\);\1;'`
    f=`echo $f | sed 's/\.c$//'`
    printf " \\\\\n\t\$(WORKDIR)\\%s.obj" $f
done
printf "\n\n\n"

cxxhdr=true
IFS="
"
for i in `grep -e '^SOURCE=.*\.cpp$' -e '^SOURCE=.*\.cpp"$' $1.tmp`
do
    IFS=$sIFS
    if $cxxhdr; then
        printf 'OBJECTS = $(OBJECTS)'
        cxxhdr=false
    fi
    f=`echo $i | sed 's;^SOURCE=;;' | sed 's;";;g'`
    f=`echo $f | sed 's;.*\\\\\(.*\.cpp$\);\1;'`
    f=`echo $f | sed 's/\.cpp$//'`
    printf " \\\\\n\t\$(WORKDIR)\\%s.obj" $f
done
if [ $cxxhdr = false ]; then
    printf "\n\n\n"
fi

IFS="
"
printf 'HEADERS ='
for i in `grep -e '^SOURCE=.*\.h$' -e '^SOURCE=.*\.h"$' $1.tmp`
do
    IFS=$sIFS
    h=`echo $i | sed 's;^SOURCE=;;' | sed 's;";;g'`
    printf " \\\\\n\t%s" $h
done
printf "\n\n\n"

pp=""
IFS="
"
for i in `grep -e '^SOURCE=.*\.c$' -e '^SOURCE=.*\.c"$' $1.tmp`
do
    IFS=$sIFS
    d=`echo $i | sed 's;^SOURCE=;;' | sed 's;";;g'`
    d=`echo $d | sed 's;\(.*\)\\\\.*\.c;\1;'`
    c=`echo $d | tr '\134' '/'`
    x=`echo "$pp" | grep ";$c"`
    if [ ".$x" = . ]; then
        printf "{\$(SRCDIR)%s}.c{\$(WORKDIR)}.obj:\n" "$d"
        printf "\t\$(CC) \$(CFLAGS) \$(INCLUDES) \$(PDBFLAGS) \$<\n\n"

        pp="$pp;$c"
    fi
done

pp=""
IFS="
"
for i in `grep -e '^SOURCE=.*\.cpp$' -e '^SOURCE=.*\.cpp"$' $1.tmp`
do
    IFS=$sIFS
    d=`echo $i | sed 's;^SOURCE=;;' | sed 's;";;g'`
    d=`echo $d | sed 's;\(.*\)\\\\.*\.cpp;\1;'`
    c=`echo $d | tr '\134' '/'`
    x=`echo "$pp" | grep ";$c"`
    if [ ".$x" = . ]; then
        printf "{\$(SRCDIR)%s}.cpp{\$(WORKDIR)}.obj:\n" "$d"
        printf "\t\$(CC) \$(CFLAGS) \$(CPPFLAGS) \$(INCLUDES) \$(PDBFLAGS) \$<\n\n"
        pp="$pp;$c"
    fi
done
printf "\n"
rm $1.tmp
