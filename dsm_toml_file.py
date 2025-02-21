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

    def lock_at(self, path):
        pass


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
        self.bundle_asjust = dic.get("bundle_adjust", True)
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
    def __init__(self):
        self.path = None

        self.name = ""
        self.dem = ""
        self.frags = [] # array of (bool, bool)

    def new(self, toml: DsmToml, lock_path):
        self.path = lock_path
        frag_nb = len(toml.sources)
        
        self.name = toml.run.name
        self.frags = [[False, False] for _ in range(frag_nb)]
        self.write_lock()
        return self

    def open(self, lock_path):
        self.path = lock_path
        lock = parse_toml(lock_path)

        self.name = lock["lock"]["name"]
        self.dem = lock["lock"]["dem_utm"]

        frags = lock["frag"]
        for f in frags:
            self.frags.append([f["bundle_adjust"], f["mapproj"]])
        
        return self
    
    def lock_dem(self, dem_utm_path):
        # add dem to lock
        self.dem = dem_utm_path
        self.write_lock()
    
    def is_dem_lock(self):
        return len(self.dem) != 0
    
    def lock_ba(self, frag_nb):
        self.frags[frag_nb][0] = True
        self.write_lock()

    def is_ba_lock(self, frag_nb):
        return self.frags[frag_nb][0]
    
    def lock_mp(self, frag_nb):
        self.frags[frag_nb][1] = True
        self.write_lock()

    def is_mp_lock(self, frag_nb):
        return self.frags[frag_nb][1]

    def write_lock(self):
        # hardcoded because tomli_w currently not installed on server
        content = '''[lock]\nname = "{}"\ndem_utm = "{}"\n\n'''.format(
            self.name,
            self.dem
        )

        frags = ""
        for k in range(len(self.frags)):
            ba = "true" if self.frags[k][0] else "false"
            mp = "true" if self.frags[k][1] else "false"
            frag = '''[[frag]]\nbundle_adjust = {}\nmapproj = {}\n'''.format(
                ba,
                mp
            )
            frags = frags + frag

        with open(self.path, "w") as f:
            f.write(content + frags)


class DsmParamLock:
    def __init__(self):
        pass

if __name__ == "__main__":
    pass