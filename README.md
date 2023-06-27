# ASP-playground
Processing tool package written in bash, python, and Gdal programming language for DSM generation from stereo Pleiades images, and using the AMES stereo toolbox (https://stereopipeline.readthedocs.io/en/latest/).

To download the package
=============
```git clone https://github.com/simondaout/ASP-DSM.git```

To update the software:
```git pull```

In case of fire:
```
git commit
git push
leave building
```

How to use it
=============
1) download SRTM or Copernicus DSM in your area and refer it to WGS84
2) edit asp_parameter.txt file (example available in example directory)
3) edit pair list file (example available in example directory): list_pairs.txt
4) run orthorectification and stereo: launch_stereo_pleiades.sh  -n list_pairs.txt
5) run post-processing check: check_process.sh list_pair.txt
6) run mosaic multispectral images: launch_MS_pleiades.sh -n list_pairs.txt

Installation
=============
* The majortiy of the scripts are written in bash and python and do not need installation. Just add them to your PATH. If you are using module, an example of modulefile is available in /contrib/modulefile/asp-dsm

Developpers & Contact
=============
```
Florian Leder : lg18102@hs-nb.de
```

```
Simon Daout: simon.daout@univ-lorraine.fr
Associate Professor, CRPG, NANCY
```

 
