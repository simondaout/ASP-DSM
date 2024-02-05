#!/usr/bin/bash

# load asp
module load asp

# help
Help()
{
   # Display Help
   echo "Syntax: launch_correl_pleiades.sh asp_parameters.txt"
   echo "asp_parameters.txt: parameter file"
   echo
}

if [ -z $1 ]; then { Help; exit 1; } fi
source $1

IMG1="$HOME/INPUT/orthoimage_"$GEOM"_"$DATE1".tif"
IMG2="$HOME/INPUT/orthoimage_"$GEOM"_"$DATE2".tif"
IMG1_CROP="$HOME/INPUT/orthoimage_"$GEOM"_crop_"$DATE1".tif"
IMG2_CROP="$HOME/INPUT/orthoimage_"$GEOM"_crop_"$DATE2".tif"

#####################
# CROP
#####################

CROP1=`echo ${CROP[0]}`
CROP2=`echo ${CROP[1]}`
CROP3=`echo ${CROP[2]}`
CROP4=`echo ${CROP[3]}`

gdal_translate -projwin $CROP1 $CROP2 $CROP3 $CROP4  -of GTiff $IMG1 $IMG1_CROP 
gdal_translate -projwin $CROP1 $CROP2 $CROP3 $CROP4  -of GTiff $IMG2 $IMG2_CROP  

#####################
# CORRELATION
#####################

cd $HOME
DIR1=${DATE1:0:8}
DIR2=${DATE2:0:8}
PAIR=$DIR1"_"$DIR2
#rm -rf $PAIR
mkdir $PAIR
cd $PAIR

session=" -t $SESSION_TYPE --individually-normalize  --alignment-method $A_M --threads-multiprocess $THREADS"
stereo="--corr-kernel $CORR_KERNEL --cost-mode $COST_MODE --stereo-algorithm $ST_ALG --corr-tile-size $CORR_T_S --subpixel-mode $SUBP_MODE --subpixel-kernel $SUBP_KERNEL --corr-seed-mode $CORR_S_MODE --xcorr-threshold $XCORR_TH --min-xcorr-level $MIN_XCORR_LVL --sgm-collar-size $SGM_C_SIZE"
denoising="--rm-quantile-multiple $RM_QUANT_MULT --filter-mode $FILTER_MODE" 
filtering="--median-filter-size $MED_FILTER_SIZE --texture-smooth-size $TEXT_SMOOTH_SIZE --texture-smooth-scale $TEXT_SMOOTH_SCALE"

parallel_stereo $session $IMG1_CROP $IMG2_CROP $BLACK_LEFT $BLACK_RIGHT $OUTPUT_DIR $stereo $filtering  
gdal_translate -q -b 1 -co COMPRESS=LZW $OUTPUT_DIR-F.tif EW_"$GEOM"_"${DATE1:0:8}"_"${DATE2:0:8}"_filter.tif
gdal_translate -q -b 2 -co COMPRESS=LZW $OUTPUT_DIR-F.tif NS_"$GEOM"_"${DATE1:0:8}"_"${DATE2:0:8}"_filter.tif
gdal_translate -q -b 3 -co COMPRESS=LZW $OUTPUT_DIR-F.tif CC_"$GEOM"_"${DATE1:0:8}"_"${DATE2:0:8}"_filter.tif

