. ./params.txt

session="--nodata-value $NO_DATA_S $DEM_UTM_FILE  --threads-multiprocess $THREADS" 
stereo="--prefilter-mode $PREF_MODE --prefilter-kernel-width $PREF_KER_M --corr-kernel $CORR_KERNEL --cost-mode $COST_MODE --stereo-algorithm $ST_ALG --corr-tile-size $CORR_T_S --subpixel-mode $SUBP_MODE --subpixel-kernel $SUBP_KERNEL --corr-seed-mode $CORR_S_MODE --xcorr-threshold $XCORR_TH --min-xcorr-level $MIN_XCORR_LVL --sgm-collar-size $SGM_C_SIZE" 
denoising="--rm-quantile-percentile $RM_QUANT_PC --rm-quantile-multiple $RM_QUANT_MULT --filter-mode $FILTER_MODE --rm-half-kernel $RM_HALF_KERN --rm-min-matches $RM_MIN_MATCHES --rm-threshold $RM_THRESHOLD --max-mean-diff $MAX_DIFF" 
#filtering="--median-filter-size $MED_FILTER_SIZE --texture-smooth-size $TEXT_SMOOTH_SIZE --texture-smooth-scale $TEXT_SMOOTH_SCALE" 
filtering=--median-filter-size 0  --texture-smooth-size 0 --texture-smooth-scale 0.13

parallel_stereo -t $SESSION_TYPE --alignment-method $A_M $IMG1_MP $IMG2_MP $IMG3_MP $Lrpc $Rrpc $Mrpc demPleiadesTest/dem  $session $stereo $denoising $filtering --bundle-adjust-prefix ../ba/run

cd ./demPleiadesTest/

point2dem --t_srs EPSG:32645 --tr 2 dem-PC.tif --dem-hole-fill-len 200 --erode_length 0 --nodata-value 0 --tif_compress "Deflate" --max-valid-triangulation-error 4.
gdalwarp -wm 512 -q -c COMPRESS=DEFLATE -overwrite -of GTiff -ot Float32 -r cubic dem-DEM.tif ../test-dsm.tiff

cd ..

exit