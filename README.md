# Orbit Environment Sync

Container used for syncing/decrypting various environment files from cloud
storage to a folder on an instance.

### Features

 * Lean ~30MB container footprint
 * Uses rclone to sync, so many backends supported

### Usage

Have all of the environment files you want made available to your app
in a storage medium your instance can reach, defined as SOURCE_ENV.

Any source files encrypted with git-deploy's 'secret' command with a .secret
extension will arrive at the designation decrypted with extension stripped
so long as the needed GPG keys are present in the SOURCE_ENV as public.key and
private.key respectively.

Example:

```
docker run -e SOURCE_ENV="s3://some-bucket" -v config:/config pebbletech/orbit-env
```
