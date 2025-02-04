#. ./asp_parameters.txt

# Bundle adjust images
# Correct errors in camera position and orientation

# bundle_adjust <images> <cameras> -o <output prefix> <opts>
# -t
# --datum datum override
# --ip-detect-method interest point detection method
# --ip-per-tile nb interest point in each 1024^2 image tile
# --ip-inlier-factor higher factor will result in more interest points, but perhaps also more outliers
# --num-passes nb of bundle adjustement to iterate
# --robust-threshold threshold for the robust reprojection error cost function
# --parameter-tolerance stop when the relative error in the variables being optimized is less than this
# --max-iterations ?
# --camera-weight /!\ DEPRECATED The weight to give to the constraint that the camera positions/orientations stay close to the original values
# --tri-weight The weight to give to the constraint that optimized triangulated points stay close to original triangulated points

if [[ $TRISTEREO = 'TRUE'  ]]; then
bundle_adjust  $IMG1 $IMG2 $IMG3 $Lrpc $Rrpc $Mrpc -t $SESSION_TYPE --datum wgs84 -o ba/run --ip-detect-method 0 --ip-per-tile 50 --ip-inlier-factor 0.4 --num-passes 2  --robust-threshold 0.5 --parameter-tolerance 1e-10 --max-iterations 500 --camera-weight 0 --tri-weight 0.1
else
bundle_adjust  $IMG1 $IMG2 $Lrpc $Rrpc -t $SESSION_TYPE --datum wgs84 -o ba/run --ip-detect-method 0 --ip-per-tile 50 --ip-inlier-factor 0.4 --num-passes 2 --robust-threshold 0.5 --parameter-tolerance 1e-10 --max-iterations 500 --camera-weight 0 --tri-weight 0.1
fi
