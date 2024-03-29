#!/bin/sh
# Copyright(c) 2022 Red Hat, Inc.
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
# Perform 'git pull' for each directory inside current dir
# This utility goes trough each subdirectory inside current
# current directory and performs git pull if subdir is a local
# git repository and was cloned using current username
#
#
set +e +x

dogitpull()
{

    for i in `ls -1`
    do
      if [ -f "$i/.git/config" ]
      then
        pushd $i >/dev/null
        repo="`basename $i`"
        if [ -n "$repo" ]
        then
          echo "Pulling '$repo' ..."
          git pull
          test $? -ne 0 && exit 1
          echo
        fi
        popd  >/dev/null
      fi
    done

}

if [ "x$1" = "x" ]; then
  dogitpull
else
  for o
  do
    pushd $o >/dev/null
    echo "Pulling from '$o'"
    dogitpull
    popd  >/dev/null

  done
fi

echo "Done"

