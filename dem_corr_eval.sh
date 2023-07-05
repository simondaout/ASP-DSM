#!/usr/bin/bash

# help
Help()
{
   # Display Help
   echo "Syntax: dem_corr_eval.sh -n pair_list "
   echo "options:"
   echo "n         input file: list of pairs"
   echo "h     Print this Help."
   echo "Carefull:  asp_parameters.txt file must be in this directory"
   echo
}

while getopts ":hvfn:" option; do
   case $option in
      h) # display Help
         Help
         exit;;
      n) PAIRS=$OPTARG;;
      \?) echo "Error: "$OPTARG "is an invalid option"
                exit;;
   esac
done

# Initial checkings
if [ -z $PAIRS ]; then { Help; exit 1; } fi

if [ ! -f "asp_parameters.txt" ]; then
    echo "missing parameter file: asp_parameters.txt"
    echo ; exit
fi

. ./asp_parameters.txt

# set home directory
ROOT=$PWD

TRISTEREO=FALSE
# check if stereo or tri-stereo
cols=`awk '{print NF}' $PAIRS | tail -n 1`
if [[ $cols -eq '6' ]]; then
TRISTEREO=TRUE
elif [[ $cols  -eq '4' ]]; then
TRISTEREO=FALSE
else
echo "Invalid number of columns in input pair list file. Must be 4 (stereo) or 6 (tri-stereo)"
echo ; exit
fi

cat < $PAIRS | while true
do
   read ligne
   echo
   echo "Processing...."
   echo $ligne
   if [ "$ligne" = "" ]; then break; fi
   if [[ $TRISTEREO = 'TRUE'  ]]; then
   set -- $ligne ; DATE1=$1 ; NAME1=$2 ; DATE2=$3 ; NAME2=$4 ; DATE3=$5 ; NAME3=$6 ;
   else
   set -- $ligne ; DATE1=$1 ; NAME1=$2 ; DATE2=$3 ; NAME2=$4 ;
   fi
cd $ROOT

# set output dir
OUTPUT_DIR=$ROOT/$NAME1"-"$NAME2

#############
# CORR EVAL #
#############

cd $OUTPUT_DIR

# set prefilter mode depending of stereo-algorithm
if [[ $ST_ALG == "asp_bm" ]]; then
PREF_MODE_EVAL="2"
else
PREF_MODE_EVAL="0"
fi

if [[ $TRISTEREO = 'TRUE'  ]]; then

# compute corr_eval for each dem-pair in demPleiades
if [[ ! -f $OUTPUT_DIR"/demPleiades/dem-pair1/dem-ncc.tif" ]]; then
echo $OUTPUT_DIR/demPleiades/dem-pair1
cd $OUTPUT_DIR/demPleiades/dem-pair1
corr_eval --prefilter-mode $PREF_MODE_EVAL --kernel-size $CORR_KERNEL --metric ncc "1-L.tif" "1-R.tif" "1-F.tif" dem
fi

if [[ ! -f $OUTPUT_DIR"/demPleiades/dem-pair2/dem-ncc.tif" ]]; then
echo $OUTPUT_DIR/demPleiades/dem-pair2
cd $OUTPUT_DIR/demPleiades/dem-pair2
corr_eval --prefilter-mode $PREF_MODE_EVAL --kernel-size $CORR_KERNEL --metric ncc "2-L.tif" "2-R.tif" "2-F.tif" dem
fi


# compute corr_eval for each dem-pair in demPleiades-filt
if [[ ! -f $OUTPUT_DIR"/demPleiades-filt/dem-pair1/dem-ncc.tif" ]]; then
echo $OUTPUT_DIR/demPleiades-filt/dem-pair1
cd $OUTPUT_DIR/demPleiades-filt/dem-pair1
corr_eval --prefilter-mode $PREF_MODE_EVAL --kernel-size $CORR_KERNEL --metric ncc "1-L.tif" "1-R.tif" "1-F.tif" dem
fi

if [[ ! -f $OUTPUT_DIR"/demPleiades-filt/dem-pair2/dem-ncc.tif" ]]; then
echo $OUTPUT_DIR/demPleiades-filt/dem-pair2
cd $OUTPUT_DIR/demPleiades-filt/dem-pair2
corr_eval --prefilter-mode $PREF_MODE_EVAL --kernel-size $CORR_KERNEL --metric ncc "2-L.tif" "2-R.tif" "2-F.tif" dem
fi

else

# compute corr_eval in demPleiades
if [[ ! -f $OUTPUT_DIR"/demPleiades/dem-ncc.tif" ]]; then
echo $OUTPUT_DIR/demPleiades
cd $OUTPUT_DIR/demPleiades
corr_eval --prefilter-mode $PREF_MODE_EVAL --kernel-size $CORR_KERNEL --metric ncc "dem-L.tif" "dem-R.tif" "dem-F.tif" dem
fi


# compute corr_eval in demPleiades-filt
if [[ ! -f $OUTPUT_DIR"/demPleiades-filt/dem-ncc.tif" ]]; then
echo $OUTPUT_DIR/demPleiades-filt
cd $OUTPUT_DIR/demPleiades-filt
corr_eval --prefilter-mode $PREF_MODE_EVAL --kernel-size $CORR_KERNEL --metric ncc "dem-L.tif" "dem-R.tif" "dem-F.tif" dem
fi

fi

exit

done 

