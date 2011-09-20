#!/bin/sh
# Copyright(c) 2009 Red Hat Middleware, LLC,
# and individual contributors as indicated by the @authors tag.
# See the copyright.txt in the distribution for a
# full listing of individual contributors.
#
# This library is free software; you can redistribute it and/or
# modify it under the terms of the GNU Lesser General Public
# License as published by the Free Software Foundation; either
# version 2 of the License, or (at your option) any later version.
#
# This library is distributed in the hope that it will be useful,
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
sIFS=$IFS
IFS="
"
printf "OBJECTS="
for i in `grep 'SOURCE=.*\.c$' $1`
do
    IFS=$sIFS
    f=`echo $i | tr '\\' '/' | sed 's;.*/\(.*\.c$\);\1;'`
    f=`echo $f | sed 's/\.c$//'`
    printf " \\\\\n\t\$(WORKDIR)\\%s.obj" $f
done
printf "\n\n\n"

cxxhdr=true
for i in `grep 'SOURCE=.*\.cpp$' $1`
do
    IFS=$sIFS
    if $cxxhdr; then
        printf "CXXOBJECTS="
        cxxhdr=false
    fi
    f=`echo $i | tr '\\' '/' | sed 's;.*/\(.*\.cpp$\);\1;'`
    f=`echo $f | sed 's/\.cpp$//'`
    printf " \\\\\n\t\$(WORKDIR)\\%s.obj" $f
done
if [ $cxxhdr = false ]; then
    printf "\n\n\n"
fi

IFS="
"
printf "HEADERS="
for i in `grep 'SOURCE=.*\.h$' $1`
do
    IFS=$sIFS
    h=`echo $i | sed 's;SOURCE=;;'`
    printf " \\\\\n\t%s" $h
done
printf "\n\n\n"

pp=""
IFS="
"
for i in `grep 'SOURCE=.*\.c$' $1`
do
    IFS=$sIFS
    d=`echo $i | tr '\\' '/' | sed 's;SOURCE=\.\(.*\)/.*\.c;\1;'`
    d=`echo $d | tr '/' '\\'`
    x=`echo "$pp" | grep ";$d"`
    if [ ".$x" = . ]; then
        printf "{\$(SRCDIR)%s}.c{\$(WORKDIR)}.obj:\n" "$d"
    	printf "\t\$(CC) \$(CFLAGS) \$(INCLUDES) \$(PDBFLAGS) \$<\n\n"

        pp="$pp;$d"
    fi
done

pp=""
IFS="
"
for i in `grep 'SOURCE=.*\.cpp$' $1`
do
    IFS=$sIFS
    d=`echo $i | tr '\\' '/' | sed 's;SOURCE=\.\(.*\)/.*\.cpp;\1;'`
    d=`echo $d | tr '/' '\\'`
    x=`echo "$pp" | grep ";$d"`
    if [ ".$x" = . ]; then
        printf "{\$(SRCDIR)%s}.cpp{\$(WORKDIR)}.obj:\n" "$d"
    	printf "\t\$(CC) \$(CFLAGS) \$(CXXFLAGS) \$(INCLUDES) \$(PDBFLAGS) \$<\n\n"
        pp="$pp;$d"
    fi
done
printf "\n"
