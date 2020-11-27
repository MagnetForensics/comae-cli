
#!/usr/bin/env python3
#-------------------------------------------------------------------------------
# stardust_api.py
#
# Comae Stardust Python API
#
#-------------------------------------------------------------------------------

import requests, os, sys, math

# hostname = "api.comae.com"

def getApiKey(client_id, client_secret):
    print("[COMAE] Requesting Comae Stardust API key....")
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

def getOrganizations(key):
    headers = {"Authorization": "Bearer " + key}
    # Central API
    url = "https://api.comae.com/v1/venus/organizations"
    res = requests.get(url, headers=headers)
    result_json = res.json()

    print("     Organization Id           Name")
    print("     ---------------           ----")
    for org in result_json:
        print("     %s  %s" % (org["_id"], org["name"]))
    print("")

    return result_json

def getCases(key, hostname="api.comae.com"):
    headers = {"Authorization": "Bearer " + key}
    url = "https://api.comae.com/v1/venus/organizations"
    res = requests.get(url, headers=headers)
    orgs = res.json()

    cases = []

    for org in orgs:
        url = "https://%s/v1/cases?organizationId=%s" % (hostname, org["_id"])
        res = requests.get(url, headers=headers)
        result_json = res.json()
        for case in result_json:
            cases.append(case)

    print("     organizationId           _id                      name          description             creationDate             lastModificationDate     labels")
    print("     --------------           ---                      ----          -----------             ------------             --------------------     ------")
    for case in cases:
        # print(case)
        print("     %s %s %-13s %-23s %s %s %s" % (case["organizationId"], case["_id"], case["name"], case["description"], case["creationDate"], case["lastModificationDate"], ', '.join(case["labels"])))

    print("")

    return case

def sendSnapshotToComae(filename, key, organizationId, caseId, hostname="api.comae.com"):
    headers = {"Authorization": "Bearer " + key}
    url = "https://%s/v1/upload/json?organizationId=%s&caseId=%s" % (hostname, organizationId, caseId)
    files = {os.path.basename(filename): open(filename, "rb")}
    print("\r[COMAE] Uploading JSON archive to Comae Stardust...")
    res = requests.post(url, headers=headers, files=files)
    return res

def sendSnapshotUrlToComae(fileUrl, key, organizationId, caseId, hostname="api.comae.com"):
    headers = {"Authorization": "Bearer " + key}

    print("\r[COMAE] Sending snapshot file URL to Comae Stardust...")
    url = "https://%s/v1/upload/json/by-url?organizationId=%s&caseId=%s" % (hostname, organizationId, caseId)
    body = {"url": fileUrl}
    res = requests.post(url, headers=headers, json=body)

    if res.status_code != 200:
        print("Upload failed", file=sys.stderr)
        print(res.text, file=sys.stderr)
        exit(1)

    print("\n[COMAE] Upload complete!")

def sendDumpToComae(filename, key, organizationId, caseId, hostname="api.comae.com"):
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
            "https://%s/v1/upload/dump/chunks?chunkSize=%d&chunk=%d&id=%s&filename=%s&chunks=%d&organizationId=%s&caseId=%s"
            % (hostname, chunkSize, chunkNumber, uniqueId, filename, chunkCount, organizationId, caseId)
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

def sendDumpUrlToComae(fileUrl, key, organizationId, caseId, hostname="api.comae.com"):
    headers = {"Authorization": "Bearer " + key}

    print("\r[COMAE] Sending dump file URL to Comae Stardust...")
    url = "https://%s/v1/upload/dump/by-url?organizationId=%s&caseId=%s" % (hostname, organizationId, caseId)
    body = {"url": fileUrl}
    res = requests.post(url, headers=headers, json=body)

    if res.status_code != 200:
        print("Upload failed", file=sys.stderr)
        print(res.text, file=sys.stderr)
        exit(1)

    print("\n[COMAE] Upload complete!")

