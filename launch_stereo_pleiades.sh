#!/usr/bin/bash

# help
Help()
{
   # Display Help
   echo "Syntax: launch_stereo_dem.sh -n pair_list [-h|v|f]"
   echo "options:"
   echo "n	   input file: list of pairs"
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

cat < $PAIRS | while true
do
   read ligne
   echo 
   echo "Processing...."
   echo $ligne
   if [ "$ligne" = "" ]; then break; fi
   set -- $ligne ; DATE1=$1 ; NAME1=$2 ; DATE2=$3 ; NAME2=$4 ;

cd $ROOT

# set output dir
OUTPUT_DIR=$ROOT/$NAME1"-"$NAME2

if [[ -d $DATA_DIR"/"$NAME1"/IMG_PHR1A_P_001/" ]]
then
	# set input images
	DIR1=$DATA_DIR"/"$NAME1"/IMG_PHR1A_P_001"
	if [[ $SESSION_TYPE = 'rpc' ]]; then
	Lrpc=$DIR1"/RPC_PHR1A_P_"$DATE1"_SEN_"$NAME1"-1.XML"
	elif [[ $SESSION_TYPE = 'pleiades' ]]; then
	Lrpc=$DIR1"/DIM_PHR1A_P_"$DATE1"_SEN_"$NAME1"-1.XML"
	else
	echo "Unknown session type, chose rpc or pleiades"
    echo ; exit	
else
	# set input images
	DIR1=$DATA_DIR"/"$NAME1"/IMG_PHR1B_P_001"
	if [[ $SESSION_TYPE = 'rpc' ]]; then
	Lrpc=$DIR1"/RPC_PHR1B_P_"$DATE1"_SEN_"$NAME1"-1.XML"
	elif [[ $SESSION_TYPE = 'pleiades' ]]; then
	Lrpc=$DIR1"/DIM_PHR1B_P_"$DATE1"_SEN_"$NAME1"-1.XML"
	else
	echo "Unknown session type, chose rpc or pleiades"
    echo ; exit	
fi
IMG1=$DIR1"/image1.tif"
IMG1_MP=$OUTPUT_DIR"/img1_mapproj.tif"
ORTHO1=$OUTPUT_DIR"/orthoimage_forward.tif"

if [[ -d $DATA_DIR"/"$NAME2"/IMG_PHR1A_P_001/" ]]
then
	# set input images
	DIR2=$DATA_DIR"/"$NAME2"/IMG_PHR1A_P_001"
	if [[ $SESSION_TYPE = 'rpc' ]]; then
	Rrpc=$DIR2"/RPC_PHR1A_P_"$DATE2"_SEN_"$NAME2"-1.XML"
	elif [[ $SESSION_TYPE = 'pleiades' ]]; then
	Rrpc=$DIR2"/DIM_PHR1A_P_"$DATE2"_SEN_"$NAME2"-1.XML"
	else
	echo "Unknown session type, chose rpc or pleiades"
    echo ; exit	
else
	# set input images
	DIR2=$DATA_DIR"/"$NAME2"/IMG_PHR1B_P_001"
	if [[ $SESSION_TYPE = 'rpc' ]]; then
	Rrpc=$DIR2"/RPC_PHR1B_P_"$DATE2"_SEN_"$NAME2"-1.XML"
	elif [[ $SESSION_TYPE = 'pleiades' ]]; then
	Rrpc=$DIR2"/DIM_PHR1B_P_"$DATE2"_SEN_"$NAME2"-1.XML"
	else
	echo "Unknown session type, chose rpc or pleiades"
    echo ; exit	
fi
IMG2=$DIR2"/image2.tif"
IMG2_MP=$OUTPUT_DIR"/img2_mapproj.tif"
ORTHO2=$OUTPUT_DIR"/orthoimage_backward.tif"

###########
# REF DEM #
###########

if [[ ! -f $DEM_UTM_FILE ]]; then
	gdalwarp -tr $GDAL_OUT_RES -t_srs EPSG:$UTM $DEM $DEM_UTM_FILE -r $RESAMP_M -overwrite
fi 

##################
# TILED IMAGES   #
##################

# With some Airbus Pleiades data, each of the left and right images may arrive broken up into .TIF or .JP2 tiles, with names ending in R1C1.tif, R2C1.tif, etc.

if [ $FORCE = 'TRUE' ]; then
rm -f $IMG1 $IMG2
fi 

if [[ -f $IMG1 ]]; then
	echo "$IMG1 exists."
else
	# These need to be mosaicked before being used
	gdalbuildvrt $DIR1"/vrt.tif" $DIR1"/"*"R"*"C"*".TIF"
	#actual self-contained image can be produced with:
	gdal_translate -co TILED=YES -co BLOCKXSIZE=256 -co BLOCKYSIZE=256 -co BIGTIFF=IF_SAFER $DIR1"/vrt.tif" $IMG1
fi

if [[ -f $IMG2 ]]; then
    echo "$IMG2 exists."
else
	gdalbuildvrt $DIR2"/vrt.tif" $DIR2"/"*"R"*"C"*".TIF"
	gdal_translate -co TILED=YES -co BLOCKXSIZE=256 -co BLOCKYSIZE=256 -co BIGTIFF=IF_SAFER $DIR2"/vrt.tif" $IMG2
fi

##################
# CHANGE DIR     #
##################

if [ $FORCE = 'TRUE' ]; then
rm -rf $OUTPUT_DIR
fi 

if [[ ! -d $OUTPUT_DIR  ]]; then
mkdir $OUTPUT_DIR
fi

# copy parameter file to new working dir
cp asp_parameters.txt $OUTPUT_DIR"/."
# change to working dir; TIMESTAMP bc this is the name of the current working dir
cd $OUTPUT_DIR

##################
# BUNDLE ADJUST #
##################
# perform bundle and map project only if map projected image does not exist
if [[ ! -f $IMG2_MP ]]; then

#bundle_adjust $IMG1 $IMG2 $Lrpc $Rrpc -t $SESSION_TYPE --camera-weight 0 --tri-weight 0.1 --min-matches 15  --datum wgs84 -o ba/run
bundle_adjust  $IMG1 $IMG2 $Lrpc $Rrpc -t $SESSION_TYPE --datum wgs84 -o ba/run --ip-detect-method 0 --ip-per-tile 50 --ip-inlier-factor 0.4 --num-passes 2 --min-matches 15 --robust-threshold 0.5 --parameter-tolerance 1e-10 --max-iterations 500 --camera-weight 0 --tri-weight 0.1

# ###############
# # Map Project #
# ###############

if [[ ! -f "ba/run-image1__image2.match" ]]; then
mapproject -t $SESSION_TYPE --t_srs EPSG:$UTM --tr $RESMP $DEM $IMG1 $Lrpc $IMG1_MP --nodata-value 0
mapproject -t $SESSION_TYPE --t_srs EPSG:$UTM --tr $RESMP $DEM $IMG2 $Rrpc $IMG2_MP --nodata-value 0
else
mapproject -t $SESSION_TYPE --t_srs EPSG:$UTM --tr $RESMP $DEM $IMG1 $Lrpc $IMG1_MP --bundle-adjust-prefix ba/run --nodata-value 0
mapproject -t $SESSION_TYPE --t_srs EPSG:$UTM --tr $RESMP $DEM $IMG2 $Rrpc $IMG2_MP --bundle-adjust-prefix ba/run --nodata-value 0
fi

# convert in Int16 format & COMPRESS
gdalwarp -wm 512 -q -co COMPRESS=DEFLATE -overwrite -of GTiff -ot UInt16 -r cubic $IMG1_MP $ORTHO1 
gdalwarp -wm 512 -q -co COMPRESS=DEFLATE -overwrite -of GTiff -ot UInt16 -r cubic $IMG2_MP $ORTHO2 

fi 

##############
# RUN STEREO #
##############

if [[ ! -f "demPleiades/dem-PC.tif" ]]; then

# if filtering is selected in asp_parameters.txt, the following parameters will be included for parallel_stereo: rm-quantile-percentile, rm-quantile-multiple, rm-cleanup-passes, filter-mode, rm-half-kernel, rm-min-matches, rm-threshold

if [ $FILTERING = true ]
then

if [[ ! -f "ba/run-image1__image2.match" ]]; then
parallel_stereo -t $SESSION_TYPE --alignment-method $A_M $IMG1_MP $IMG2_MP $Lrpc $Rrpc demPleiades/dem $DEM_UTM_FILE --nodata-value $NO_DATA_S --prefilter-mode $PREF_MODE --prefilter-kernel-width $PREF_KER_M --corr-kernel $CORR_KERNEL --cost-mode $COST_MODE --stereo-algorithm $ST_ALG --corr-tile-size $CORR_T_S --subpixel-mode $SUBP_MODE --subpixel-kernel $SUBP_KERNEL --corr-seed-mode $CORR_S_MODE --processes $THREADS --xcorr-threshold $XCORR_TH --min-xcorr-level $MIN_XCORR_LVL --sgm-collar-size $SGM_C_SIZE --rm-quantile-percentile $RM_QUANT_PC --rm-quantile-multiple $RM_QUANT_MULT --rm-cleanup-passes $RM_CLEAN_PASS --filter-mode $FILTER_MODE --rm-half-kernel $RM_HALF_KERN --rm-min-matches $RM_MIN_MAT --rm-threshold $RM_TH
else
parallel_stereo -t $SESSION_TYPE --alignment-method $A_M $IMG1_MP $IMG2_MP $Lrpc $Rrpc demPleiades/dem $DEM_UTM_FILE  --bundle-adjust-prefix ba/run --nodata-value $NO_DATA_S --prefilter-mode $PREF_MODE --prefilter-kernel-width $PREF_KER_M --corr-kernel $CORR_KERNEL --cost-mode $COST_MODE --stereo-algorithm $ST_ALG --corr-tile-size $CORR_T_S --subpixel-mode $SUBP_MODE --subpixel-kernel $SUBP_KERNEL --corr-seed-mode $CORR_S_MODE --processes $THREADS --xcorr-threshold $XCORR_TH --min-xcorr-level $MIN_XCORR_LVL --sgm-collar-size $SGM_C_SIZE --rm-quantile-percentile $RM_QUANT_PC --rm-quantile-multiple $RM_QUANT_MULT --rm-cleanup-passes $RM_CLEAN_PASS --filter-mode $FILTER_MODE --rm-half-kernel $RM_HALF_KERN --rm-min-matches $RM_MIN_MAT --rm-threshold $RM_TH
fi 

else

if [[ ! -f "ba/run-image1__image2.match" ]]; then
parallel_stereo -t $SESSION_TYPE --alignment-method $A_M $IMG1_MP $IMG2_MP $Lrpc $Rrpc demPleiades/dem $DEM_UTM_FILE --nodata-value $NO_DATA_S --corr-kernel $CORR_KERNEL --cost-mode $COST_MODE --stereo-algorithm $ST_ALG --corr-tile-size $CORR_T_S --subpixel-mode $SUBP_MODE --subpixel-kernel $SUBP_KERNEL --corr-seed-mode $CORR_S_MODE --processes $THREADS --xcorr-threshold $XCORR_TH --min-xcorr-level $MIN_XCORR_LVL --sgm-collar-size $SGM_C_SIZE --prefilter-mode $PREF_MODE --prefilter-kernel-width $PREF_KER_M
else
parallel_stereo -t $SESSION_TYPE --alignment-method $A_M $IMG1_MP $IMG2_MP $Lrpc $Rrpc demPleiades/dem $DEM_UTM_FILE --bundle-adjust-prefix ba/run --nodata-value $NO_DATA_S --corr-kernel $CORR_KERNEL --cost-mode $COST_MODE --stereo-algorithm $ST_ALG --corr-tile-size $CORR_T_S --subpixel-mode $SUBP_MODE --subpixel-kernel $SUBP_KERNEL --corr-seed-mode $CORR_S_MODE --processes $THREADS --xcorr-threshold $XCORR_TH --min-xcorr-level $MIN_XCORR_LVL --sgm-collar-size $SGM_C_SIZE --prefilter-mode $PREF_MODE --prefilter-kernel-width $PREF_KER_M
fi

fi
fi

#############
# POINT2DEM #
#############

# the dem-PC file is stored in demPleiades; the final dem-DEM.tif will be created within demPleiades
cd $OUTPUT_DIR/demPleiades

if [[ ! -f "demPleiades/dem-DEM.tif" ]]; then
point2dem --t_srs EPSG:$UTM --tr $RES dem-PC.tif --median-filter-params $MED_F_PAR --dem-hole-fill-len $DEM_HOLE_F_L --erode-length $ERODE_L --nodata-value $NO_DATA_DEM --tif-compress $TIF_COMPR --max-valid-triangulation-error $MAX_V_TRIANG_ERR --remove-outliers-param $RM_OUTL_PARA --threads $THREADS

# convert in Int16 format & COMPRESS
gdalwarp -wm 512 -q -co COMPRESS=DEFLATE -overwrite -of GTiff -ot UInt16 -r cubic dem-DEM.tif ../dsm_denoised.tiff
#gdalwarp -wm 512 -q -co COMPRESS=DEFLATE -overwrite -of GTiff -ot UInt16 -r cubic dem-F.tif ../dsm_denoised_filtered.tiff

# create hillshade
gdaldem hillshade ../dsm_denoised.tiff ../hillshade_denoised.tiff  -of GTiff -b 1 -z 1.0 -s 1.0 -az 315.0 -alt 45.0 
#gdaldem hillshade ../dsm_denoised_filtered.tiff ../hillshade_denoised_filtered.tiff  -of GTiff -b 1 -z 1.0 -s 1.0 -az 315.0 -alt 45.0 

fi

# exit pair
cd $ROOT

# exit loop
done

exit

