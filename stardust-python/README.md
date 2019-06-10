# Usage from CLI

## Get the API key

`./comae.py --client_id clientIdHere --client_secret clientSecretHere get_api_key`

## Dump memory and upload

`./comae.py --client_id clientIdHere --client_secret clientSecretHere dump`

# Usage as python library

First, `import comae`

## Get the api key

```
print(comae.get_api_key(client_id, client_secret))
```

## Generate the dump file
```
filename = comae.dump_it()
print(filename)
```

## Upload the dump file
```
key = comae.get_api_key(client_id, client_secret)
upload_file(filename, key)
```
