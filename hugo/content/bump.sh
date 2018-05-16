#!/bin/bash
OLD="1.8.2"
NEW="1.8.3"
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
DPATH=$DIR/*.adoc
BPATH=/tmp/backups
TFILE="/tmp/out.tmp.$$"
[ ! -d $BPATH ] && mkdir -p $BPATH || :
for f in $DPATH
do
  if [ -f $f -a -r $f ]; then
    /bin/cp -f $f $BPATH
   sed "s/$OLD/$NEW/g" "$f" > $TFILE && mv $TFILE "$f"
  else
   echo "Error: Cannot read $f"
  fi
done
/bin/rm $TFILE
