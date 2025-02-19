#. ./asp_parameters.txt

echo "> Referencing DEM"

# Reference the initial DEM
# gdalwarp <opts> <src_dataset_name> <dst_dataset_name>
# -te <xres> <yres> output file resolution
# -t_srs <srs_def> target spatial reference
# -r <resampling_method>
# -overwrite overwrite the target if already exists
gdalwarp -tr $GDAL_OUT_RES -t_srs EPSG:$UTM $DEM $DEM_UTM_FILE -r $RESAMP_M -overwrite