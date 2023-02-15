#!/usr/bin/env bash

set -o errexit

# shellcheck source=get-config.sh
. .scripts/get-config.sh

# The $SSH_ env variables are provided by GitHub secret


[[ -z "$SSH_USER" ]] && echo "SSH_USER not set" && exit 1
[[ -z "$SSH_HOST" ]] && echo "SSH_HOST not set" && exit 1
[[ -z "$SSH_PRIVATE_KEY" ]] && echo "SSH_PRIVATE_KEY not set" && exit 1
[[ -z "$SSH_KNOWN_HOSTS" ]] && echo "SSH_KNOWN_HOSTS not set" && exit 1

dest="/var/www/$SPEC_SERVER/$SITE_NAME"

if [[ -e .ssh ]]; then
  echo "Temp .ssh already exists: exiting for safety (check where you are running this from)"
  exit 1
fi

echo Setting up .ssh

mkdir .ssh
chmod 700 .ssh
echo "$SSH_PRIVATE_KEY" > .ssh/id_rsa && chmod 600 .ssh/id_rsa
echo "$SSH_KNOWN_HOSTS" > .ssh/known_hosts && chmod 600 .ssh/known_hosts

tar_file="$SITE_NAME.tar.gz"
echo "Making local tar file $tar_file"
tar -czf "$tar_file" _site

function do_ssh {
  # shellcheck disable=SC2029
  ssh -i .ssh/id_rsa -o UserKnownHostsFile=.ssh/known_hosts "$SSH_USER@$SSH_HOST" "$@" || exit 1
}
echo Making destination directory:
dest_new=$(do_ssh "mktemp -d $dest.XXXXXX")
echo "$dest_new"

echo Uploading
if ! scp -i .ssh/id_rsa -o UserKnownHostsFile=.ssh/known_hosts "$tar_file" "$SSH_USER@$SSH_HOST:$dest_new/"; then
  do_ssh rm -rf "$dest_new"
  exit 1
fi

echo Extracting
do_ssh "cd $dest_new && tar --strip-components=1 -xf $tar_file"

echo Replacing old site
do_ssh "mv $dest $dest.old ; mv $dest_new $dest; chmod 775 $dest; rm -rf $dest.old"

echo Deleting local tar file
rm "$tar_file"

if [[ "$AMWA_ID" == "SPECS" ]]; then
    echo Setting top level .htaccess and 404 page
    do_ssh "mv $dest/.htaccess $dest/branches/main/404.html $dest/../"
fi

echo Deleting .ssh
rm -rf .ssh

echo "Site is https://$SPEC_SERVER/$SITE_NAME"
