import tomli
import os


def parse_toml(file):
    with open(file, "rb") as f:
        toml = tomli.load(f)
    return toml


class DsmToml:
    def __init__(self, toml):
        toml = parse_toml(toml)
        self.toml_dic = toml

        self.run = Run(toml["run"])
        self.output = Output(toml["output"])
        self.sources = [Source(s) for s in toml["source"]]
        self.step_control = StepControl(toml.get("step_control", None))
        self.stereo = Stereo(toml["stereo"])
        self.rastering = Rastering(toml["rastering"])

    def has_stereo_change(self, other):
        if self.step_control.stereo ^ other.step_control.stereo:
            return True
        return self.toml_dic["stereo"] != other.toml_dic["stereo"]


class Run:
    def __init__(self, dic):
        self.name = dic["name"]
        self.info = dic["info"]
        self.dem_path = dic.get("dem_path", None)
        self.threads = dic["threads"]


class Output:
    def __init__(self, dic):
        self.path = dic["path"]
        self.utm = dic["utm"]
        self.res = dic.get("res", 2)
        self.resmp = dic.get("resmp", 1)
        self.gdal_out_res = dic.get("gdal_out_res", [30, 30])
        self.resamp_m = dic.get("resamp_m", "cubic")


class Source:
    def __init__(self, dic):
        self.paths = dic["paths"]


class StepControl:
    # can not be indicated
    def __init__(self, dic):
        self.dem = dic.get("dem", True)
        self.bundle_adjust = dic.get("bundle_adjust", True)
        self.orbit_viz = dic.get("orbit_viz", True)
        self.map_project = dic.get("map_project", True)
        self.stereo = dic.get("stereo", True)
        self.rastering = dic.get("rastering", True)
        self.merge = dic.get("merge", True)
        self.ms_orthorectified = dic.get("ms_orthorectified", True)
        self.error_estimation = dic.get("error_estimation", True)


class Stereo:
    def __init__(self, dic):
        self.session_type = dic.get("session_type", "pleiades")
        self.st_alg = dic["st_alg"]
        self.cost_mode = dic["st_alg"]
        self.subp_mode = dic["subp_mode"]
        self.corr_kernel = dic["corr_kernel"]
        self.subp_kernel = dic["subp_kernel"]
        
        dic_adv = dic.get("advance", {})

        self.alignement_method = dic_adv.get("alignement_method", "none")
        self.nodata_value_stereo = dic_adv.get("nodata_value_stereo", 0)
        self.corr_tile_size = dic_adv.get("corr_tile_size", 1024)
        self.corr_seed_mode = dic_adv.get("corr_seed_mode", 1)
        self.xcorr_threshold = dic_adv.get("xcorr_threshold", 2)
        self.min_xcorr_lvl = dic_adv.get("min_xcorr_lvl", 1)
        self.sgm_collar_size = dic_adv.get("sgm_collar_size", 256)
        self.prefilter_mode = dic_adv.get("prefilter_mode", 2)
        self.prefilter_kernel_width = dic_adv.get("prefilter_kernel_width", 1.4)

        self.denoising = Denoising(dic.get("denoising", {}))
        self.filtering = Filtering(dic.get("filtering", {}))


class Denoising:
    def __init__(self, dic):
        self.rm_quantile_multiple = dic.get("rm_quantile_multiple", -1)
        self.rm_clean_pass = dic.get("rm_clean_pass", 1)
        self.rm_quant_pc = dic.get("rm_quant_pc", 0.95)
        self.filter_mode = dic.get("filter_mode", 2)
        self.rm_half_kernel = dic.get("rm_half_kernel", [7, 7])
        self.rm_min_matches = dic.get("rm_min_matches", 50)
        self.rm_threshold = dic.get("rm_threshold", 4)
        self.max_mean_diff = dic.get("max_mean_diff", 4)


class Filtering:
    # can not be indicated
    def __init__(self, dic):
        self.do = dic.get("do", True)
        self.median_filter_size = dic.get("median_filter_size", 3)
        self.texture_smooth_size = dic.get("texture_smooth_size", 3)
        self.texture_smooth_scale = dic.get("texture_smooth_scale", 0.13)


class Rastering:
    def __init__(self, dic):
        self.median_filter_params = dic.get("", [9, 50])
        self.dem_hole_fill_len = dic.get("dem_hole_fill_len", 200)
        self.erode_length = dic.get("erode_length", 0)
        self.nodata_value_dem = dic.get("nodata_value_dem", 0)
        self.tif_compress = dic.get("tif_compress", "Deflate")
        self.max_valid_triangulation_error = dic.get("max_valid_triangulation_error", 4.0)
        self.remove_outlier_param = dic.get("remove_outlier_param", [75.0, 3.0])


