#. ./asp_parameters

# Map Project: orthorectify a camera image onto a DEM or datum
# For stereo, all mapprojected images should have the same grid size and projection

# mapproject <opts> <dem> <camera-image> <camera-model> <output-image>
# -t stereo session type
# --t-srs output projection as GDAL projection string
# --tr output file resolution (ground sample distance) in target georeferenced units per pixel
# --nodata-value nodata value to use
# --bundle-adjust-prefix camera adjustement from bundle-adjust

# gdalwarp <opts> <src_dataset_name> <dst_dataset_name>
# -wm amount of memory allowed for caching (MB), can be specified also as %
# -q be quiet
# -overwrite overwrite target if already exists
# -of output format
# -ot output image band data type
# -r resampling method

if [[ ! -f $IMG2_MP ]]; then

if [[ $TRISTEREO = 'TRUE'  ]]; then
if [[ ! -f "ba/run-image1__image2.match" ]]; then
mapproject -t $SESSION_TYPE --t_srs EPSG:$UTM --tr $RESMP $DEM $IMG3 $Mrpc $IMG3_MP --nodata-value 0
else
mapproject -t $SESSION_TYPE --t_srs EPSG:$UTM --tr $RESMP $DEM $IMG3 $Mrpc $IMG3_MP --bundle-adjust-prefix ba/run --nodata-value 0
fi
gdalwarp -wm 512 -q -co COMPRESS=DEFLATE -overwrite -of GTiff -ot Float32 -r cubic $IMG3_MP $ORTHO3 
fi

if [[ ! -f "ba/run-image1__image2.match" ]]; then
mapproject -t $SESSION_TYPE --t_srs EPSG:$UTM --tr $RESMP $DEM $IMG1 $Lrpc $IMG1_MP --nodata-value 0
mapproject -t $SESSION_TYPE --t_srs EPSG:$UTM --tr $RESMP $DEM $IMG2 $Rrpc $IMG2_MP --nodata-value 0
else
mapproject -t $SESSION_TYPE --t_srs EPSG:$UTM --tr $RESMP $DEM $IMG1 $Lrpc $IMG1_MP --bundle-adjust-prefix ba/run --nodata-value 0
mapproject -t $SESSION_TYPE --t_srs EPSG:$UTM --tr $RESMP $DEM $IMG2 $Rrpc $IMG2_MP --bundle-adjust-prefix ba/run --nodata-value 0
fi
fi

# convert in Float32 format & COMPRESS
gdalwarp -wm 512 -q -co COMPRESS=DEFLATE -overwrite -of GTiff -ot Float32 -r cubic $IMG1_MP $ORTHO1 
gdalwarp -wm 512 -q -co COMPRESS=DEFLATE -overwrite -of GTiff -ot Float32 -r cubic $IMG2_MP $ORTHO2 
