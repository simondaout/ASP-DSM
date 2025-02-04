#. ./asp_parameters.txt

# Transform the point cloud resulting from stereo to raster DEM

# point2dem

# gdalwarp <opts> <src_dataset_name> <dst_dataset_name>
# -wm amount of memory allowed for caching (MB), can be specified also as %
# -q be quiet
# -overwrite overwrite target if already exists
# -of output format
# -ot output image band data type
# -r resampling method

# the dem-PC file is stored in demPleiades; the final dem-DEM.tif will be created within demPleiades
if [[ ! -f "demPleiades/dem-DEM.tif" ]]; then
cd $OUTPUT_DIR/demPleiades
point2dem --t_srs EPSG:$UTM --tr $RES dem-PC.tif --dem-hole-fill-len $DEM_HOLE_F_L --erode-length $ERODE_L --nodata-value $NO_DATA_DEM --tif-compress $TIF_COMPR --max-valid-triangulation-error $MAX_V_TRIANG_ERR  
# convert in Float32 format & COMPRESS
gdalwarp -wm 512 -q -co COMPRESS=DEFLATE -overwrite -of GTiff -ot Float32 -r cubic dem-DEM.tif ../dsm_denoised.tiff
# create hillshade
#gdaldem hillshade ../dsm_denoised.tiff ../hillshade_denoised.tiff  -of GTiff -b 1 -z 1.0 -s 1.0 -az 315.0 -alt 45.0 
fi

cd $OUTPUT_DIR

if [[ ! -f "demPleiades-filt/dem-DEM.tif" ]]; then
cd $OUTPUT_DIR/demPleiades-filt
point2dem --t_srs EPSG:$UTM --tr $RES dem-PC.tif --median-filter-params $MED_F_PAR --dem-hole-fill-len $DEM_HOLE_F_L --erode-length $ERODE_L --nodata-value $NO_DATA_DEM --tif-compress $TIF_COMPR --max-valid-triangulation-error $MAX_V_TRIANG_ERR --remove-outliers-param $RM_OUTL_PARA --remove-outliers  
# convert in Float32 format & COMPRESS
gdalwarp -wm 512 -q -co COMPRESS=DEFLATE -overwrite -of GTiff -ot Float32 -r cubic dem-DEM.tif ../dsm_denoised_filtered.tiff
# create hillshade
#gdaldem hillshade ../dsm_denoised_filtered.tiff ../hillshade_denoised_filtered.tiff  -of GTiff -b 1 -z 1.0 -s 1.0 -az 315.0 -alt 45.0 
fi