#. ./asp_parameters.txt

# Set the directory names and variables before ASP DSM processing

# set output dir
OUTPUT_DIR=$ROOT/$NAME1"-"$NAME2

if [[ -d $DATA_DIR"/"$NAME1"/IMG_PHR1A_P_001/" ]]
then
    # set input images
    DIR1=$DATA_DIR"/"$NAME1"/IMG_PHR1A_P_001"
    if [[ $SESSION_TYPE = 'rpc' ]]; then
    Lrpc=$DIR1"/RPC_PHR1A_P_"$DATE1"_SEN_"$NAME1"-1.XML"
    elif [[ $SESSION_TYPE = 'pleiades' ]]; then
    Lrpc=$DIR1"/DIM_PHR1A_P_"$DATE1"_SEN_"$NAME1"-1.XML"
    else
    echo "Unknown session type, choose rpc or pleiades"
    echo ; exit	
    fi
else
    # set input images
    DIR1=$DATA_DIR"/"$NAME1"/IMG_PHR1B_P_001"
    if [[ $SESSION_TYPE = 'rpc' ]]; then
    Lrpc=$DIR1"/RPC_PHR1B_P_"$DATE1"_SEN_"$NAME1"-1.XML"
    elif [[ $SESSION_TYPE = 'pleiades' ]]; then
    Lrpc=$DIR1"/DIM_PHR1B_P_"$DATE1"_SEN_"$NAME1"-1.XML"
    else
    echo "Unknown session type, choose rpc or pleiades"
    echo ; exit
    fi	
fi
cp $Lrpc $DIR1/$DATE1.XML
IMG1=$DIR1"/forward_$DATE1.tif"
IMG1_MP=$OUTPUT_DIR"/MAPPROJ/mapproj_forward_$DATE1.tif"
ORTHO1=$OUTPUT_DIR"/orthoimage_forward_$DATE1.tif"

if [[ -d $DATA_DIR"/"$NAME2"/IMG_PHR1A_P_001/" ]]
then
    # set input images
    DIR2=$DATA_DIR"/"$NAME2"/IMG_PHR1A_P_001"
    if [[ $SESSION_TYPE = 'rpc' ]]; then
    Rrpc=$DIR2"/RPC_PHR1A_P_"$DATE2"_SEN_"$NAME2"-1.XML"
    elif [[ $SESSION_TYPE = 'pleiades' ]]; then
    Rrpc=$DIR2"/DIM_PHR1A_P_"$DATE2"_SEN_"$NAME2"-1.XML"
    else
    echo "Unknown session type, choose rpc or pleiades"
    echo ; exit
    fi	
else
    # set input images
    DIR2=$DATA_DIR"/"$NAME2"/IMG_PHR1B_P_001"
    if [[ $SESSION_TYPE = 'rpc' ]]; then
    Rrpc=$DIR2"/RPC_PHR1B_P_"$DATE2"_SEN_"$NAME2"-1.XML"
    elif [[ $SESSION_TYPE = 'pleiades' ]]; then
    Rrpc=$DIR2"/DIM_PHR1B_P_"$DATE2"_SEN_"$NAME2"-1.XML"
    else
    echo "Unknown session type, choose rpc or pleiades"
    echo ; exit
    fi	
fi
cp $Rrpc $DIR2/$DATE2.XML
IMG2=$DIR2"/backward_$DATE2.tif"
IMG2_MP=$OUTPUT_DIR"/MAPPROJ/mapproj_backward_$DATE2.tif"
ORTHO2=$OUTPUT_DIR"/orthoimage_backward_$DATE2.tif"

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
    cp $Mrpc $DIR3/$DATE3.XML
    IMG3=$DIR3"/nadir_$DATE3.tif"
    IMG3_MP=$OUTPUT_DIR"/MAPPROJ/mapproj_nadir_$DATE3.tif"
    ORTHO3=$OUTPUT_DIR"/orthoimage_nadir_$DATE3.tif"

fi