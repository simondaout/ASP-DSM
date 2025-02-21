#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""
dsm_pleiades.py
_______________
Handle DSM production from Pléiades images using the ASP toolchain.

Usage: dsm_pleiades.py --toml=<toml_path>
dsm_pleiades.py -h | --help

Options:
--toml=<toml_path>      Path to the toml parameter file

"""

import numpy as np
from dsm_toml_file import DsmToml, DsmLock
from dsm_dim_parse import PleiadesDIM

from osgeo import gdal

import os
import sys
import subprocess

import docopt

def sh(cmd: str):
    """
    Launch a shell command
    """
    subprocess.call(cmd, shell=True, stdout=sys.stdout, stderr=subprocess.STDOUT, env=os.environ)

class DsmRun:
    def __init__(self, toml):
        self.toml_path = toml
        self.toml = DsmToml(toml)
        self.lock = None
        self.output = None
        
        # ante stereo
        self.available_as = {"dem": False, "ba": False, "orbit": False, "mapproj": False}
        # post stereo
        self.available_ps = {"stereo": False, "rastering": False, "merge": False, "ms": False, "error": False}
        
        self.dims = []
        self.tifs = []
        self.bboxs = []
        self.global_bbox = []
        self.dem = None
        self.dem_utm = None

    def run(self):
        print("run")
        self._workspace_ready()
        not_implemented()

    def _setup_folders(self):
        print("setup folder")
        output_folder = self.toml.output.path
        self.output = output_folder

        if not os.path.isdir(output_folder):
            os.mkdir(output_folder)
        lock_path = os.path.join(output_folder, "asp_dsm.lock")

        if not os.path.isfile(lock_path):
            self.lock = DsmLock().new(self.toml, lock_path)
        else:
            self.lock = DsmLock().open(lock_path)
            avail = self.lock.check_commons()
            self.available_as = {"dem": avail[0], "ba": avail[1], "orbit": avail[2], "mapproj": avail[3]}
        
        for k in range(len(self.toml.sources)):
            if not os.path.isdir(output_folder + "/frag" + str(k + 1)):
                os.mkdir(output_folder + "/frag" + str(k + 1))
    
    def _workspace_ready(self):
        """
        Workspace is ready when:

        * raw img is in one .TIF
        * dem is acquired
        * img is bundle adjusted
        * orbit kml
        * img is mapprojected
        """
        print("workspace ready")
        # Setup the working folder
        self._setup_folders()
        sh("cd {}".format(self.toml.output.path))
        sc = self.toml.step_control

        # Check if raw data is ready, i.e single .TIF
        self._raw_data_ready()

        # Prepare the DEM
        if not self.available_as["dem"] or sc.dem:
            self._compute_dem()
        else: 
            self.dem = self.toml.run.dem_path
        self.dem_utm = os.path.splitext(self.dem)[0] + "_utm.tif"
        sh("gdalwarp -tr {} -t_srs {} {} {} -r {}".format(" ".join([str(res) for res in self.toml.output.gdal_out_res]),
                                                           "EPSG:" + str(self.toml.output.utm),
                                                           self.dem,
                                                           self.dem_utm,
                                                           self.toml.output.resamp_m))

        for s in range(len(self.toml.sources)):
            frag_folder = os.path.join(self.output, "frag" + str(s + 1))
            sh("cd {}".format(frag_folder))
            print("frag", s)
            
            # Bundle adjust the images
            if not self.available_as["ba"] or sc.bundle_asjust:
                print("bundle")
                self._bundle_adjust(s)

            # Create orbit kml visualization
            if not self.available_as["orbit"] or sc.orbit_viz:
                print("orbit")
                self._orbit_viz(s)
                
            # Mapproject the images
            if not self.available_as["mapproj"] or sc.map_project:
                print("mapproject")
                self._map_project(s)

    def _raw_data_ready(self):
        src = [s.paths for s in self.toml.sources]
        print(src)

        for s in src:
            if not len(s) == 2 and not len(s) == 3:
                raise ValueError("Invalid number of images for stereo ({}). Must be 2 or 3.".format(len(s)))
            dims = []
            for img_p in s:
                dim = PleiadesDIM(img_p)
                dim.prepare()
                dims.append(dim)
            self.dims.append(dims)
            self.tifs.append([k.img_tif for k in dims])
            self.bboxs.append([k.bbox for k in dims])
        
        self.bboxs = np.array(self.bboxs)
        self.global_bbox = [np.min(self.bboxs[:, :, 0]), np.max(self.bboxs[:, :, 1]), np.min(self.bboxs[:, :, 2]), np.max(self.bboxs[:, :, 3])]
        # 2% padding for security
        bbox_width = self.global_bbox[1] - self.global_bbox[0]
        bbox_height = self.global_bbox[3] - self.global_bbox[2]
        self.global_bbox = [self.global_bbox[0] - 0.02 * bbox_width, 
                            self.global_bbox[1] + 0.02 * bbox_width,
                            self.global_bbox[2] - 0.02 * bbox_height,
                            self.global_bbox[3] + 0.02 * bbox_height]

    
    def _compute_dem(self):
        long1, long2, lat1, lat2 = self.global_bbox[0], self.global_bbox[1], self.global_bbox[2], self.global_bbox[3]
        dst = os.path.join(self.toml.output.path, "cop_dem30_{}_{}_{}_{}".format(int(long1), int(long2), int(lat1), int(lat2)))
        sh("my_getDemFile.py -s COP_DEM --bbox={},{},{},{} -c /data/ARCHIVES/DEM/COP-DEM_GLO-30-DTED/DEM".format(long1, long2, lat1, lat2))
        sh("gdal_translate -of Gtiff {} {}".format(dst + ".dem", dst + ".tif"))
        self.dem = os.path.join(self.toml.output.path, dst + ".tif")
    
    def _get_src_dim_from_nb(self, source_nb):
        source = self.toml.sources[source_nb].paths

        src = source[0] + ' ' + source[1]
        tifs = " ".join(self.tifs[source_nb])
        dims = self.dims[source_nb][0].dim_path + ' ' + self.dims[source_nb][1].dim_path
        if len(source) == 3:
            src = src + ' ' + source[2]
            dims = dims + ' ' + self.dims[source_nb][2].dim_path
        return src, dims, tifs

    def frag_folder(self, source_nb):
        return os.path.join(self.output, "frag" + str(source_nb + 1))

    def _bundle_adjust(self, source_nb):
        src, dims, tifs = self._get_src_dim_from_nb(source_nb)
        frag_folder = self.frag_folder(source_nb)
        print("frag folder", frag_folder)

        ba_params = "--datum wgs84 -o {}/ba/run --ip-detect-method 0 --ip-per-tile 50 --ip-inlier-factor 0.4 --num-passes 2 --robust-threshold 0.5 --parameter-tolerance 1e-10 --max-iterations 500 --camera-weight 0 --tri-weight 0.1".format(frag_folder)

        sh("bundle_adjust {} {} -t {} {}".format(tifs, dims, self.toml.stereo.session_type, ba_params))

    def _orbit_viz(self, source_nb):
        not_implemented()
        src, dims, tifs = self._get_src_dim_from_nb(source_nb)

        sh("orbitviz -t {} {} {} -o orbitviz_sat_pos_adjusted.kml --bundle-adjust-prefix ba/run".format(
            self.toml.stereo.session_type,
            tifs,
            dims
        ))

    def _map_project(self, source_nb):
        src, dims, tifs = self._get_src_dim_from_nb(source_nb)
        src, dims, tifs = src.split(' '), dims.split(' '), tifs.split(" ")

        for k in range(len(src)):
            sh("mapproject -t {} --t_srs EPSG:{} --tr {} {} {} {} {} --bundle-adjust-prefix ba/run --nodata-value 0".format(
                self.toml.stereo.session_type,
                self.toml.output.utm,
                self.toml.output.resmp,
                self.dem_utm,
                tifs[k],
                dims[k],
                os.path.join(self.output, "mapproj", "mp_" + os.path.basename(src[k]))
            ))

    def _run_process_stereo(self):
        not_implemented()


def cli():
    print('>Launching cli...')
    arguments = docopt.docopt(__doc__)
    toml_path = arguments['--toml']

    print(">init run")
    run = DsmRun(toml_path)
    print(">run init, starting run")

    run.run()

    print(">run completed")

    not_implemented()


def not_implemented():
    raise NotImplementedError("not implemented...\n\n\t(ㅠ﹏ㅠ)\n")


if __name__ == "__main__":
    cli()
