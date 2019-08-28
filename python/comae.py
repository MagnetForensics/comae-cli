#!/usr/bin/env python3
from __future__ import print_function
import requests, os, time, subprocess, argparse, math, sys, zipfile

hostname = "api.comae.com"

def getApiKey(client_id, client_secret):
    body = {
        "grant_type": "client_credentials",
        "client_id": client_id,
        "client_secret": client_secret,
        "audience": "JHYFRulOwjLslg87tUt4bCT8i4O3yBsm",
    }

    uri = "https://comae.auth0.com/oauth/token"

    result = requests.post(uri, json=body)
    result_json = result.json()

    if "access_token" not in result_json:
        print("Failed to get api key", file=sys.stderr)
        print(result_json, file=sys.stderr)
        exit(1)

    return result_json["access_token"]

def sendSnapshotToComae(filename, key):
    headers = {"Authorization": "Bearer " + key}
    url = "https://" + hostname + "/v1/upload/json"
    files = {os.path.basename(filename): open(filename, "rb")}
    print("\r[COMAE] Uploading JSON archive to Comae Stardust...")
    res = requests.post(url, headers=headers, files=files)

def sendSnapshotUrlToComae(fileUrl, key):
    global hostname

    headers = {"Authorization": "Bearer " + key}

    print("\r[COMAE] Sending snapshot file URL to Comae Stardust...")
    url = "https://%s/v1/upload/json/by-url" % (hostname)
    body = {"url": fileUrl}
    res = requests.post(url, headers=headers, json=body)

    if res.status_code != 200:
        print("Upload failed", file=sys.stderr)
        print(res.text, file=sys.stderr)
        exit(1)

    print("\n[COMAE] Upload complete!")

def sendDumpToComae(filename, key):
    global hostname

    file = open(filename, "rb")
    fileSize = os.path.getsize(filename)
    bufferSize = 32 * 1024 * 1024
    chunkCount = int(math.ceil(fileSize / bufferSize))
    uniqueId = str(fileSize) + "-" + filename

    headers = {"Authorization": "Bearer " + key}

    offset = 0
    for chunkNumber in range(1, chunkCount + 1):
        # '\033[1A' moves the cursor up one line, because passing `end=""` to print
        # to strip the newline doesn't want to work here on python2
        status_string = "\r[COMAE] Uploading %d / %d chunks \033[1A" % (
            chunkNumber,
            chunkCount,
        )
        print(status_string)
        chunk = file.read(bufferSize)
        # When it's the last chunk the size can be smaller than the buffer
        chunkSize = len(chunk)
        url = (
            "https://%s/v1/upload/dump/chunks?chunkSize=%d&chunk=%d&id=%s&filename=%s&chunks=%d"
            % (hostname, chunkSize, chunkNumber, uniqueId, filename, chunkCount)
        )

        form_data = {
            "filename": (
                None,
                filename,
            ),  # Tuple of (filename, content, content type, dict of headers), we don't want a filename
            "file": (filename, chunk, "application/octet-stream"),
        }

        res = requests.post(url, headers=headers, files=form_data)

        if res.status_code != 200:
            print("Upload failed", file=sys.stderr)
            print(res.text, file=sys.stderr)
            exit(1)

        offset += chunkSize

    upload_complete_url = "https://%s/v1/upload/dump/completed" % (hostname)
    upload_details = {"id": uniqueId, "filename": filename, "chunks": chunkCount}

    res = requests.post(upload_complete_url, headers=headers, json=upload_details)

    print("\n[COMAE] Upload complete!")

def sendDumpUrlToComae(fileUrl, key):
    global hostname

    headers = {"Authorization": "Bearer " + key}

    print("\r[COMAE] Sending dump file URL to Comae Stardust...")
    url = "https://%s/v1/upload/dump/by-url" % (hostname)
    body = {"url": fileUrl}
    res = requests.post(url, headers=headers, json=body)

    if res.status_code != 200:
        print("Upload failed", file=sys.stderr)
        print(res.text, file=sys.stderr)
        exit(1)

    print("\n[COMAE] Upload complete!")


