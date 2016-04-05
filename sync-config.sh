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
	gpg2 --batch --import /config/private.key 2>/dev/null
fi
if [ ! -f /config/public.key ]; then
	echo "No public key found, unable to verify signatures"
else
	gpg2 --batch --import /config/public.key 2>/dev/null
fi

rm -f /config/public.key /config/private.key

gpg_template='-----BEGIN PGP MESSAGE-----\n\n%s\n\n-----END PGPMESSAGE-----\n'

find /config -type f -iname "*.secret" -print0 \
  | while IFS= read -r -d $'\0' file; do
		out_file=$(echo $file | sed 's/.secret$//g')
		printf -- "$gpg_template" $(cat $file) >> ${out_file}.gpg
		gpg2 --decrypt ${out_file}.gpg > ${out_file} 2> /dev/null
		rm ${out_file}.{gpg,secret}
done

find /config -type f -iname "*.env" -print0 \
| while IFS= read -r -d $'\0' file; do
	while IFS='' read -r line || [[ -n "$line" ]]; do
		if [[ "${line:0:1}" != "#" ]] && [[ "$line" == *"="* ]]; then
			key=${line%%=*}
			value=${line#*=}
			decrypted_value=$(
				printf -- "$gpg_template" "$value" | gpg2 -d 2>/dev/null
			)
			if [ "$?" -eq 0 ]; then
				echo ${decrypted_value} | grep -qi ^${key}=
				if [ "$?" -eq 0 ]; then
					echo $key=$decrypted_value >> ${file}.decrypted
				fi
			else
				echo $line >> ${file}.decrypted
			fi
		else
			echo $line >> ${file}.decrypted
		fi
	done < "$file"
done
