# ASP-playground
Processing tool package written in bash, python, and Gdal programming language for DSM generation from stereo Pleiades images, and using the AMES stereo toolbox (https://stereopipeline.readthedocs.io/en/latest/).

![Alt text](logo-pnts.jpg)

The present usage generates DSM using the ASP toolchain. It handles the Pleiades images ditribution variability, fetching DEM, stereo of two or three images, merging of neighboring images.

## To download the package

```git clone https://github.com/simondaout/ASP-DSM.git```

To update the software:
```git pull```

In case of fire:
```
git commit
git push
leave building
```

## Installation

* The majortiy of the scripts are written in bash and python and do not need installation. Just add them to your PATH. If you are using module, an example of modulefile is available in /contrib/modulefile/asp-dsm

* Dependencies: pygdalsar, nsbas, asp


## How to use it

1) Download a pleiades image and unzip the folder
2) Generate a parameter file and fill parameters' of interest and project-related parameters
3) Launch the command with the parameter file path indicated

## Developpers & Contact

* `Florian Leder : lg18102@hs-nb.de`
* `Simon Daout: simon.daout@univ-lorraine.fr, Ass. Prof., CRPG, NANCY`
* `Leo Letellier: leo.letellier@univ-lorraine.fr, PhD Student, CRPG, NANCY`

 
