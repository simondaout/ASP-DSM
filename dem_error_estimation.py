#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""
dem_error_estimation.py
-------------
Plot the DEM error as function of the slope using the difference of two DEMs and the corresponding slope

Usage: dem_error_estimation.py --diff=<path> --slope=<path> [--name=<string>] 
dem_error_estimation.py -h | --help

Options:
-h --help           Show this screen.
--diff PATH       Path to difference file
--slope PATH      Path to slope file   
--name STRING     Naming for plot title

"""
##########
# IMPORT #
##########

import os, sys
import numpy as np
from osgeo import gdal
from matplotlib import pyplot as plt
import pandas as pd
from pathlib import Path
from math import *
import docopt

#############
# FUNCTIONS #
#############

def save_to_file(diff, output_path, ncol, nrow):
    drv = gdal.GetDriverByName('GTiff')
    dst_ds = drv.Create(output_path, ncol, nrow, 1, gdal.GDT_Float32)
    dst_band = dst_ds.GetRasterBand(1)
    dst_band.SetNoDataValue(-9999)
    dst_band.WriteArray(diff)

def read_from_file(input_file):

    ds = gdal.OpenEx(input_file, allowed_drivers=['GTiff'])
    ds_band = ds.GetRasterBand(1)
    values = ds_band.ReadAsArray(0, 0, ds.RasterXSize, ds.RasterYSize)
    ncol, nrow = ds.RasterXSize, ds.RasterYSize
    
    error_val = ds_band.GetNoDataValue()
    # if there is no set no-data value, set to -9999
    if(error_val == None):
        error_val = -9999

    values_copy = np.copy(values)
    values_copy[values_copy <= error_val] = np.nan

    return values_copy

def multiplot_slope_error(slope, out_path, option, diff):

    x = slope.flatten() # slope_flat - used to plot slope histogram
    y = diff.flatten() # diff_flat - used to get mean/median error

    #TODO: define with docopt, max_slope, slope_steps 
    max_slope = np.nanpercentile(x,92)
    slope_steps = 1 + int(max_slope/10)
    print(max_slope,slope_steps)

    bins = np.arange(0, max_slope, slope_steps)
    histo_bins = np.arange(0, max_slope, slope_steps)
    # digitize returns the index of the bin where value belongs to
    inds = np.digitize(x,bins)

    #TODO: rename file headers to easier distinct the results
    data = pd.DataFrame({'slope': x, 'bin': inds, 'diff': y})
    grouped_data = data.groupby('bin').agg({'slope': 'median', 'diff': ['std', 'median', 'mean']})

    bin_centers = grouped_data['slope']['median']
    std = grouped_data['diff']['std']
    # need to calculate the STD for one DEM - see paper Eq. 2
    grouped_data['stdi'] = grouped_data['diff']['std']/np.sqrt(2)
    stdi = grouped_data['stdi']

    median = grouped_data['diff']['median']
    mean = grouped_data['diff']['mean']
    print(grouped_data)
    
    grouped_data.to_csv(os.path.join(out_path, 'statistics.txt'), sep='\t')

    fig, (ax1, ax2) = plt.subplots(2, 1, gridspec_kw={'height_ratios': [2, 1]}, sharex=True)

    ax1.plot(bin_centers, median, '-b', label='Median')
    ax1.plot(bin_centers, mean, '-r', label='Mean')
    ax1.plot(bin_centers, stdi, '-k', label='STDi')

    y = np.array([median,mean,stdi]); ymax = np.nanmax(y); ymin = np.nanmin(y)

    ax1.set_xlim(0, max_slope)
    ax1.set_ylim(ymin, ymax)
    ax1.set_xlabel('Slope [deg]')
    ax1.set_ylabel('DEM Error [m]')
    ax1.set_title('DEM Error as Function of Slope for {}'.format(option))
    ax1.legend()

    ax2.hist(x, bins=histo_bins, alpha=0.7)
    
    ax2.set_xlim(0, 75)
    ax2.set_xlabel('Slope [deg]')
    ax2.set_ylabel('Frequency')

    plt.tight_layout()

    plt.show()
    

def prepare_and_plot_data(slope_file, diff_file, option):
    
    print('Read slope data')
    slope = read_from_file(slope_file)

    print('Read difference data')
    diff = read_from_file(diff_file)

    # assumed that all necessary files are stored in the same directory
    # this directory will be handled as output dir for statistics.txt
    diff_path = os.path.dirname(diff_file)
    print('Start generating slope plot')
    multiplot_slope_error(slope, diff_path, option, diff)
    
########
# MAIN #
########

arguments = docopt.docopt(__doc__)

# all input files should be in one directory
diff_file = arguments['--diff']
slope_file = arguments['--slope']

# naming for final plot
option = arguments['--name']

# destination path will be path of diff file
dest_path = os.path.dirname(diff_file)


#############
# PLOT DATA #
#############

# SINGLE PLOT #
prepare_and_plot_data(slope_file, diff_file, option)




