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

if [[ -d $DATA_DIR"/"$NAME1"/IMG_PHR1A_P_001/" ]]
then
	# set input images
	DIR1=$DATA_DIR"/"$NAME1"/IMG_PHR1A_P_001"
	if [[ $SESSION_TYPE = 'rpc' ]]; then
	Lrpc=$DIR1"/RPC_PHR1A_P_"$DATE1"_SEN_"$NAME1"-1.XML"
	elif [[ $SESSION_TYPE = 'pleiades' ]]; then
	Lrpc=$DIR1"/DIM_PHR1A_P_"$DATE1"_SEN_"$NAME1"-1.XML"
	else
	echo "Unknown session type, choose rpc or pleiades"
    echo ; exit	
	fi
else
	# set input images
	DIR1=$DATA_DIR"/"$NAME1"/IMG_PHR1B_P_001"
	if [[ $SESSION_TYPE = 'rpc' ]]; then
	Lrpc=$DIR1"/RPC_PHR1B_P_"$DATE1"_SEN_"$NAME1"-1.XML"
	elif [[ $SESSION_TYPE = 'pleiades' ]]; then
	Lrpc=$DIR1"/DIM_PHR1B_P_"$DATE1"_SEN_"$NAME1"-1.XML"
	else
	echo "Unknown session type, choose rpc or pleiades"
    echo ; exit
	fi	
fi
IMG1=$DIR1"/image1.tif"
IMG1_MP=$DIR1"/img1_mapproj.tif"
ORTHO1=$OUTPUT_DIR"/orthoimage_forward_$DATE1.tif"

if [[ -d $DATA_DIR"/"$NAME2"/IMG_PHR1A_P_001/" ]]
then
	# set input images
	DIR2=$DATA_DIR"/"$NAME2"/IMG_PHR1A_P_001"
	if [[ $SESSION_TYPE = 'rpc' ]]; then
	Rrpc=$DIR2"/RPC_PHR1A_P_"$DATE2"_SEN_"$NAME2"-1.XML"
	elif [[ $SESSION_TYPE = 'pleiades' ]]; then
	Rrpc=$DIR2"/DIM_PHR1A_P_"$DATE2"_SEN_"$NAME2"-1.XML"
	else
	echo "Unknown session type, choose rpc or pleiades"
    echo ; exit
	fi	
else
	# set input images
	DIR2=$DATA_DIR"/"$NAME2"/IMG_PHR1B_P_001"
	if [[ $SESSION_TYPE = 'rpc' ]]; then
	Rrpc=$DIR2"/RPC_PHR1B_P_"$DATE2"_SEN_"$NAME2"-1.XML"
	elif [[ $SESSION_TYPE = 'pleiades' ]]; then
	Rrpc=$DIR2"/DIM_PHR1B_P_"$DATE2"_SEN_"$NAME2"-1.XML"
	else
	echo "Unknown session type, choose rpc or pleiades"
    echo ; exit
	fi	
fi
IMG2=$DIR2"/image2.tif"
IMG2_MP=$DIR2"/img2_mapproj.tif"
ORTHO2=$OUTPUT_DIR"/orthoimage_backward_$DATE2.tif"

if [[ $TRISTEREO = 'TRUE'  ]]; then

if [[ -d $DATA_DIR"/"$NAME3"/IMG_PHR1A_P_001/" ]]
then
    # set input images
    DIR3=$DATA_DIR"/"$NAME3"/IMG_PHR1A_P_001"
    if [[ $SESSION_TYPE = 'rpc' ]]; then
    Mrpc=$DIR3"/RPC_PHR1A_P_"$DATE3"_SEN_"$NAME3"-1.XML"
    elif [[ $SESSION_TYPE = 'pleiades' ]]; then
    Mrpc=$DIR3"/DIM_PHR1A_P_"$DATE3"_SEN_"$NAME3"-1.XML"
    else
    echo "Unknown session type, choose rpc or pleiades"
    echo ; exit
    fi
else
    # set input images
    DIR3=$DATA_DIR"/"$NAME3"/IMG_PHR1B_P_001"
    if [[ $SESSION_TYPE = 'rpc' ]]; then
    Mrpc=$DIR3"/RPC_PHR1B_P_"$DATE3"_SEN_"$NAME3"-1.XML"
    elif [[ $SESSION_TYPE = 'pleiades' ]]; then
    Mrpc=$DIR3"/DIM_PHR1B_P_"$DATE3"_SEN_"$NAME3"-1.XML"
    else
    echo "Unknown session type, choose rpc or pleiades"
    echo ; exit
    fi
