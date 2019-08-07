# Comae Python

## Get the API key

`./comae.py --client-id clientIdHere --client-secret clientSecretHere --get-api-key`

## Upload to Comae Stardust
### Memory dump
`./comae.py --dump-it --action upload-comae --comae-client-id clientIdHere --comae-client-secret clientSecretHere`

### Memory dump from file path
`./comae.py --dump-it --action upload-comae --comae-client-id clientIdHere --comae-client-secret clientSecretHere --file-url fileUrlHere`

## Memory snapshot
`./comae.py --snap-it --action upload-comae --comae-client-id clientIdHere --comae-client-secret clientSecretHere`

### Memory snapshot from file path
`./comae.py --snap-it --action upload-comae --comae-client-id clientIdHere --comae-client-secret clientSecretHere --file-url fileUrlHere`

## Upload to a GCP Bucket
### Memory dump
`./comae.py --dump-it --action upload-gcp --gcp-creds-file /tmp/gcp_creds.json --bucket comae-dump` or
`GOOGLE_APPLICATION_CREDENTIALS=/tmp/gcp_creds.json ./comae.py --dump-it --action upload-gcp --bucket comae-dump`

### Memory snapshot
`./comae.py --snap-it --action upload-gcp --gcp-creds-file /tmp/gcp_creds.json --bucket comae-snap` or
`GOOGLE_APPLICATION_CREDENTIALS=/tmp/gcp_creds.json ./comae.py --snap-it --action upload-gcp --bucket comae-snap`

## Upload to a S3 Bucket
### Memory dump
`./comae.py --dump-it --action upload-gcp --gcp-creds-file /tmp/gcp_creds.json --bucket comae-dump`

### Memory snapshot
`./comae.py --snap-it --action upload-gcp --gcp-creds-file /tmp/gcp_creds.json --bucket comae-snap`

## Upload to an Azure bucket
### Memory dump
`./comae.py --dump-it --action upload-az --bucket comae-dump --az-account-name AzureAccountName --az-account-key base64EncodedKey`

### Memory snapshot
`./comae.py --snap-it --action upload-az --bucket comae-dump --az-account-name AzureAccountName --az-account-key base64EncodedKey`


# Use as a Library

First, `import comae, stardust_api`

## Get the Comae Stardust API key

```
print(stardust_api.getApiKey(client_id, client_secret))
```

## Acquire a memory image with Comae DumpIt
```
filename = comae.dumpIt()
print(filename)
```

## Upload the memory image to Comae Stardust
```
key = stardust_api.getApiKey(client_id, client_secret)
comae.uploadFile(filename, key)
```
