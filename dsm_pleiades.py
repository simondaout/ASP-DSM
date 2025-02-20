# handle all the asp dsm pleiades workflow in a modulable way

import numpy as np
from dsm_toml_file import DsmToml
from dsm_dim_parse import PleiadesDIM

from osgeo import gdal

import os
import sys
import subprocess


def setup_folders():
    # construct the folder structure
    not_implemented()

def check_folder_exist():
    not_implemented()

def prepare_dem():
    not_implemented()

def check_dem():
    not_implemented()

def bundle_adjust():
    not_implemented()

def check_bundle_adjust():
    not_implemented()

def orbitviz():
    not_implemented()

def check_orbit_viz():
    not_implemented()

def map_project():
    not_implemented()

def check_map_project():
    not_implemented()

def stereo():
    not_implemented()

def check_stereo():
    not_implemented()

def rastering():
    not_implemented()

def check_rastering():
    not_implemented()

def merge():
    not_implemented()

def check_merge():
    not_implemented()

def ms_ortho():
    not_implemented()

def check_ms_ortho():
    not_implemented()

def error_estimation():
    not_implemented()

def check_error_estimation():
    not_implemented()


def dsm_run(toml_path):
    toml = DsmToml(toml_path)
    sc = toml.step_control

    if not check_folder_exist:
        setup_folders()

    if not check_dem() and sc.dem:
        prepare_dem()
    
    if not check_bundle_adjust() and sc.bundle_asjust:
        bundle_adjust()

    if not check_orbit_viz() and sc.orbit_viz:
        orbitviz()

    if not check_map_project() and sc.map_project:
        map_project()

    if not check_stereo() and sc.stereo:
        stereo()

    if not check_rastering() and sc.rastering:
        rastering()

    if not check_merge() and sc.merge:
        merge()

    if not check_ms_ortho() and sc.ms_orthorectified:
        ms_ortho()
    
    if not check_error_estimation() and sc.error_estimation:
        error_estimation()


def cli():
    print("launch cli...")
    print("...\n...\n...")
    not_implemented()


def not_implemented():
    raise NotImplementedError("not implemented...\n\n\t(ㅠ﹏ㅠ)\n")


if __name__ == "__main__":
    cli()
