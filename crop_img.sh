CROP1=245000 # x up left
CROP2=3147000 #y up left
CROP3=249000 # x low right
CROP4=3141000 #y low right


gdal_translate -proj_srs EPSG:32645 -projwin $CROP1 $CROP2 $CROP3 $CROP4  -of GTiff mapproj_backward_202501190507419.tif mapproj_backward_crop.tif
gdal_translate -proj_srs EPSG:32645 -projwin $CROP1 $CROP2 $CROP3 $CROP4  -of GTiff mapproj_forward_202501190507160.tif mapproj_forward_crop.tif
gdal_translate -proj_srs EPSG:32645 -projwin $CROP1 $CROP2 $CROP3 $CROP4  -of GTiff mapproj_nadir_202501190507505.tif mapproj_nadir_crop.tif