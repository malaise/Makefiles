#!/bin/sh
units=""
for file in *.ads; do
  root=`basename $file .ads`
  if [ ! -f $root.adb ] ; then
     units=$units" "$root
  fi
done
for file in *.adb; do 
  root=`basename $file .adb`
  units=$units" "$root
done
echo $units
exit 0

