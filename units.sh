#!/bin/sh
units=""
for file in `ls *.ads 2>/dev/null`; do
  root=`basename $file .ads`
  if [ ! -f $root.adb ] ; then
     units=$units" "$root
  fi
done
for file in `ls *.adb 2>/dev/null`; do 
  root=`basename $file .adb`
  units=$units" "$root
done
echo $units
exit 0

