#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""
dsm_pleiades_new.py
___________________
Initialize the parameter file for ASP DSM

Usage: dsm_pleiades_new.py --preset=<preset>
dsm_pleiades_new.py -h | --help

Options:
--preset=<preset>       Choose preset for parameters. 

Available presets are: "default"
"""

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

class Preset:
    def __init__(self, preset: str):
        self.preset = preset
        self.avail = ["default", "mountain"]
        self.base_folder = os.path.dirname(__file__)

        if self.preset not in self.avail:
            raise ValueError("Invalid preset name")
    
    def path(self):
        return os.path.join(self.base_folder, "toml_presets", self.preset + ".toml")
    
    def name(self):
        return self.preset + ".toml"

def generate_toml(preset):
    preset = Preset(preset)
    target = "./asp_dsm_params.toml"
    sh("cp {} {}".format(
        preset.path(),
        target
    ))
    print("Successfully wrote {} in the working directory!".format(target))


def cli():
    arguments = docopt.docopt(__doc__)
    preset = arguments.get('--preset', 'default')

    generate_toml(preset)

if __name__ == "__main__":
    cli()
