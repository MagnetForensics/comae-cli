import requests, os
from google.cloud import storage

def upload_gcp(gcp_bucket, filename):
    blobpath = "/comae/" + os.path.basename(filename)
    storage_client = storage.Client()
    bucket = storage_client.get_bucket(gcp_bucket)
    blob = bucket.blob(blobpath)
    blob.upload_from_filename(filename)
