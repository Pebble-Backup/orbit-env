#!/bin/bash

sed -i "s/__AWS_REGION__/$AWS_REGION/g" .rclone.conf.template
cp /home/orbit/.rclone.conf{.template,}

[ -z "${ENV_SOURCE}" ] && echo "No ENV_SOURCE URI specified" && exit

if [[ "$ENV_SOURCE" == "s3://"* ]]; then
	rclone sync s3:${ENV_SOURCE#s3://} /config
elif [[ "$ENV_SOURCE" == "file://"* ]]; then
	cp -R ${ENV_SOURCE#file://} /config
else
	echo "ENV_SOURCE URI not defined or invalid"
	exit
fi

if [ ! -f /config/private.key ]; then
	echo "No private key found, unable to decrypt"
else
	gpg2 --import /config/private.key 2>/dev/null
fi
if [ ! -f /config/public.key ]; then
	echo "No public key found, unable to verify signatures"
else
	gpg2 --import /config/public.key 2>/dev/null
fi

rm -f /config/public.key /config/private.key

gpg_template='-----BEGIN PGP MESSAGE-----\n\n%s\n-----END PGPMESSAGE-----\n'
find /config -type f -iname "*.secret" -print0 \
  | while IFS= read -r -d $'\0' file; do
	local out_file=$(echo $file | sed 's/.secreti$//g')
	printf -- $gpg_template $(cat $file) | gpg2 --decrypt > $out_file
done

