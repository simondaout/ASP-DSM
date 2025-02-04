#. ./asp_parameters

# Run the stereo reconstruction
# Step 0 Preprocessing: locate and match interest points
# Step 1 Stereo Correlation
# Step 2 Blend
# Step 3 Sub-pixel refinement
# Step 4 Outlier Rejection
# Step 5 Triangulation

# parallel_stereo <opts> <images> <cameras> <output_file_prefix>
# -t
# --alignement-method
# --bundle-adjust-prefix
# --median-filter-size
# --texture-smooth-size
# --texture-smooth-scale


if [[ $TRISTEREO = 'TRUE'  ]]; then

    if [[ ! -f "demPleiades-filt/dem-PC.tif" ]]; then
        if [[ ! -f "ba/run-image1__image2.match" ]]; then
            parallel_stereo -t $SESSION_TYPE --alignment-method $A_M $IMG1_MP $IMG2_MP $IMG3_MP $Lrpc $Rrpc $Mrpc demPleiades-filt/dem  $session $stereo $denoising $filtering 
            else 
            parallel_stereo -t $SESSION_TYPE --alignment-method $A_M $IMG1_MP $IMG2_MP $IMG3_MP $Lrpc $Rrpc $Mrpc demPleiades-filt/dem  $session $stereo $denoising $filtering --bundle-adjust-prefix ba/run
        fi 
    fi
    
    if [[ ! -f "demPleiades/dem-PC.tif" ]]; then
        if [[ ! -f "ba/run-image1__image2.match" ]]; then
            parallel_stereo -t $SESSION_TYPE --alignment-method $A_M $IMG1_MP $IMG2_MP $IMG3_MP $Lrpc $Rrpc $Mrpc demPleiades/dem $session $stereo $denoising --median-filter-size 0  --texture-smooth-size 0 --texture-smooth-scale 0.13 
            else
            parallel_stereo -t $SESSION_TYPE --alignment-method $A_M $IMG1_MP $IMG2_MP  $IMG3_MP $Lrpc $Rrpc $Mrpc demPleiades/dem  $session $stereo $denoising --bundle-adjust-prefix ba/run --median-filter-size 0  --texture-smooth-size 0 --texture-smooth-scale 0.13
        fi
    fi

    else

    if [[ ! -f "demPleiades-filt/dem-PC.tif" ]]; then
        if [[ ! -f "ba/run-image1__image2.match" ]]; then
            parallel_stereo -t $SESSION_TYPE --alignment-method $A_M $IMG1_MP $IMG2_MP $Lrpc $Rrpc demPleiades-filt/dem $session $stereo $denoising $filtering 
            else
            parallel_stereo -t $SESSION_TYPE --alignment-method $A_M $IMG1_MP $IMG2_MP $Lrpc $Rrpc demPleiades-filt/dem $session $stereo $denoising $filtering --bundle-adjust-prefix ba/run
        fi
    fi

    if [[ ! -f "demPleiades/dem-PC.tif" ]]; then
        if [[ ! -f "ba/run-image1__image2.match" ]]; then
            parallel_stereo -t $SESSION_TYPE --alignment-method $A_M  $IMG1_MP $IMG2_MP $Lrpc $Rrpc demPleiades/dem  $session $stereo $denoising --median-filter-size 0  --texture-smooth-size 0 --texture-smooth-scale 0.13
            else
            parallel_stereo -t $SESSION_TYPE --alignment-method $A_M $IMG1_MP $IMG2_MP $Lrpc $Rrpc  demPleiades/dem $session $stereo $denoising  --bundle-adjust-prefix ba/run --median-filter-size 0  --texture-smooth-size 0 --texture-smooth-scale 0.13
        fi
    fi

fi