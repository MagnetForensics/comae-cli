# Comae Python

## Get the API key

`./comae.py --client-id clientIdHere --client-secret clientSecretHere get_api_key`

## Dump the memory with Comae DumpIt and upload to Comae Stardust

`./comae.py --client-id clientIdHere --cclient-secret clientSecretHere dump`

# Use as a Library

First, `import comae`

## Get the Comae Stardust API key

```
print(comae.getApiKey(client_id, client_secret))
```

## Acquire a memory image with Comae DumpIt
```
filename = comae.dumpIt()
print(filename)
```

## Upload the memory image to Comae Stardust
```
key = comae.getApiKey(client_id, client_secret)
comae.uploadFile(filename, key)
```
