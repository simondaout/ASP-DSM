#. ./asp_parameters.txt

echo "Tiling Source Images"

# Tiled images when broken between R & C components
# Pleiades images can can in multiple parts for a single acquisition, each of them in
# format .TIF or .JP2

# gdalbuildvrt <opts> <output.vrt> <input>

# gdaltranslate <opts> <src_dataset> <dst_dataset>
# -co <NAME>=<VALUE> more options
#   BLOCKXSIZE block width
#   BLOCKYSIZE block height
#   TILED ?
#   BIGTIFF ?


if [[ -f $IMG1 ]]; then
	echo "$IMG1 exists."
else
	# These need to be mosaicked before being used
	if [[ -f $DIR1"/"*"R"*"C"*".JP2" ]]; then
	gdalbuildvrt $DIR1"/vrt.tif" $DIR1"/"*"R"*"C"*".JP2"
	else
	gdalbuildvrt $DIR1"/vrt.tif" $DIR1"/"*"R"*"C"*".TIF"
	fi 
	#actual self-contained image can be produced with:
	gdal_translate -co TILED=YES -co BLOCKXSIZE=256 -co BLOCKYSIZE=256 -co BIGTIFF=IF_SAFER $DIR1"/vrt.tif" $IMG1
fi

if [[ -f $IMG2 ]]; then
    echo "$IMG2 exists."
else
    if [[ -f $DIR2"/"*"R"*"C"*".JP2" ]]; then	
	gdalbuildvrt $DIR2"/vrt.tif" $DIR2"/"*"R"*"C"*".JP2"
	else
	gdalbuildvrt $DIR2"/vrt.tif" $DIR2"/"*"R"*"C"*".TIF"
	fi	
	gdal_translate -co TILED=YES -co BLOCKXSIZE=256 -co BLOCKYSIZE=256 -co BIGTIFF=IF_SAFER $DIR2"/vrt.tif" $IMG2
fi

if [[ $TRISTEREO = 'TRUE'  ]]; then
if [[ -f $IMG3 ]]; then
    echo "$IMG3 exists."
else
	if [[ -f $DIR3"/"*"R"*"C"*".JP2" ]]; then
    gdalbuildvrt $DIR3"/vrt.tif" $DIR3"/"*"R"*"C"*".JP2"
	else 
	gdalbuildvrt $DIR3"/vrt.tif" $DIR3"/"*"R"*"C"*".TIF" 
    fi 
	gdal_translate -co TILED=YES -co BLOCKXSIZE=256 -co BLOCKYSIZE=256 -co BIGTIFF=IF_SAFER $DIR3"/vrt.tif" $IMG3
fi
fi