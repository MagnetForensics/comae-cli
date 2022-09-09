
#!/usr/bin/env python3
# -------------------------------------------------------------------------------
# stardust_api.py
#
# Comae Stardust Python API
#
# -------------------------------------------------------------------------------

from time import sleep
import requests
import os
import sys
import math
import uuid

# hostname = "beta.comae.tech"


def getOrganizations(key, hostname="beta.comae.tech"):
    headers = {"Authorization": "Bearer " + key}
    # Central API
    url = "https://" + hostname + "/api/organizations"
    res = requests.get(url, headers=headers)
    result_json = res.json()

    print("     Organization Id           Name")
    print("     ---------------           ----")
    for org in result_json:
        print("     %s  %s" % (org["id"], org["name"]))
    print("")

    return result_json


def getCases(key, organizationId, hostname="beta.comae.tech"):
    headers = {"Authorization": "Bearer " + key}

    url = "https://%s/api/cases?organizationId=%s" % (hostname, organizationId)
    res = requests.get(url, headers=headers)
    cases = res.json()

    print("     organizationId           id                      name          description             creationDate             lastModificationDate     labels")
    print("     --------------           ---                      ----          -----------             ------------             --------------------     ------")
    for case in cases:
        # print(case)
        print("     %s %s %-13s %-23s %s %s %s" % (case["organizationId"],
              case["id"], case["name"], case["description"], case["createdAt"], case["updateAt"], case["labels"]))

    print("")


def sendSnapshotToComae(filename, key, organizationId, caseId, hostname="beta.comae.tech"):
    headers = {"Authorization": "Bearer " + key}
    url = "https://%s/v1/upload-json?organizationId=%s&caseId=%s" % (
        hostname, organizationId, caseId)
    files = {os.path.basename(filename): open(filename, "rb")}
    print("\r[COMAE] Uploading JSON archive to Comae Stardust...")
    res = requests.post(url, headers=headers, files=files)
    return res


def sendSnapshotUrlToComae(fileUrl, key, organizationId, caseId, hostname="beta.comae.tech"):
    headers = {"Authorization": "Bearer " + key}

    print("\r[COMAE] Sending snapshot file URL to Comae Stardust...")
    url = "https://%s/v1/upload/json-by-url?organizationId=%s&caseId=%s" % (
        hostname, organizationId, caseId)
    body = {"url": fileUrl}
    res = requests.post(url, headers=headers, json=body)

    if res.status_code != 200:
        print("Upload failed", file=sys.stderr)
        print(res.text, file=sys.stderr)
        exit(1)

    print("\n[COMAE] Upload complete!")


def upload(file, fileSize, hostname, key, chunkNumber, originalname, chunkCount, organizationId, caseId, ticketId, bufferSize, offset, retryCount):
    for chunkNumber in range(chunkNumber, chunkCount + 1):
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
            "https://%s/v1/upload-parts?chunkSize=%d&chunk=%d&originalname=%s&total=%d&organizationId=%s&caseId=%s&ticketId=%s"
            % (hostname, chunkSize, chunkNumber-1, originalname, chunkCount, organizationId, caseId, ticketId)
        )

        contentRange = (
            "bytes %d-%d/%d"
            % (chunkNumber * chunkSize,
               min(fileSize, (chunkNumber+1)*chunkSize),
               fileSize)
        )

        form_data = {
            "file": chunk
        }

        data = {
            "ticketId": ticketId,
            "organizationId": organizationId,
            "caseId": caseId
        }

        headers = {"Authorization": "Bearer " +
                   key, "Content-Range": contentRange}

        res = requests.post(url, headers=headers, files=form_data, data=data)

        if res.status_code != 200:
            if retryCount > 5:
                print("Upload failed", file=sys.stderr)
                exit(1)
            else:
                sleep(60)
                upload(file=file, fileSize=fileSize, hostname=hostname, key=key, chunkNumber=chunkNumber, originalname=originalname, chunkCount=chunkCount,
                       organizationId=organizationId, caseId=caseId, ticketId=ticketId, bufferSize=bufferSize, offset=offset, retryCount=retryCount+1)
        retryCount = 0
        offset += chunkSize


def sendDumpToComae(filename, key, organizationId, caseId, hostname="beta.comae.tech"):
    file = open(filename, "rb")
    fileSize = os.path.getsize(filename)
    bufferSize = 32 * 1024 * 1024
    chunkCount = int(math.ceil(fileSize / bufferSize))
    ticketId = uuid.uuid4()
    originalname = os.path.basename(filename)

    offset = 0

    upload(file=file, fileSize=fileSize, hostname=hostname, key=key, chunkNumber=1, originalname=originalname, chunkCount=chunkCount,
           organizationId=organizationId, caseId=caseId, ticketId=ticketId, bufferSize=bufferSize, offset=offset, retryCount=0)

    print("\n[COMAE] Upload complete!")


def sendDumpUrlToComae(fileUrl, key, organizationId, caseId, hostname="beta.comae.tech"):
    headers = {"Authorization": "Bearer " + key}

    print("\r[COMAE] Sending dump file URL to Comae Stardust...")
    url = "https://%s/v1/upload/dump-by-url?organizationId=%s&caseId=%s" % (
        hostname, organizationId, caseId)
    body = {"url": fileUrl}
    res = requests.post(url, headers=headers, json=body)

    if res.status_code != 200:
        print("Upload failed", file=sys.stderr)
        print(res.text, file=sys.stderr)
        exit(1)

    print("\n[COMAE] Upload complete!")