fi
IMG3=$DIR3"/image3.tif"
IMG3_MP=$DIR3"/img3_mapproj.tif"
ORTHO3=$OUTPUT_DIR"/orthoimage_nadir_$DATE3.tif"

fi

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
if [[ $TRISTEREO = 'TRUE'  ]]; then
rm -f $IMG1 $IMG2 $IMG3 $IMG1_MP $IMG2_MP $IMG3_MP 
else
rm -f $IMG1 $IMG2 $IMG1_MP $IMG2_MP
fi
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

if [[ $TRISTEREO = 'TRUE'  ]]; then
if [[ -f $IMG3 ]]; then
    echo "$IMG3 exists."
else
    gdalbuildvrt $DIR3"/vrt.tif" $DIR3"/"*"R"*"C"*".TIF"
    gdal_translate -co TILED=YES -co BLOCKXSIZE=256 -co BLOCKYSIZE=256 -co BIGTIFF=IF_SAFER $DIR3"/vrt.tif" $IMG3
fi
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

if [[ $TRISTEREO = 'TRUE'  ]]; then
bundle_adjust  $IMG1 $IMG2 $IMG3 $Lrpc $Rrpc $Mrpc -t $SESSION_TYPE --datum wgs84 -o ba/run --ip-detect-method 0 --ip-per-tile 50 --ip-inlier-factor 0.4 --num-passes 2 --robust-threshold 0.5 --parameter-tolerance 1e-10 --max-iterations 500 --camera-weight 0 --tri-weight 0.1
else
bundle_adjust  $IMG1 $IMG2 $Lrpc $Rrpc -t $SESSION_TYPE --datum wgs84 -o ba/run --ip-detect-method 0 --ip-per-tile 50 --ip-inlier-factor 0.4 --num-passes 2 --robust-threshold 0.5 --parameter-tolerance 1e-10 --max-iterations 500 --camera-weight 0 --tri-weight 0.1
fi

# ###############
# # Map Project #
# ###############

if [[ $TRISTEREO = 'TRUE'  ]]; then
if [[ ! -f "ba/run-image1__image2.match" ]]; then
mapproject -t $SESSION_TYPE --t_srs EPSG:$UTM --tr $RESMP $DEM $IMG3 $Mrpc $IMG3_MP --nodata-value 0
else
mapproject -t $SESSION_TYPE --t_srs EPSG:$UTM --tr $RESMP $DEM $IMG3 $Mrpc $IMG3_MP --bundle-adjust-prefix ba/run --nodata-value 0
fi
gdalwarp -wm 512 -q -co COMPRESS=DEFLATE -overwrite -of GTiff -ot UInt16 -r cubic $IMG3_MP $ORTHO3 
fi

if [[ ! -f "ba/run-image1__image2.match" ]]; then
mapproject -t $SESSION_TYPE --t_srs EPSG:$UTM --tr $RESMP $DEM $IMG1 $Lrpc $IMG1_MP --nodata-value 0
mapproject -t $SESSION_TYPE --t_srs EPSG:$UTM --tr $RESMP $DEM $IMG2 $Rrpc $IMG2_MP --nodata-value 0
else
mapproject -t $SESSION_TYPE --t_srs EPSG:$UTM --tr $RESMP $DEM $IMG1 $Lrpc $IMG1_MP --bundle-adjust-prefix ba/run --nodata-value 0
mapproject -t $SESSION_TYPE --t_srs EPSG:$UTM --tr $RESMP $DEM $IMG2 $Rrpc $IMG2_MP --bundle-adjust-prefix ba/run --nodata-value 0
fi
fi

# convert in Int16 format & COMPRESS
gdalwarp -wm 512 -q -co COMPRESS=DEFLATE -overwrite -of GTiff -ot UInt16 -r cubic $IMG1_MP $ORTHO1 
gdalwarp -wm 512 -q -co COMPRESS=DEFLATE -overwrite -of GTiff -ot UInt16 -r cubic $IMG2_MP $ORTHO2 

##############
# RUN STEREO #
##############


cd $OUTPUT_DIR

if [[ $TRISTEREO = 'TRUE'  ]]; then

