#!/usr/bin/env python3
#-------------------------------------------------------------------------------
# stardust_api.py
#
# Comae Stardust Python API - Utils
#
#-------------------------------------------------------------------------------

import os, zipfile

def isRoot():
    return os.getuid() == 0

def createZip(filename):
    # allowZip64 to allow for > 4 GB zip files
    zip_f = zipfile.ZipFile(
        filename + ".zip", mode="w", compression=zipfile.ZIP_DEFLATED, allowZip64=True
    )
    zip_f.write(filename)
    zip_f.close()

def checkAllArgsExist(args, required_args):
    for required_arg in required_args:
        if getattr(args, required_arg) == None:
            return False
    
    return True