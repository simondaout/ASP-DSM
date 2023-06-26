#!/usr/bin/bash

# Initial checkings
[ $# -eq 0 ] && { echo "Usage: $0 pair_list"; exit 1; }

# set home directory
ROOT=$PWD

cat < $1 | while true
do
   read ligne
   if [ "$ligne" = "" ]; then break; fi
   set -- $ligne ; DATE1=$1 ; NAME1=$2 ; DATE2=$3 ; NAME2=$4 ;

cd $ROOT

# set output dir
OUTPUT_DIR=$NAME1"-"$NAME2

if [[  ! -d $OUTPUT_DIR"/demPleiades" ]]
then
	echo $DATE1 $NAME1 $DATE2 $NAME2
fi

done
