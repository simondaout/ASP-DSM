"""
dem_error_estimation.py
-------------
Plot the DEM error as function of the slope using the difference of two DEMs and the corresponding slope

Usage: dem_error_estimation.py [--force] --diff=<path> --slope=<path> --name=<string> 
dem_error_estimation.py -h | --help

Options:
-h --help           Show this screen.
--diff PATH       Path to difference file
--slope PATH      Path to slope file   
--name STRING     Naming for plot title
--force           Force calculation of pixel_sigma.tif file

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


def calculate_pixel_sigma(diff):

    x_dim, y_dim = diff.shape[0], diff.shape[1]
    mean = np.nanmean(diff)
    out = np.zeros((x_dim, y_dim))
    #print(np.amax(diff)) 
    print('Start pixel sigma calculation')
    for x in range(x_dim):
        #print('Start line: {}'.format(x))
        for y in range(y_dim):
            if(np.isnan(diff[x][y])): 
                continue
            else:
                std = np.sqrt((diff[x][y] - mean)**2)
                #print(std)
                out[x][y] = std
    print('Finished pixel sigma calculation')
    return out

def multiplot_slope_error(slope, pixel_sigma, out_path, option, diff):

    x = slope.flatten() # slope_flat - used to plot slope histogram
    y = pixel_sigma.flatten() # sigma_pixel_flat - used to calculate stdi
    z = diff.flatten() # diff_flat - used to get mean/median error

    #TODO: define with docopt, max_slope, slope_steps 
    # default 75, 5
    max_slope = 75
    slope_steps = 5

    bins = np.arange(0, max_slope, slope_steps)
    histo_bins = np.arange(0, max_slope, slope_steps)
    # digitize returns the index of the bin where value belongs to
    inds = np.digitize(x,bins)

    #TODO: rename file headers to easier distinct the results
    data = pd.DataFrame({'x': x, 'y': y, 'bin': inds, 'z': z})
    grouped_data = data.groupby('bin').agg({'x': 'median', 'y': ['std', 'median', 'mean'], 'z': ['median', 'mean']})

    bin_centers = grouped_data['x']['median']
    std = grouped_data['y']['std']
    # need to calculate the STD for one DEM - see paper Eq. 2
    grouped_data['stdi'] = grouped_data['y']['std']/np.sqrt(2)
    stdi = grouped_data['stdi']

    median = grouped_data['z']['median']
    mean = grouped_data['z']['mean']
    print(grouped_data)
    
    grouped_data.to_csv(os.path.join(out_path, 'statistics.txt'), sep='\t')

    fig, (ax1, ax2) = plt.subplots(2, 1, gridspec_kw={'height_ratios': [2, 1]}, sharex=True)

    ax1.plot(bin_centers, median, '-b', label='Median')
    ax1.plot(bin_centers, mean, '-r', label='Mean')
    ax1.plot(bin_centers, stdi, '-k', label='STDi')

    ax1.set_xlim(0, 75)
    ax1.set_ylim(-2, 10)
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
    
    return (fig, ax1, ax2)

def create_pixel_sigma_file(diff, pixel_sigma_file):
    pixel_sigma_results = calculate_pixel_sigma(diff)
    save_to_file(pixel_sigma_results, pixel_sigma_file, pixel_sigma_results.shape[1], pixel_sigma_results.shape[0])

def prepare_and_plot_data(slope_file, diff_file, pixel_sigma_file, option):
    
    print('Read slope data')
    slope = read_from_file(slope_file)

    print('Read difference data')
    diff = read_from_file(diff_file)

    print('Read from sigma_pixel file')
    if(os.path.isfile(pixel_sigma_file)):
        pixel_sigma = read_from_file(pixel_sigma_file)
    else:
        print('No pixel_sigma file; run create_pixel_sigma_file first')

    # assumed that all necessary files are stored in the same directory
    # this directory will be handled as output dir for statistics.txt
    diff_path = os.path.dirname(diff_file)
    print('Start generating slope plot')
    multiplot_slope_error(slope, pixel_sigma, diff_path, option, diff)
    
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

# path of pixel sigma file
pixel_sigma_file = os.path.join(dest_path, 'pixel_sigma.tif')


# if sigma_pixel doesn't exist -> compute
exist_pixel_sigma = os.path.isfile(pixel_sigma_file)
# force recomputation of sigma_pixel.tif
force_pixel_sigma = arguments['--force']

if(not exist_pixel_sigma or force_pixel_sigma):
    if(not exist_pixel_sigma):
        print('pixel_sigma.tif not found. Compute sigma_pixel.tif')
    else:
        print('Force recomputation of pixel_sigma.tif')
    print('sigma_pixel.tif will be stored in {}'.format(dest_path))
    diff = read_from_file(diff_file)
    create_pixel_sigma_file(diff, pixel_sigma_file)


#############
# PLOT DATA #
#############

# SINGLE PLOT #
prepare_and_plot_data(slope_file, diff_file, pixel_sigma_file, option)




