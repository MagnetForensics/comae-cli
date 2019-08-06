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