def isRoot():
    return os.getuid() == 0


def createZip(filename):
    # allowZip64 to allow for > 4 GB zip files
    zip_f = zipfile.ZipFile(
        filename + ".zip", mode="w", compression=zipfile.ZIP_DEFLATED, allowZip64=True
    )
    zip_f.write(filename)
    zip_f.close()


def dumpIt():
    if not isRoot():
        print("Program must be run as root", file=sys.stderr)
        exit(1)

    current_time = time.strftime("%Y%m%d-%H%M%S")
    kernel_release = os.uname()[2]
    filename = kernel_release + "." + current_time + ".dumpit" + ".core"

    # This way we can run the script from another path, we don't have to be in
    # the directory containing DumpIt
    dumpIt_path = os.path.dirname(os.path.realpath(__file__)) + "/DumpIt"

    print('[COMAE] Saving memory image as "' + filename + '"')
    subprocess.call([dumpIt_path, filename])

    print('[COMAE] Compressing image as "' + filename + '.zip"')
    createZip(filename)
    # subprocess.call(["zip", '-0', filename + ".zip", filename])

    print('[COMAE] Removing memory image file "' + filename + '"')
    os.remove(filename)

    return filename + ".zip"

def createLiveSnapshot():
    if not isRoot():
        print("Program must be run as root", file=sys.stderr)
        exit(1)

    current_time = time.strftime("%Y%m%d-%H%M%S")
    kernel_release = os.uname()[2]
    filename = kernel_release + "." + current_time + ".live-comae"

    mem2jsonIt_path = os.path.dirname(os.path.realpath(__file__)) + "/Mem2Json"

    print('[COMAE] Saving memory image as "' + filename + '"')
    subprocess.call([mem2jsonIt_path, "--live", "--out", filename])

    return filename + ".json.zip"

if __name__ == "__main__":
    argparser = argparse.ArgumentParser(description="Comae Stardust Client")
    argparser.add_argument("--client-id", help="Client ID")
    argparser.add_argument("--client-secret", help="Client Secret")
    argparser.add_argument(
        "-k", "--get-api-key", action="store_true", help="Get Comae Stardust API Key"
    )
    argparser.add_argument(
        "-d",
        "--dump-it",
        action="store_true",
        help="Dump with Comae DumpIt and send to Comae Stardust",
    )
    argparser.add_argument(
        "-s",
        "--snap-it",
        action="store_true",
        help="Dump Mem2Json and send to Comae Stardust",
    )
    argparser.add_argument("--send-to-comae", action="store_true")
    argparser.add_argument("--send-to-az", action="store_true")
    argparser.add_argument("--send-to-aws", action="store_true")
    argparser.add_argument("--file-url", help="URL of a dump/snapshot file. The tool will not upload the local file if it is specified.")
    args = argparser.parse_args()

    if not args.get_api_key and not args.dump_it and not args.snap_it:
        argparser.print_help()
        exit(1)

    if not args.client_secret or not args.client_id:
        print("Provide client_secret and client_id", file=sys.stderr)
        exit(1)

    if args.get_api_key:
        print(getApiKey(args.client_id, args.client_secret))

    elif args.dump_it:
        print("[COMAE] Requesting Comae Stardust API key....")
        api_key = getApiKey(args.client_id, args.client_secret)
        if args.file_url:
            sendDumpUrlToComae(args.file_url, api_key)
        else:
            print("[COMAE] Acquiring the memory image with Comae DumpIt...")
            filename = dumpIt()
            print(
                "[COMAE] Uploading the core dump generated by Comae DumpIt to Comae Stardust...."
            )
            sendDumpToComae(filename, api_key)

    elif args.snap_it:
        print("[COMAE] Requesting Comae Stardust API key....")
        api_key = getApiKey(args.client_id, args.client_secret)
        if args.file_url:
            sendSnapshotUrlToComae(args.file_url, api_key)
        else:
            filename = createLiveSnapshot()
            print(
                "[COMAE] Uploading the JSON snapshot generated by Comae Mem2Json to Comae Stardust...."
            )
            sendSnapshotToComae(filename, api_key)