if [[ ! -f "demPleiades-filt/dem-PC.tif" ]]; then
if [[ ! -f "ba/run-image1__image2.match" ]]; then
parallel_stereo -t $SESSION_TYPE --alignment-method $A_M $IMG1_MP $IMG2_MP $IMG3_MP $Lrpc $Rrpc $Mrpc demPleiades-filt/dem $DEM_UTM_FILE --nodata-value $NO_DATA_S --prefilter-mode $PREF_MODE --prefilter-kernel-width $PREF_KER_M --corr-kernel $CORR_KERNEL --cost-mode $COST_MODE --stereo-algorithm $ST_ALG --corr-tile-size $CORR_T_S --subpixel-mode $SUBP_MODE --subpixel-kernel $SUBP_KERNEL --corr-seed-mode $CORR_S_MODE --processes $THREADS --xcorr-threshold $XCORR_TH --min-xcorr-level $MIN_XCORR_LVL --sgm-collar-size $SGM_C_SIZE --rm-quantile-percentile $RM_QUANT_PC --rm-quantile-multiple $RM_QUANT_MULT --rm-cleanup-passes $RM_CLEAN_PASS --filter-mode $FILTER_MODE --rm-half-kernel $RM_HALF_KERN --median-filter-size $MED_FILTER_SIZE --texture-smooth-size $TEXT_SMOOTH_SIZE --texture-smooth-scale $TEXT_SMOOTH_SCALE 
else 
parallel_stereo -t $SESSION_TYPE --alignment-method $A_M $IMG1_MP $IMG2_MP $IMG3_MP  $Lrpc $Rrpc $Mrpc demPleiades-filt/dem $DEM_UTM_FILE  --bundle-adjust-prefix ba/run --nodata-value $NO_DATA_S --prefilter-mode $PREF_MODE --prefilter-kernel-width $PREF_KER_M --corr-kernel $CORR_KERNEL --cost-mode $COST_MODE --stereo-algorithm $ST_ALG --corr-tile-size $CORR_T_S --subpixel-mode $SUBP_MODE --subpixel-kernel $SUBP_KERNEL --corr-seed-mode $CORR_S_MODE --processes $THREADS --xcorr-threshold $XCORR_TH --min-xcorr-level $MIN_XCORR_LVL --sgm-collar-size $SGM_C_SIZE --rm-quantile-percentile $RM_QUANT_PC --rm-quantile-multiple $RM_QUANT_MULT --rm-cleanup-passes $RM_CLEAN_PASS --filter-mode $FILTER_MODE --rm-half-kernel $RM_HALF_KERN --median-filter-size $MED_FILTER_SIZE --texture-smooth-size $TEXT_SMOOTH_SIZE--texture-smooth-scale $TEXT_SMOOTH_SCALE
fi 
fi

cd $OUTPUT_DIR
if [[ ! -f "demPleiades/dem-PC.tif" ]]; then
if [[ ! -f "ba/run-image1__image2.match" ]]; then
parallel_stereo -t $SESSION_TYPE --alignment-method $A_M $IMG1_MP $IMG2_MP $IMG3_MP  $Lrpc $Rrpc $Mrpc demPleiades/dem $DEM_UTM_FILE --nodata-value $NO_DATA_S --corr-kernel $CORR_KERNEL --cost-mode $COST_MODE --stereo-algorithm $ST_ALG --corr-tile-size $CORR_T_S --subpixel-mode $SUBP_MODE --subpixel-kernel $SUBP_KERNEL --corr-seed-mode $CORR_S_MODE --processes $THREADS --xcorr-threshold $XCORR_TH --min-xcorr-level $MIN_XCORR_LVL --sgm-collar-size $SGM_C_SIZE --prefilter-mode $PREF_MODE --prefilter-kernel-width $PREF_KER_M
else
parallel_stereo -t $SESSION_TYPE --alignment-method $A_M $IMG1_MP $IMG2_MP  $IMG3_MP  $Lrpc $Rrpc $Mrpc  demPleiades/dem $DEM_UTM_FILE --bundle-adjust-prefix ba/run --nodata-value $NO_DATA_S --corr-kernel $CORR_KERNEL --cost-mode $COST_MODE --stereo-algorithm $ST_ALG --corr-tile-size $CORR_T_S --subpixel-mode $SUBP_MODE --subpixel-kernel $SUBP_KERNEL --corr-seed-mode $CORR_S_MODE --processes $THREADS --xcorr-threshold $XCORR_TH --min-xcorr-level $MIN_XCORR_LVL --sgm-collar-size $SGM_C_SIZE --prefilter-mode $PREF_MODE --prefilter-kernel-width $PREF_KER_M
fi
fi

else

