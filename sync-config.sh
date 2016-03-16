#!/bin/sh

[ -z "${ENV_SOURCE}" ] && echo "No ENV_SOURCE URI specified"; exit

if [[ "$ENV_SOURCE" == "s3://"* ]]; then
	rclone s3:${ENV_SOURCE#s3://} /config
elif [[ "$ENV_SOURCE" == "file://"* ]]; then
	cp -R ${ENV_SOURCE#file://} /config
else
	echo "ENV_SOURCE URI not defined or invalid"
	exit
fi

if [ ! -f /config/keys/private.key ]; then
	echo "No private key found, unable to decrypt"
fi
if [ ! -f /config/keys/public.key ]; then
	echo "No public key found, unable to verify signatures"
fi
gpg2 --import /config/keys/private.key 2>/dev/null
gpg2 --import /config/keys/public.key 2>/dev/null
rm -rf /config/keys

# Begin decryption operations here before exiting
