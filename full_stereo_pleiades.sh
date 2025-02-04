#!/usr/bin/bash

# help
Help()
{
   # Display Help
   echo "Syntax: launch_stereo_pleiades.sh -n pair_list [-h|v|f]"
   echo "options:"
   echo "n	   input file: list of pairs"
   echo "h     Print this Help."
   echo "v     Verbose mode."
   echo "f     Force mode: overwrite all files and directories."
   echo "Carefull:  asp_parameters.txt file must be in this directory"
   echo
}

FORCE='FALSE'
VERBOSE='FALSE'
# Get the options
while getopts ":hvfn:" option; do
   case $option in
      h) # display Help
         Help
         exit;;
      v) # verbose mode
         VERBOSE='TRUE';;
      f) # force mode
		 FORCE='TRUE';;
	  n) PAIRS=$OPTARG;; 
	  \?) echo "Error: "$OPTARG "is an invalid option"
		exit;;
   esac
done

#echo $PAIRS
#echo $FORCE
#echo $VERBOSE

# Initial checkings
if [ -z $PAIRS ]; then { Help; exit 1; } fi

if [ ! -f "asp_parameters.txt" ]; then
    echo "missing parameter file: asp_parameters.txt"
    echo ; exit
fi

module load asp
. ./asp_parameters.txt

# set input DEM
DEM=$DEM_FILE
DEM_UTM_FILE=$PWD"/"$(basename $DEM .tif)"_utm.tif"

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

	. ./set_dirs.sh

	###########
	# REF DEM #
	###########

	. ./ref_dem.sh

	##################
	# TILED IMAGES   #
	##################

	. ./tiled_images.sh

	##################
	# CHANGE DIR     #
	##################

	if [ $FORCE = 'TRUE' ]; then
	rm -rf $OUTPUT_DIR/demPleiades
	rm -rf $OUTPUT_DIR/demPleiades-filt
	fi 

	if [[ ! -d $OUTPUT_DIR  ]]; then
	mkdir $OUTPUT_DIR
	fi

	if [[ ! -d $OUTPUT_DIR'/MAPPROJ'  ]]; then
	mkdir $OUTPUT_DIR'/MAPPROJ'
	fi

	# copy parameter file to new working dir
	cp asp_parameters.txt $OUTPUT_DIR"/."
	# change to working dir; TIMESTAMP bc this is the name of the current working dir
	cd $OUTPUT_DIR

	##################
	# BUNDLE ADJUST #
	##################
	# perform bundle and map project only if map projected image does not exist

	if [[ ! -d ba ]]; then

	. ./bundle_adjust.sh

	fi

	# #########################
	# # check locations in GE #
	# #########################

	. ./orbit_viz.sh

	# ###############
	# # Map Project #
	# ###############

	. ./map_project.sh

	##############
	# RUN STEREO #
	##############

	session="--nodata-value $NO_DATA_S $DEM_UTM_FILE  --threads-multiprocess $THREADS" 
	stereo="--prefilter-mode $PREF_MODE --prefilter-kernel-width $PREF_KER_M --corr-kernel $CORR_KERNEL --cost-mode $COST_MODE --stereo-algorithm $ST_ALG --corr-tile-size $CORR_T_S --subpixel-mode $SUBP_MODE --subpixel-kernel $SUBP_KERNEL --corr-seed-mode $CORR_S_MODE --xcorr-threshold $XCORR_TH --min-xcorr-level $MIN_XCORR_LVL --sgm-collar-size $SGM_C_SIZE" 
	denoising="--rm-quantile-percentile $RM_QUANT_PC --rm-quantile-multiple $RM_QUANT_MULT --filter-mode $FILTER_MODE --rm-half-kernel $RM_HALF_KERN --rm-min-matches $RM_MIN_MATCHES --rm-threshold $RM_THRESHOLD --max-mean-diff $MAX_DIFF" 
	filtering="--median-filter-size $MED_FILTER_SIZE --texture-smooth-size $TEXT_SMOOTH_SIZE --texture-smooth-scale $TEXT_SMOOTH_SCALE" 

	cd $OUTPUT_DIR

	. ./run_stereo.sh

	#############
	# POINT2DEM #
	#############

	. ./point2dem.sh

	# exit pair
	cd $ROOT

# exit loop
done

exit

