#!/usr/bin/bash

# help
Help()
{
   # Display Help
   echo "Syntax: launch_MS.sh -n pair_list [-h|v|f]"
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

if [[ -d $DATA_DIR"/"$NAME1"/IMG_PHR1A_MS_002/" ]]
then
	# set input images
	DIR1=$DATA_DIR"/"$NAME1"/IMG_PHR1A_MS_002"
	Lrpc=$DIR1"/DIM_PHR1A_MS_"$DATE1"_SEN_"$NAME1"-2.XML"
else
	# set input images
	DIR1=$DATA_DIR"/"$NAME1"/IMG_PHR1B_MS_002"
	Lrpc=$DIR1"/DIM_PHR1B_MS_"$DATE1"_SEN_"$NAME1"-2.XML"
fi
IMG1=$DIR1"/image1_MS.tif"
IMG1_MP=$OUTPUT_DIR"/img1_MS_mapproj.tif"
ORTHO1=$OUTPUT_DIR"/orthoimage_MS_$DATE1.tif"

if [[ -d $DATA_DIR"/"$NAME2"/IMG_PHR1A_MS_002/" ]]
then
	# set input images
	DIR2=$DATA_DIR"/"$NAME2"/IMG_PHR1A_MS_002"
	Rrpc=$DIR2"/DIM_PHR1A_MS_"$DATE2"_SEN_"$NAME2"-2.XML"
else
	# set input images
	DIR2=$DATA_DIR"/"$NAME2"/IMG_PHR1B_MS_002"
	Rrpc=$DIR2"/DIM_PHR1B_MS_"$DATE2"_SEN_"$NAME2"-2.XML"
fi
IMG2=$DIR2"/image2_MS.tif"
IMG2_MP=$OUTPUT_DIR"/img2_MS_mapproj.tif"
ORTHO2=$OUTPUT_DIR"/orthoimage_MS_$DATE2.tif"

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

if [[ ! -d $OUTPUT_DIR  ]]; then
mkdir $OUTPUT_DIR
fi

# copy parameter file to new working dir
cp asp_parameters.txt $OUTPUT_DIR"/."
# change to working dir; TIMESTAMP bc this is the name of the current working dir
cd $OUTPUT_DIR

# ###############
# # Map Project #
# ###############

mapproject -t $SESSION_TYPE --t_srs EPSG:$UTM --tr $RESMP $DEM $IMG1 $Lrpc $IMG1_MP --nodata-value 0
mapproject -t $SESSION_TYPE --t_srs EPSG:$UTM --tr $RESMP $DEM $IMG2 $Rrpc $IMG2_MP --nodata-value 0

# convert in Int16 format & COMPRESS
gdalwarp -wm 512 -q -co COMPRESS=DEFLATE -overwrite -of GTiff -ot UInt16 -r cubic $IMG1_MP $ORTHO1 
gdalwarp -wm 512 -q -co COMPRESS=DEFLATE -overwrite -of GTiff -ot UInt16 -r cubic $IMG2_MP $ORTHO2 

# exit pair
cd $ROOT

# exit loop
done

exit

