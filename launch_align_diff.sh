#!/usr/bin/bash

# help
Help()
{
   # Display Help
   echo "Syntax: launch_align.sh -n dir_list [-h|v|f]"
   echo "options:"
   echo "n	   input file: list of directories"
   echo "h     Print this Help."
   echo "v     Verbose mode."
   echo "f     Force mode: overwirte all files and directories."
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

cat < $PAIRS | while true
do
   read ligne
   echo 
   echo "Processing...."
   echo $ligne
   if [ "$ligne" = "" ]; then break; fi
   set -- $ligne ; DIR1=$1 ; DIR2=$2 ;  

cd $ROOT
# set output dir
OUTPUT_DIR=$ROOT/diff-$DIR1-$DIR2

if [ $FORCE = 'TRUE' ]; then
rm -rf $OUTPUT_DIR
fi 

if [[ ! -d $OUTPUT_DIR  ]]; then
mkdir $OUTPUT_DIR
fi

if [[ ! -f $OUTPUT_DIR/run-trans_reference-DEM.tif ]]; then
pc_align --max-displacement 100 --save-transformed-source-points --save-inv-transformed-reference-points $ROOT/$DIR1/demPleiades/dem-PC.tif $ROOT/$DIR2/demPleiades/dem-PC.tif -o $OUTPUT_DIR/run
cd $OUTPUT_DIR
point2dem --t_srs EPSG:$UTM  --tr $RES run-trans_reference.tif --median-filter-params $MED_F_PAR --dem-hole-fill-len $DEM_HOLE_F_L --erode-length $ERODE_L --nodata-value $NO_DATA_DEM --tif-compress $TIF_COMPR --max-valid-triangulation-error $MAX_V_TRIANG_ERR --remove-outliers-param $RM_OUTL_PARA --threads $THREADS
fi

if [[ ! -f $OUTPUT_DIR/diff-dsm.tif ]]; then
# clipping the ref DEM with the another DEM and compute diff
echo raster_diff.py --infile1=$OUTPUT_DIR/run-trans_reference-DEM.tif --infile2=$ROOT/$DIR2/demPleiades/dem-DEM.tif --outfile=diff-dsm.tif
raster_diff.py --infile1=$OUTPUT_DIR/run-trans_reference-DEM.tif --infile2=$ROOT/$DIR2/demPleiades/dem-DEM.tif --outfile=diff-dsm.tif
fi 

if [[ ! -f $OUTPUT_DIR/dsm1_clipped.tif ]]; then
# compute slope on reference DEM
echo raster_diff.py --infile1=$OUTPUT_DIR/run-trans_reference-DEM.tif --infile2=$ROOT/$DIR2/demPleiades/dem-DEM.tif --outfile=dsm1_clipped.tif
raster_diff.py --infile1=$OUTPUT_DIR/run-trans_reference-DEM.tif --infile2=$ROOT/$DIR2/demPleiades/dem-DEM.tif --outfile=$OUTPUT_DIR/dsm1_clipped.tif
echo gdaldem slope $OUTPUT_DIR/run-trans_reference-DEM.tif  $OUTPUT_DIR/dsm1_clipped_slope.tif  -of GTiff -b 1 -s 1.0
gdaldem slope $OUTPUT_DIR/dsm1_clipped.tif  $OUTPUT_DIR/dsm1_clipped_slope.tif  -of GTiff -b 1 -s 1.0 
fi

# compute error estimation
dem_error_estimation.py --diff=$OUTPUT_DIR/diff-dsm.tif --slope=$OUTPUT_DIR/dsm1_clipped_slope.tif

done
