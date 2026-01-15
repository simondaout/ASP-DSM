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

TRISTEREO=FALSE
# check if stereo or tri-stereo
cols=`awk '{print NF}' $PAIRS | tail -n 1`
if [[ $cols -eq 6 ]]; then
TRISTEREO=TRUE
elif [[ $cols -eq 4 ]]; then
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

if [[ -d $DATA_DIR"/"$NAME1"/IMG_PHR1A_MS_002/" ]]
then
	# set input images
	DIR1=$DATA_DIR"/"$NAME1"/IMG_PHR1A_MS_002"
    if [[ $SESSION_TYPE = 'rpc' ]]; then
    Lrpc=$DIR1"/RPC_PHR1A_MS_"$DATE1"_SEN_"$NAME1"-2.XML"
    elif [[ $SESSION_TYPE = 'pleiades' ]]; then
    Lrpc=$DIR1"/DIM_PHR1A_MS_"$DATE1"_SEN_"$NAME1"-2.XML"
    else
    echo "Unknown session type, choose rpc or pleiades"
    echo ; exit
    fi
else
	# set input images
	DIR1=$DATA_DIR"/"$NAME1"/IMG_PHR1B_MS_002"
    if [[ $SESSION_TYPE = 'rpc' ]]; then
    Lrpc=$DIR1"/RPC_PHR1B_MS_"$DATE1"_SEN_"$NAME1"-2.XML"
    elif [[ $SESSION_TYPE = 'pleiades' ]]; then
    Lrpc=$DIR1"/DIM_PHR1B_MS_"$DATE1"_SEN_"$NAME1"-2.XML"
    else
    echo "Unknown session type, choose rpc or pleiades"
    echo ; exit
    fi
fi
IMG1=$DIR1"/MS_"$DATE1".tif"
IMG1_MP=$DIR1"/mapproj_MS_$DATE1.tif"
ORTHO1=$OUTPUT_DIR"/orthoimage_forward_MS_$DATE1.tif"

if [[ -d $DATA_DIR"/"$NAME2"/IMG_PHR1A_MS_002/" ]]
then
	# set input images
	DIR2=$DATA_DIR"/"$NAME2"/IMG_PHR1A_MS_002"
    if [[ $SESSION_TYPE = 'rpc' ]]; then
    Rrpc=$DIR2"/RPC_PHR1A_MS_"$DATE2"_SEN_"$NAME2"-2.XML"
    elif [[ $SESSION_TYPE = 'pleiades' ]]; then
    Rrpc=$DIR2"/DIM_PHR1A_MS_"$DATE2"_SEN_"$NAME2"-2.XML"
    else
    echo "Unknown session type, choose rpc or pleiades"
    echo ; exit
    fi
else
	# set input images
	DIR2=$DATA_DIR"/"$NAME2"/IMG_PHR1B_MS_002"
    if [[ $SESSION_TYPE = 'rpc' ]]; then
    Rrpc=$DIR2"/RPC_PHR1B_MS_"$DATE2"_SEN_"$NAME2"-2.XML"
    elif [[ $SESSION_TYPE = 'pleiades' ]]; then
    Rrpc=$DIR2"/DIM_PHR1B_MS_"$DATE2"_SEN_"$NAME2"-2.XML"
    else
    echo "Unknown session type, choose rpc or pleiades"
    echo ; exit
    fi
fi
IMG2=$DIR2"/MS_$DATE2.tif"
IMG2_MP=$DIR2"/MS_mapproj_$DATE2.tif"
ORTHO2=$OUTPUT_DIR"/orthoimage_MS_backward_$DATE2.tif"

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
IMG3=$DIR3"/MS_$DATE3.tif"
IMG3_MP=$DIR3"/MS_mapproj_$DATE3.tif"
ORTHO3=$OUTPUT_DIR"/orthoimage_MS_nadir_$DATE3.tif"

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
	if compgen -G "$DIR1/*R*C*.JP2" > /dev/null; then
	gdalbuildvrt $DIR1"/vrt.tif" $DIR1"/"*"R"*"C"*".JP2"
    gdalbuildvrt $DIR2"/vrt.tif" $DIR2"/"*"R"*"C"*".JP2"
	else
	gdalbuildvrt $DIR1"/vrt.tif" $DIR1"/"*"R"*"C"*".TIF"
    gdalbuildvrt $DIR2"/vrt.tif" $DIR2"/"*"R"*"C"*".TIF"
    fi
	gdal_translate -co TILED=YES -co BLOCKXSIZE=256 -co BLOCKYSIZE=256 -co BIGTIFF=IF_SAFER $DIR1"/vrt.tif" $IMG1
	gdal_translate -co TILED=YES -co BLOCKXSIZE=256 -co BLOCKYSIZE=256 -co BIGTIFF=IF_SAFER $DIR2"/vrt.tif" $IMG2
fi

if [[ $TRISTEREO = 'TRUE'  ]]; then
if [[ -f $IMG3 ]]; then
    echo "$IMG3 exists."
else
	if compgen -G "$DIR3/*R*C*.JP2" > /dev/null; then
    gdalbuildvrt $DIR3"/vrt.tif" $DIR3"/"*"R"*"C"*".JP2"
    else
    gdalbuildvrt $DIR3"/vrt.tif" $DIR3"/"*"R"*"C"*".TIF"
    fi
    gdal_translate -co TILED=YES -co BLOCKXSIZE=256 -co BLOCKYSIZE=256 -co BIGTIFF=IF_SAFER $DIR3"/vrt.tif" $IMG3
    gdalbuildvrt $DIR3"/vrt.tif" $DIR3"/"*"R"*"C"*".JPG"
fi
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

if [[ $TRISTEREO = 'TRUE'  ]]; then
mapproject -t $SESSION_TYPE --t_srs EPSG:$UTM --tr $RESMP $DEM $IMG3 $Mrpc $IMG3_MP --nodata-value 0
gdalwarp -wm 512 -q -co COMPRESS=DEFLATE -overwrite -of GTiff -ot UInt16 -r cubic $IMG3_MP $ORTHO3
fi

# exit pair
cd $ROOT

# exit loop
done

exit

