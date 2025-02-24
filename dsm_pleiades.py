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

    # Example

    ````
    sh("ls -l | wc -l")
    ````

    """
    subprocess.run(cmd, shell=True, stdout=sys.stdout, stderr=subprocess.STDOUT, env=os.environ)

class DsmRun:
    """
    Handles the command run and the linear steps succession
    """
    def __init__(self, toml: str):
        """
        :param toml: path to the toml parameter file
        """
        self.toml_path = toml
        self.toml = DsmToml(toml)
        self.lock = None
        self.output = None
        self.run_nb = 0
        
        self.dims = []
        self.tifs = []
        self.bboxs = []
        self.global_bbox = []
        self.dem = None
        self.dem_utm = None

    def run(self):
        """
        Call the major steps to run:

        * Init the workspace (raw data, output folder, ba, orbit, mapproj)
        * Performs the stereo (and merge)
        * Produces ms orthorectified images
        * Launch the error estimation
        """
        print("run")
        self._workspace_ready()
        self._run_process_stereo()
        if self.toml.step_control.ms_orthorectified:
            self._ms_ortho()

    def _setup_folders(self):
        """
        Setup the output folders and the lock file.
        """
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

        for k in range(len(self.toml.sources)):
            if not os.path.isdir(output_folder + "/frag" + str(k + 1)):
                os.mkdir(output_folder + "/frag" + str(k + 1))

        run_nb = self.lock.current_run()
        for k in range(1, run_nb):
            toml_run = DsmToml(os.path.join(output_folder, "run_" + str(k), "asp_dsm.lock"))
            if not self.toml.has_stereo_change(toml_run):
                self.run_nb = k
                
        if self.run_nb == 0: # run start at 1
            self.lock.new_run()
            self.run_nb = self.lock.current_run()

        if not os.path.isdir(os.path.join(output_folder, "run_" + str(self.run_nb))):
            os.mkdir(os.path.join(output_folder, "run_" + str(self.run_nb)))

        sh("cp {} {}/asp_dsm.lock".format(
            self.toml_path,
            os.path.join(self.output, "run_" + str(self.run_nb))
        ))
    
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
        if not self.lock.is_dem_lock():
            if len(self.toml.run.dem_path) == 0 or sc.dem:
                self._compute_dem()
            else: 
                self.dem = self.toml.run.dem_path
            self.dem_utm = os.path.splitext(self.dem)[0] + "_utm.tif"
            sh("gdalwarp -tr {} -t_srs {} {} {} -r {}".format(" ".join([str(res) for res in self.toml.output.gdal_out_res]),
                                                            "EPSG:" + str(self.toml.output.utm),
                                                            self.dem,
                                                            self.dem_utm,
                                                            self.toml.output.resamp_m))
            self.lock.lock_dem(self.dem_utm)
        else: 
            self.dem_utm = self.lock.dem

        for s in range(len(self.toml.sources)):
            frag_folder = os.path.join(self.output, "frag" + str(s + 1))
            sh("cd {}".format(frag_folder))
            print("frag", s)
            
            # Bundle adjust the images
            if not self.lock.is_ba_lock(s) or sc.bundle_adjust:
                print("bundle")
                self._bundle_adjust(s)
                self.lock.lock_ba(s)

            # Create orbit kml visualization
            if sc.orbit_viz:
                print("orbit")
                self._orbit_viz(s)
                
            # Mapproject the images
            if not self.lock.is_mp_lock(s) or sc.map_project:
                print("mapproject")
                self._map_project(s)
                self.lock.lock_mp(s)

    def _raw_data_ready(self):
        """
        Read and prepare the raw data. Ensure that all image info are found. Ensure that the raw images are available as one .TIF file.

        Computes a global bbox for all the acquisitions.
        """
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
        """
        Fetch a DEM using pygdalsar referring to the ellipsoid.
        """
        long1, long2, lat1, lat2 = self.global_bbox[0], self.global_bbox[1], self.global_bbox[2], self.global_bbox[3]
        dst = os.path.join(self.toml.output.path, "cop_dem30_{}_{}_{}_{}".format(int(long1), int(long2), int(lat1), int(lat2)))
        sh("my_getDemFile.py -s COP_DEM --bbox={},{},{},{} -c /data/ARCHIVES/DEM/COP-DEM_GLO-30-DTED/DEM".format(long1, long2, lat1, lat2))
        sh("gdal_translate -of Gtiff {} {}".format(dst + ".dem", dst + ".tif"))
        self.dem = os.path.join(self.toml.output.path, dst + ".tif")

        os.remove(os.path.join(self.toml.output.path, dst + ".dem"))
        os.remove(os.path.join(self.toml.output.path, dst + ".dem.aux.xml"))
        os.remove(os.path.join(self.toml.output.path, dst + ".dem.rsc"))
    
    def _get_src_dim_from_nb(self, source_nb):
        """
        Helper function to get src, dims and tifs full paths for a given fragment.
        """
        source = self.toml.sources[source_nb].paths

        src = source[0] + ' ' + source[1]
        tifs = " ".join(self.tifs[source_nb])
        dims = self.dims[source_nb][0].dim_path + ' ' + self.dims[source_nb][1].dim_path
        if len(source) == 3:
            src = src + ' ' + source[2]
            dims = dims + ' ' + self.dims[source_nb][2].dim_path
        return src, dims, tifs

    def frag_folder(self, source_nb):
        """
        Helper function to acces the full path of the current fragment folder
        """
        return os.path.join(self.output, "frag" + str(source_nb + 1))

    def _bundle_adjust(self, source_nb):
        """
        Perform the bundle adjustment of the current fragment.

        Uses asp.
        """
        src, dims, tifs = self._get_src_dim_from_nb(source_nb)
        frag_folder = self.frag_folder(source_nb)
        print("frag folder", frag_folder)

        ba_params = "--datum wgs84 -o {}/ba/run --ip-detect-method 0 --ip-per-tile 50 --ip-inlier-factor 0.4 --num-passes 2 --robust-threshold 0.5 --parameter-tolerance 1e-10 --max-iterations 500 --camera-weight 0 --tri-weight 0.1".format(frag_folder)

        sh("bundle_adjust {} {} -t {} {}".format(tifs, dims, self.toml.stereo.session_type, ba_params))

    def _orbit_viz(self, source_nb):
        """
        Prepare a kml visualization of orbits for the current fragment.

        Uses asp.
        """
        src, dims, tifs = self._get_src_dim_from_nb(source_nb)
        frag_folder = self.frag_folder(source_nb)

        sh("orbitviz -t {} {} {} -o {}/orbitviz_sat_pos_adjusted.kml --bundle-adjust-prefix {}/ba/run".format(
            self.toml.stereo.session_type,
            tifs,
            dims,
            frag_folder,
            frag_folder
        ))

    def _map_project(self, source_nb):
        """
        Perform the map projection onto the DEM for the current fragment.

        Uses asp.
        """
        src, dims, tifs = self._get_src_dim_from_nb(source_nb)
        src, dims, tifs = src.split(' '), dims.split(' '), tifs.split(" ")
        frag_folder = self.frag_folder(source_nb)

        for k in range(len(src)):
            out_file = os.path.join(self.output, frag_folder, "mapproj", "mp_" + os.path.basename(tifs[k]))
            print("img", tifs[k])
            print("camera", dims[k])
            print("output", out_file)
            sh("mapproject -t {} --t_srs EPSG:{} --tr {} {} {} {} {} --bundle-adjust-prefix {}/ba/run --nodata-value 0".format(
                self.toml.stereo.session_type,
                self.toml.output.utm,
                self.toml.output.resmp,
                self.dem_utm,
                tifs[k],
                dims[k],
                out_file,
                frag_folder
            ))

    def _run_process_stereo(self):
        """
        Run the stereo and post processing operations:

        * stereo
        * rastering (point2dem)
        * merging (if multiple images)
        * ms ortho
        * error estimation
        """
        for s in range(len(self.toml.sources)):
            self._stereo(s)
            self._rastering(s)
        self._merge(len(self.tifs))
        if self.toml.step_control.error_estimation:
            self._error_estimation()
    
    def _stereo(self, source_nb):
        print(">stereo")
        src, dims, tifs = self._get_src_dim_from_nb(source_nb)
        src, dims, tifs = src.split(' '), dims.split(' '), tifs.split(" ")
        frag_folder = self.frag_folder(source_nb)
        mp_img = [os.path.join(self.output, frag_folder, "mapproj", "mp_" + os.path.basename(tifs[k])) for k in range(len(src))]

        pre_args = '-t {} --alignment-method {}'.format(
            self.toml.stereo.session_type,
            self.toml.stereo.alignement_method
        )

        session = '--nodata-value {} {} --threads-multiprocess {}'.format(
            self.toml.stereo.nodata_value_stereo,
            self.dem_utm,
            self.toml.run.threads
        )

        st = self.toml.stereo
        stereo = ('--prefilter-mode {} --prefilter-kernel-width {} --corr-kernel {} --cost-mode {} '
        '--stereo-algorithm {} --corr-tile-size {} --subpixel-mode {} --subpixel-kernel {} --corr-seed-mode {} '
        '--xcorr-threshold {} --min-xcorr-level {} --sgm-collar-size {}').format(
            st.prefilter_mode,
            st.prefilter_kernel_width,
            " ".join([str(k) for k in st.corr_kernel]),
            st.cost_mode,
            st.st_alg,
            st.corr_tile_size,
            st.subp_mode,
            " ".join([str(k) for k in st.subp_kernel]),
            st.corr_seed_mode, 
            st.xcorr_threshold,
            st.min_xcorr_lvl,
            st.sgm_collar_size
        )

        dn = self.toml.stereo.denoising
        denoising = ('--rm-quantile-percentile {} --rm-quantile-multiple {} '
        '--filter-mode {} --rm-half-kernel {} --rm-min-matches {}'
        ' --rm-threshold {} --max-mean-diff {}').format(
            dn.rm_quant_pc,
            dn.rm_quantile_multiple,
            dn.filter_mode,
            " ".join([str(k) for k in dn.rm_half_kernel]),
            dn.rm_min_matches,
            dn.rm_threshold,
            dn.max_mean_diff
        )

        ft = self.toml.stereo.filtering
        filtering = '--median-filter-size {} --texture-smooth-size {} --texture-smooth-scale {}'.format(
            ft.median_filter_size,
            ft.texture_smooth_size,
            ft.texture_smooth_scale
        )

        post_args = '{} {} {} {} --bundle-adjust-prefix frag{}/ba/run'.format(
            session,
            stereo,
            denoising,
            filtering,
            source_nb + 1
        )

        cmd = 'parallel_stereo {} {} {} frag{}/demPleiades/dem {}'.format(
            pre_args,
            " ".join(mp_img), 
            " ".join(dims),
            source_nb + 1,
            post_args
        )

        sh(cmd)

    def _rastering(self, source_nb):
        """
        Transform the point cloud produce by the stereo step into a raster, for the current fragment.

        :param source_nb: current fragment
        """
        r = self.toml.rastering
        frag_folder = self.frag_folder(source_nb)
        sh("cd {}".format(
            frag_folder
        ))

        point_params = "--median-filter-params {} --tif-compress {} --max-valid-triangulation-error {} --remove-outliers-param {} --remove-outliers".format(
            r.median_filter_params,
            r.tif_compress,
            r.max_valid_triangulation_error,
            r.remove_outlier_param
        )

        sh("point2dem --t_srs EPSG:{} --tr {} demPleiades/dem-PC.tif {}".format(
            self.toml.output.utm, 
            self.toml.output.res,
            point_params
        ))
        
        sh("gdalwarp -wm 512 -q -co COMPRESS=DEFLATE -overwrite -of GTiff -ot Float32 -r cubic {} {}".format(
            os.path.join(frag_folder, "demPleiades", "dem-DEM.tif"),
            os.path.join(frag_folder, "dem_raster.tif")
        ))

    def _merge(self, frag_nb):
        """
        Combine all fragments raster results into one global raster

        :param frag_nb: number of total fragments
        """
        not_implemented()
        frag_dirs = []
        for k in range(frag_nb):
            frag_dirs.append(self.frag_folder(k + 1))

        run_folder = os.path.join(self.output, "run_" + str(self.run_nb))
        
        sh("gdalbuildvrt {} {}".format(
            os.path.join(run_folder, "vrt.tif"),
            " ".join([os.path.join(f, "dem_raster.tif") for f in frag_dirs])
        ))

        sh("gdal_translate -co TILED=YES -co BLOCKXSIZE=256 -co BLOCKYSIZE=256 -co BIGTIFF=IF_SAFER {} {}".format(
            os.path.join(run_folder, "vrt.tif"),
            os.path.join(run_folder, "dsm.tif")
        ))

        sh("gdalwarp -wm 512 -q -co COMPRESS=DEFLATE -overwrite -of GTiff -ot Float32 -r cubic {} {}".format(
            os.path.join(run_folder, "dsm.tif"),
            os.path.join(run_folder, "dsm_result.tif")
        ))

        os.remove(os.path.join(run_folder, "vrt.tif"))
        os.remove(os.path.join(run_folder, "dsm.tif"))

    def _ms_ortho(self):
        """
        Produce orthorectified images from MS pléiades
        """
        # does not depend on stereo run
        # need to rewrite mosaic ms
        not_implemented()

    def _error_estimation(self):
        """
        Estimate the errors associated to the produced DEM
        """
        # need to rewrite error estim
        not_implemented()


def cli():
    """
    Defines the argument handling by docopt and init the run
    """
    print('>Launching cli...')
    arguments = docopt.docopt(__doc__)
    toml_path = arguments['--toml']

    if not os.path.isfile(toml_path):
        raise ValueError("Invalid path given to the cli, recheck your inputs.")

    print(">init run")
    run = DsmRun(toml_path)
    print(">run init, starting run")

    run.run()

    print(">run completed")

    not_implemented()


def not_implemented():
    """
    Little message to display to show that a feature is not implemented yet.

    As it raises an error, the program stops here.
    """
    raise NotImplementedError("not implemented...\n\n\t(ㅠ﹏ㅠ)\n")


if __name__ == "__main__":
    cli()
