import xml.etree.ElementTree as ET


def parse(file):
    """
    Parse an XML file into a root element
    """
    tree = ET.parse(file)
    root = tree.getroot()
    return root


def get_file_names(root):
    names = [n.attrib['href'] for n in root.findall("./Raster_Data/Data_Access/Data_Files/Data_File/DATA_FILE_PATH")]
    return names


def get_time(root):
    """
    Find the acquisition time of a Pleiades image from the root of its DIM XML file
    """
    time = root.find("./Geometric_Data/Use_Area/Located_Geometric_Values/TIME").text
    return time


def sort_by_time(names, times):
    """
    Sort entry names from their acquisition times.
    The times elements should have the '__lt__' ('<') operator implemented.
    """
    return [n for _, n in sorted(zip(times, names), key=lambda pair: pair[0])]


class Time:
    """
    Read and compare the time format of the Pleiades DIM
    """
    def __init__(self, time):
        """
        Initilalize the class from the string of the Pleiades DIM time's format
        """
        date, hour = time[:-1].split('T')
        self.y, self.m, self.d = [int(k) for k in date.split('-')]
        h, minu, self.sec = [float(k) for k in hour.split(':')]
        self.h, self.min = int(h), int(minu)
    
    def __lt__(self, other):
        """
        Compare two dates (less than).
        Boolean as result. Fonction can be used with the '<' operator.
        """
        self_time = [self.y, self.m, self.d, self.h, self.min, self.sec]
        other_time = [other.y, other.m, other.d, other.h, other.min, other.sec]

        for k in range(len(self_time)):
            if self_time[k] < other_time[k]:
                return True
            elif self_time[k] > other_time[k]:
                return False
            # Otherwise the number is equal, check the next one
        # times are equal, so not strictly less than
        return False
    
    def time(self):
        return f"{self.y:04}-{self.m:02}-{self.d:02}T{self.h:02}:{self.min:02}:{self.sec:02}Z"

def sort_in_file(file, target_folder):
    dates = []
    folders = []
    names_sorted = []

    with open(file, 'r') as in_file:
        for line in in_file:
            l_split = line.split()
            dates.append(l_split[::2])
            folders.append(l_split[1::2])

    for p in range(len(dates)):
        times = []
        for i in range(len(dates[p])):
            xml_file = glob.glob(target_folder + "/" + folders[p] + "/" + "IMG*P*/DIM*.XML")
            root = parse(xml_file)
            times.append(Time(get_time(root)))
        # loop on pairs pls
        names = [f"{d} {f}" for d, f in zip(dates[p], folder[p])]
        names_sorted.append(sort_by_time(names, times))

    with open(file, 'w') as out_file:
        for p in names_sorted:
            line = ""
            for el in p:
                line += el + " "
            out_files.write(line[::-1] + "\n")
    print("done")


if __name__ == "__main__":
    file = "/data/ARCHIVES/Nepal/Pleiades/7249972101/IMG_PHR1B_P_001/202501190507160.XML"
    root = parse(file)
    names = get_file_names(root)
    for n in names:
        print(n)
    time = get_time(root)
    time1 = Time(time)
    time2 = Time("2025-01-19T05:08:22.456Z")
    time3 = Time("2025-01-19T04:58:22.456Z")

    print(time1.time(), time2.time(), time1 < time2)
    print(time1.time(), time3.time(), time1 < time3)
    print(time3.time(), time2.time(), time3 < time2)

    sorted_t = sort_by_time(["t1", "t2", "t3"], [time1, time2, time3])

    print(sorted_t)

    print("----")

    list_p = "/home/leo/ASP-DSM/test/list_pair.txt"
    target = "/home/leo/ASP-DSM/test"
    sort_in_file(list_p, target)
