
#!/usr/bin/env python3
#-------------------------------------------------------------------------------
# comae.py
#
# Comae Stardust Python CLI
#
#-------------------------------------------------------------------------------

from __future__ import print_function
import requests, time, subprocess, argparse, sys, os
import cloud_upload, util, stardust_api


def dumpIt():
    if not util.isRoot():
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
    util.createZip(filename)
    # subprocess.call(["zip", '-0', filename + ".zip", filename])

    print('[COMAE] Removing memory image file "' + filename + '"')
    os.remove(filename)

    return filename + ".zip"

def createLiveSnapshot():
    if not util.isRoot():
        print("Program must be run as root", file=sys.stderr)
        exit(1)

    current_time = time.strftime("%Y%m%d-%H%M%S")
    kernel_release = os.uname()[2]
    filename = kernel_release + "." + current_time + ".live-comae"

    mem2jsonIt_path = os.path.dirname(os.path.realpath(__file__)) + "/Mem2Json"

    print('[COMAE] Saving memory image as "' + filename + '"')
    subprocess.call([mem2jsonIt_path, "--live", "--out", filename])

    return filename + ".json.zip"

def handle_file(file, args, filetype):
    if args.action == "store":
        pass # we already have the file stored
    
    if args.action == "upload-comae":
        if not args.comae_client_secret or not args.comae_client_id:
            print("Provide client_secret and client_id", file=sys.stderr)
            exit(1)

        print("[COMAE] Requesting Comae Stardust API key....")
        api_key = stardust_api.getApiKey(args.comae_client_id, args.comae_client_secret)
        print("[COMAE] Uploading file to Comae Stardust")

        if filetype == "dump":
            if args.file_url:
                stardust_api.sendDumpUrlToComae(file, api_key)
            else:
                stardust_api.sendDumpToComae(file, api_key)

        if filetype == "snap":
            if args.file_url:
                stardust_api.sendSnapshotUrlToComae(file, api_key)
            else:
                stardust_api.sendSnapshotToComae(file, api_key)

        print("[COMAE] Uploaded to Comae Stardust")
    
    if args.action == "upload-gcp":
        fail = False
        if not "GOOGLE_APPLICATION_CREDENTIALS" in os.environ and not "gcp_creds_file" in args:
            print("Please provide path to gcloud creds with --gcp-creds-file or set the GOOGLE_APPLICATION_CREDENTIALS env var.")
            fail = True
        
        if not "bucket" in args:
            print("Please provice a bucket name with --bucket")
            fail = True

        
        if "gcp_creds_file" in args:
            os.environ['GOOGLE_APPLICATION_CREDENTIALS'] = args.gcp_creds_file
        
        if not os.path.exists(os.environ['GOOGLE_APPLICATION_CREDENTIALS']):
            print(f"[COMAE] GCP creds file {os.environ['GOOGLE_APPLICATION_CREDENTIALS']} does not exist")

        if fail:
            exit(1)

        cloud_upload.upload_gcp(args.bucket, file)
        print("[COMAE] Uploaded to GCP bucket")

    if args.action == "upload-az":
        fail = False
        if not "az_account_name" in args or not "az_account_key" in args:
            print("Please provide --az-account-name and --az-account-key")
            fail = True

        if not "bucket" in args:
            print("Please provide a bucket name with --bucket")
            fail = True

        if fail:
            exit(1)

        cloud_upload.upload_az(args.az_account_name, args.az_account_key, args.bucket, filename)
        print("[COMAE] Uploaded to Azure")

    if args.action == "upload-s3":
        fail = False
        if not "aws_access_id" in args or not "aws_access_secret" in args:
            print("Please provide --aws-access-id and --aws-access-secret")
            fail = True

        if not "bucket" in args:
            print("Please provide a bucket name with --bucket")
            fail = True

        if fail:
            exit(1)

        cloud_upload.upload_s3(args.aws_access_id, args.aws_access_secret,  args.bucket, filename)
        print("[COMAE] Uploaded to S3")
        

if __name__ == "__main__":
    argparser = argparse.ArgumentParser(description="Comae Stardust Client")
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
    argparser.add_argument("--action", help='One of "store", "upload-comae", "upload-gcp", "upload-az", "upload-s3"', default="store")
    argparser.add_argument("--file-url", help="URL of a dump/snapshot file. The tool will not upload the local file if it is specified.")
    argparser.add_argument("--bucket", help="Name of bucket to use if uploading to GCP / Azure / S3")
    argparser.add_argument("--comae-client-id", help="Comae Client ID if uploading to Comae Stardust")
    argparser.add_argument("--comae-client-secret", help="Comae Client Secret if uploading to Comae Stardust")
    argparser.add_argument("--gcp-creds-file", help="Path to file containing GCP credentials, if uploading to GCP")
    argparser.add_argument("--az-account-name", help="Account name if uploading to Azure")
    argparser.add_argument("--az-account-key", help="Account key if uploading to Azure")
    argparser.add_argument("--aws-access-id", help="AWS access key ID")
    argparser.add_argument("--aws-access-secret", help="AWS access key secret")
    args = argparser.parse_args()

    if not args.get_api_key and not args.dump_it and not args.snap_it:
        argparser.print_help()
        exit(1)

    if not args.action and not args.get_api_key:
        print("[COMAE] No action provided. Please provide an action.")
        argparse.print_help()
        exit(1)

    if args.get_api_key:
        print(stardust_api.getApiKey(args.client_id, args.client_secret))

    elif args.dump_it:
        if not util.checkAllArgsExist(args, ['action']):
            print("[COMAE] Please provide an action.")
            exit(1)
        if args.file_url:
            handle_file(args.file_url, args, "dump")
        else:
            print("[COMAE] Acquiring the memory image with Comae DumpIt...")
            filename = dumpIt()
            handle_file(filename, args, "dump")

    elif args.snap_it:
        if not util.checkAllArgsExist(args, ['action']):
            print("[COMAE] Please provide an action.")
            exit(1)
        if args.file_url:
            handle_file(args.file_url, args, "snap")
        else:
            filename = createLiveSnapshot()
            handle_file(filename, args, "snap")