if [[ ! -f "demPleiades-filt/dem-PC.tif" ]]; then
if [[ ! -f "ba/run-image1__image2.match" ]]; then
parallel_stereo -t $SESSION_TYPE --alignment-method $A_M $IMG1_MP $IMG2_MP $Lrpc $Rrpc demPleiades-filt/dem $DEM_UTM_FILE --nodata-value $NO_DATA_S --prefilter-mode $PREF_MODE --prefilter-kernel-width $PREF_KER_M --corr-kernel $CORR_KERNEL --cost-mode $COST_MODE --stereo-algorithm $ST_ALG --corr-tile-size $CORR_T_S --subpixel-mode $SUBP_MODE --subpixel-kernel $SUBP_KERNEL --corr-seed-mode $CORR_S_MODE --processes $THREADS --xcorr-threshold $XCORR_TH --min-xcorr-level $MIN_XCORR_LVL --sgm-collar-size $SGM_C_SIZE --rm-quantile-percentile $RM_QUANT_PC --rm-quantile-multiple $RM_QUANT_MULT --rm-cleanup-passes $RM_CLEAN_PASS --filter-mode $FILTER_MODE --rm-half-kernel $RM_HALF_KERN --median-filter-size $MED_FILTER_SIZE --texture-smooth-size $TEXT_SMOOTH_SIZE --texture-smooth-scale $TEXT_SMOOTH_SCALE
else
parallel_stereo -t $SESSION_TYPE --alignment-method $A_M $IMG1_MP $IMG2_MP $Lrpc $Rrpc demPleiades-filt/dem $DEM_UTM_FILE  --bundle-adjust-prefix ba/run --nodata-value $NO_DATA_S --prefilter-mode $PREF_MODE --prefilter-kernel-width $PREF_KER_M --corr-kernel $CORR_KERNEL --cost-mode $COST_MODE --stereo-algorithm $ST_ALG --corr-tile-size $CORR_T_S --subpixel-mode $SUBP_MODE --subpixel-kernel $SUBP_KERNEL --corr-seed-mode $CORR_S_MODE --processes $THREADS --xcorr-threshold $XCORR_TH --min-xcorr-level $MIN_XCORR_LVL --sgm-collar-size $SGM_C_SIZE --rm-quantile-percentile $RM_QUANT_PC --rm-quantile-multiple $RM_QUANT_MULT --rm-cleanup-passes $RM_CLEAN_PASS --filter-mode $FILTER_MODE --rm-half-kernel $RM_HALF_KERN --median-filter-size $MED_FILTER_SIZE --texture-smooth-size $TEXT_SMOOTH_SIZE --texture-smooth-scale $TEXT_SMOOTH_SCALE
fi
fi

cd $OUTPUT_DIR

if [[ ! -f "demPleiades/dem-PC.tif" ]]; then
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
if [[ ! -f "demPleiades/dem-DEM.tif" ]]; then
cd $OUTPUT_DIR/demPleiades
point2dem --t_srs EPSG:$UTM --tr $RES dem-PC.tif --median-filter-params $MED_F_PAR --dem-hole-fill-len $DEM_HOLE_F_L --erode-length $ERODE_L --nodata-value $NO_DATA_DEM --tif-compress $TIF_COMPR --max-valid-triangulation-error $MAX_V_TRIANG_ERR --remove-outliers-param $RM_OUTL_PARA --threads $THREADS
# convert in Int16 format & COMPRESS
gdalwarp -wm 512 -q -co COMPRESS=DEFLATE -overwrite -of GTiff -ot UInt16 -r cubic dem-DEM.tif ../dsm_denoised.tiff
# create hillshade
gdaldem hillshade ../dsm_denoised.tiff ../hillshade_denoised.tiff  -of GTiff -b 1 -z 1.0 -s 1.0 -az 315.0 -alt 45.0 
fi

if [[ ! -f "demPleiades-filt/dem-DEM.tif" ]]; then
cd $OUTPUT_DIR/demPleiades-filt
point2dem --t_srs EPSG:$UTM --tr $RES dem-PC.tif --median-filter-params $MED_F_PAR --dem-hole-fill-len $DEM_HOLE_F_L --erode-length $ERODE_L --nodata-value $NO_DATA_DEM --tif-compress $TIF_COMPR --max-valid-triangulation-error $MAX_V_TRIANG_ERR --remove-outliers-param $RM_OUTL_PARA --threads $THREADS
# convert in Int16 format & COMPRESS
gdalwarp -wm 512 -q -co COMPRESS=DEFLATE -overwrite -of GTiff -ot UInt16 -r cubic dem-DEM.tif ../dsm_denoised_filtered.tiff
# create hillshade
gdaldem hillshade ../dsm_denoised_filtered.tiff ../hillshade_denoised_filtered.tiff  -of GTiff -b 1 -z 1.0 -s 1.0 -az 315.0 -alt 45.0 
fi

# exit pair
cd $ROOT

# exit loop
done

exit

