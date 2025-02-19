#. ./asp_parameters

# Generate the orbit files for visualization in Google Earth (KML)

# orbitviz <opts> <images and cameras>
# -t input camera model type (same as session-type)
# -o output file (default orbit.kml)
# --bundle-adjust-prefix use camera adjustement from bundle_adjust

if [[ $TRISTEREO = 'TRUE'  ]]; then
orbitviz -t $SESSION_TYPE $IMG1 $IMG2 $IMG3 $Lrpc $Rrpc $Mrpc  -o orbitviz_sat_pos_adjusted.kml --bundle-adjust-prefix ba/run
else
orbitviz -t $SESSION_TYPE $IMG1 $IMG2 $Lrpc $Rrpc -o orbitviz_sat_pos_adjusted.kml --bundle-adjust-prefix ba/run
fi