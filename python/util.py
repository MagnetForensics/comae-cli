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

def createZip(*filenames):
    # allowZip64 to allow for > 4 GB zip files
    zip_f = zipfile.ZipFile(
        filenames[0] + ".zip", mode="w", compression=zipfile.ZIP_DEFLATED, allowZip64=True
    )
    for filename in filenames:
        zip_f.write(filename)
    zip_f.close()

def checkAllArgsExist(args, required_args):
    for required_arg in required_args:
        if getattr(args, required_arg) == None:
            return False
    
    return True