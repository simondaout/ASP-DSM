import xml.etree.ElementTree as ET


def parse(file):
    tree = ET.parse(file)
    root = tree.getroot()
    return root

def get_file_names(root):
    names = [n.attrib['href'] for n in root.findall("./Raster_Data/Data_Access/Data_Files/Data_File/DATA_FILE_PATH")]
    return names

def get_time(root):
    time = root.find("./Geometric_Data/Use_Area/Located_Geometric_Values/TIME").text
    return time


if __name__ == "__main__":
    file = "/data/ARCHIVES/Nepal/Pleiades/7249972101/IMG_PHR1B_P_001/202501190507160.XML"
    root = parse(file)
    names = get_file_names(root)
    for n in names:
        print(n)
    time = get_time(root)
    print(time)
