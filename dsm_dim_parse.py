import numpy as np
from osgeo import gdal
import os
import xml.etree.ElementTree as ET


class PleiadesDIM:
    """
    Usage:

    * dim = PleiadesDIM(path): the dim is parsed

    * dim.prepare(): the raw data is manipulated to ensure that a global .TIF is available

    /!\ While creating the dim only parse, so only read the data, prepare can actually write in your raw data folder
    """
    def __init__(self, path):
        self.dim_path = path
        self.folder = os.path.dirname(path)
        self.img_paths = []
        self.img_tif = ""
        self.bbox = []
        self.area = 0
        self.cloud_coverage = 0
        self.snow_coverage = 0
        # self.sencor_crs = ""
        # self.nodata = 0
        # following can be center, bottom center, top center
        # here choose top center (first)
        self.acquisition_time = ""
        self.azimuth_angle = 0
        self.viewing_angle = 0
        self.incidence_angle = 0

        self._parse_dim()

    def _parse_dim(self):
        """
        Parse the XML to harvest data on the acquisition.

        Read only, do not write in RAW data.
        """
        root = parse_xml(self.dim_path)

        metadata_version = root.find("./Metadata_Identification/METADATA_FORMAT").attrib["version"]
        if metadata_version != "2.15":
            print("warning: new metadata version might not be supported")

        copyright = root.find("./Dataset_Identification/Legal_Constraints/COPYRIGHT").text
        print("Copyright:", copyright)

        self.area = float(root.find("./Dataset_Content/SURFACE_AREA").text)
        try:
            self.cloud_coverage = float(root.find("./Dataset_Content/CLOUD_COVERAGE").text)
        except:
            self.cloud_coverage = None
        try:
            self.snow_coverage = float(root.find("./Dataset_Content/SNOW_COVERAGE").text)
        except:
            self.snow_coverage = None

        bbox_polygon = root.findall("./Dataset_Content/Dataset_Extent/Vertex")
        bbox_points = []
        for b in bbox_polygon:
            bbox_points.append([float(b.find("./LON").text), float(b.find("./LAT").text)])
        self.bbox = points_to_bbox(bbox_points)
        print(self.bbox)

        center = root.find("./Geometric_Data/Use_Area/Located_Geometric_Values")
        self.acquisition_time = center.find("./TIME").text
        self.azimuth_angle = center.find("./Acquisition_Angles/AZIMUTH_ANGLE").text
        self.viewing_angle = center.find("./Acquisition_Angles/VIEWING_ANGLE").text
        self.incidence_angle = center.find("./Acquisition_Angles/INCIDENCE_ANGLE").text

        self.img_paths = [d.find("DATA_FILE_PATH").get("href") for d in root.findall("./Raster_Data/Data_Access/Data_Files/Data_File")]
        print(self.img_paths)

    def img_tif(self):
        return self.img_tif
    
    def bbox(self):
        return self.bbox
    
    def _merge_tiles_tif(self):
        """
        Merge all tiles if the image is split in multiple parts, and convert into .TIF

        /!\ Write in Raw data
        """
        # TODO test gdal arguments !!!!!!
        not_implemented()
        
        vrt = os.path.join(self.folder, "vrt.tif")
        dst = self.img_tif
        if len(self.img_paths) == 0 and os.path.splitext(self.img_paths[0])[1] != ".TIF":
            dst = os.path.splitext(self.img_paths[0])[0] + ".TIF"
        gdal.BuildVRT(vrt, self.img_paths)
        gdal.Translate(dst, vrt, options=["TILED=YES", "BLOCKXSIZE=256", "BLOCKYSIZE=256", "BIGTIFF=IF_SAFER"])
        os.remove(vrt)
    
    def _check_already_prepared(self):
        if len(self.img_paths) == 1:
            # use the existing file
            self.img_tif = os.path.splitext(self.img_paths[0])[0] + ".TIF"
        elif len(self.img_paths) > 1:
            # abstract on the R_C_
            self.img_tif = os.path.splitext(self.img_paths[0])[0][:-5] + ".TIF"
        os.path.isfile(os.path.join(self.folder, self.img_tif))
    
    def prepare(self):
        """
        /!\ Write in Raw data
        """
        if not self._check_already_prepared():
            # Doesnt run if already prepared...
            self._ensure_tif()
            if len(self.img_paths) > 1:
                self._merge_tiles_tif()


def parse_xml(file):
    """
    Parse an XML file into a root element

    :param file: path to the xml to parse
    :returns root: the root xml object
    """
    tree = ET.parse(file)
    root = tree.getroot()
    return root


def points_to_bbox(points: list):
    """
    Convert a list of points (x, y) into a bbox, i.e retrieve the min max on each axis

    :param points: (N, 2) list of float / integer. Can be (lat, long), (x, y), ...
    :returns bbox: bounding box [x_min, x_max, y_min, y_max]
    """
    min = np.min(points, axis=0)
    max = np.max(points, axis=0)
    return [min[0], max[0], min[1], max[1]]


def not_implemented():
    raise NotImplementedError("not implemented...\n\n\t(ㅠ﹏ㅠ)\n")

if __name__ == "__main__":
    dim_test = "./test/7249969101/IMG_PHR1B_P_001/DIM_PHR1B_P_202501190507246_SEN_7249969101-1.XML"
    dim = PleiadesDIM(dim_test)
