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
dos2unix -n $1 $1.tmp 2>/dev/null
cat $1.tmp | sed 's;^SOURCE=\"\(.*\)\";SOURCE=\1;g' > $1.unm
mv $1.unm $1.tmp
sIFS=$IFS
IFS="
"

dll="`grep 'out:.*\.dll' $1.tmp | head -1 | sed 's;.*[/\\]\(.*\.dll\).*;\1;' | sed 's;\.dll;;'`"
lib="`grep 'out:.*\.lib' $1.tmp | head -1 | sed 's;.*[/\\]\(.*\.lib\).*;\1;' | sed 's;\.lib;;'`"
exe="`grep 'out:.*\.exe' $1.tmp | head -1 | sed 's;.*[/\\]\(.*\.exe\).*;\1;' | sed 's;\.exe;;'`"
printf "\n"
test ".$dll" != "." && echo "DLL_NAME=$dll"
test ".$lib" != "." && echo "LIB_NAME=$lib"
test ".$exe" != "." && echo "EXE_NAME=$exe"
printf "\n"
i=n
d=n
defs=""
incs=""
acpp="`cat $1.tmp | grep ' CPP ' | head -2`"
IFS=$sIFS
for e in $acpp
do
    if [ $d = y ]
    then
        e=`echo $e | sed 's;";;g'`
        h=`echo "$defs" | grep "\-D$e "`
        test ".$h" = . && defs="$defs -D$e"
        d=n
    fi
    if [ $i = y ]
    then
        e=`echo $e | sed 's;";;g'`
        test ".$h" = . && h=`echo "$incs" | grep " $e "`
        incs="$incs $e"
        i=n
    fi
    test ".$e" = "./I" && i=y ;
    test ".$e" = "./D" && d=y ;

done
printf 'INCLUDES = '
for i in $incs
do
    printf " \\\\\n\t-I %s" $i
done
printf "\n\n"
echo "DEFINES = $defs"
echo ""

libs=""
libp=""
acpp="`cat $1.tmp | grep ' LINK32 ' | head -2`"
IFS=$sIFS
for e in $acpp
do
    case $e in
        *.lib )
            h=`echo "$libs" | grep " $e"`
            test ".$h" = . && libs="$libs $e"
        ;;
        /libpath:* )
            e=`echo $e | sed 's;";;g'`
            h=`echo "$libp" | grep " $e"`
            test ".$h" = . && libp="$libp $e"
        ;;
        * )
        ;;
    esac
done
echo "LDDLIBS = $libs"
echo ""
echo "LIBPATH = $libp"
echo ""

printf "OBJECTS ="
IFS="
"
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