class DsmLock:
    """
    Logic handling for the lock system
    """
    def __init__(self):
        self.path = None

        self.name = ""
        self.dem = ""
        self.frags = [] # array of (bool, bool)
        self.param = {}

    def new(self, toml: DsmToml, lock_path):
        """
        Create a lock system for a new project

        :param toml: toml to create the project for
        :param lock_path: path where to create the lock
        """
        self.path = lock_path
        frag_nb = len(toml.sources)
        self.run = 1
        
        self.name = toml.run.name
        self.frags = [[False, False] for _ in range(frag_nb)]

        self.param["dem_utm"] = toml.run.dem_path
        self.param["gdal_out_res"] = toml.output.gdal_out_res
        self.param["utm"] = toml.output.utm
        self.param["resamp_m"] = toml.output.resamp_m
        self.param["session_type"] = toml.stereo.session_type
        self.param["resmp"] = toml.output.resmp

        self.write_lock()
        return self

    def open(self, lock_path):
        """
        Open an existing lock to resume work on this project
        """
        self.path = lock_path
        lock = parse_toml(lock_path)

        self.name = lock["lock"]["name"]
        self.dem = lock["lock"]["dem_utm"]
        self.run = int(lock["lock"]["run"])
        self.param = lock["lock"]["parameters"]

        frags = lock["frag"]
        for f in frags:
            self.frags.append([f["bundle_adjust"], f["mapproj"]])
        
        return self
    
    def lock_dem(self, dem_utm_path):
        """
        Add the DEM to lock. It will be reused for other operations in this project.

        :param dem_utm_path: path to the dem
        """
        self.dem = dem_utm_path
        self.write_lock()
    
    def is_dem_lock(self):
        """
        Bool to check if a DEM has been locked.
        """
        return len(self.dem) != 0
    
    def lock_ba(self, frag_nb):
        """
        Add the bundle adjustment to lock [bool] for the current fragment.

        :param frag_nb: number of the fragment current under processing
        """
        self.frags[frag_nb][0] = True
        self.write_lock()

    def is_ba_lock(self, frag_nb):
        """
        Bool to check if th bundle adjustment of the current fragment has been locked.
        """
        return self.frags[frag_nb][0]
    
    def lock_mp(self, frag_nb):
        self.frags[frag_nb][1] = True
        self.write_lock()

    def is_mp_lock(self, frag_nb):
        return self.frags[frag_nb][1]
    
    def new_run(self):
        """
        Initialize a new run (run counter + 1).
        """
        self.run += 1
        self.write_lock()

    def current_run(self):
        """
        Get the last run number
        """
        return self.run

    def write_lock(self):
        """
        Write and update lock file.
        """
        # hardcoded because tomli_w currently not installed on server
        content = '''[lock]\nname = "{}"\ndem_utm = "{}"\nrun = "{}"\n\n'''.format(
            self.name,
            self.dem,
            self.run
        )

        print(self.param)

        param = '[lock.parameters]\ndem_path = "{}"\ngdal_out_res = "{}"\nutm = "{}"\nresamp_m = "{}"\nsession_type = "{}"\nresmp = "{}"\n\n'.format(
            self.param["dem_path"],
            self.param["gdal_out_res"],
            self.param["utm"],
            self.param["resamp_m"],
            self.param["session_type"],
            self.param["resmp"]
        )

        frags = ""
        for k in range(len(self.frags)):
            ba = "true" if self.frags[k][0] else "false"
            mp = "true" if self.frags[k][1] else "false"
            frag = '''[[frag]]\nbundle_adjust = {}\nmapproj = {}\n\n'''.format(
                ba,
                mp
            )
            frags = frags + frag

        with open(self.path, "w") as f:
            f.write(content + param + frags)
    
    def has_preproc_change(self, toml: DsmToml):
        """
        Check if the preprocessing parameters has change between a new toml and the lock.
        """
        return self.param["dem_utm"] == toml.run.dem_path and \
        self.param["gdal_out_res"] == toml.output.gdal_out_res and \
        self.param["utm"] == toml.output.utm and \
        self.param["resamp_m"] == toml.output.resamp_m and \
        self.param["session_type"] == toml.stereo.session_type and \
        self.param["resmp"] == toml.output.resmp


if __name__ == "__main__":
    pass