#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""
dem_nan_ratio.py
-------------
Calculates the ratio between NaN to all pixel of the image and plots the images.

Usage: dem_nan_ratio.py --data=<path> [--p]
dem_nan_ratio.py -h | --help

Options:
-h | --help         Show this screen
--data              Input file
--p                 Plot the result

"""
##########
# IMPORT #
##########

import os, sys
import numpy as np
from osgeo import gdal
from matplotlib import pyplot as plt
import docopt

#############
# FUNCTIONS #
#############

def read_from_file(input_file):
    ds = gdal.OpenEx(input_file, allowed_drivers=['GTiff'])
    ds_band = ds.GetRasterBand(1)
    values = ds_band.ReadAsArray(0, 0, ds.RasterXSize, ds.RasterYSize)
    ncol, nrow = ds.RasterXSize, ds.RasterYSize
    nodata = ds_band.GetNoDataValue()
    
    return (values, ncol, nrow, nodata)

def convert_to_binary(dem, nodata):
    out = np.zeros_like(dem)
    
    out[dem <= nodata] = 0
    out[dem > nodata] = 1
    
    return out

def plot_binary(dem_binary):
    plt.imshow(dem_binary)
    
    plt.title('Binary Mask')

    plt.show()

def calculate_nan_ratio(input_file, plot):
    
    dem_data = read_from_file(input_file)
    dem, ncol, nrow, nodata = dem_data[0], dem_data[1], dem_data[2], dem_data[3]
    dem_binary = convert_to_binary(dem, nodata)

    # count 0 and 1 values
    unique, counts = np.unique(dem_binary, return_counts=True)
    count_results = dict(zip(unique, counts))
    print('Number of NaN pixel: {}'.format(count_results[0]))
    print('Total number of pixel: {}'.format(dem_binary.size))
    print('Ratio NaN to DEM pixel: {}'.format(count_results[0]/dem_binary.size))
    
    if(plot):
        plot_binary(dem_binary)


########
# MAIN #
########

arguments = docopt.docopt(__doc__)

input_file = arguments['--data']

plot = arguments['--p']



calculate_nan_ratio(input_file, plot)

