#!/usr/bin/env bash

# shellcheck source=get-config.sh
. .scripts/get-config.sh

# The $SSH_ env variables are provided by GitHub secret

dest="/var/www/$SPEC_SERVER/$SITE_NAME"

if [[ -e .ssh ]]; then
  echo Temp .ssh already exists: exiting
  exit 1
fi

mkdir .ssh
chmod 700 .ssh
echo "$SSH_PRIVATE_KEY" > .ssh/id_rsa && chmod 600 .ssh/id_rsa
echo "$SSH_KNOWN_HOSTS" > .ssh/known_hosts && chmod 600 .ssh/known_hosts

echo Making tar
tar -czf $SITE_NAME.tar.gz _site

echo Making destination directory
ssh -i .ssh/id_rsa -o UserKnownHostsFile=.ssh/known_hosts "$SSH_USER@$SSH_HOST" \
    "mkdir $dest.new"

echo Uploading
scp -i .ssh/id_rsa -o UserKnownHostsFile=.ssh/known_hosts $SITE_NAME.tar.gz "$SSH_USER@$SSH_HOST:$dest.new/"

echo Extracting
ssh -i .ssh/id_rsa -o UserKnownHostsFile=.ssh/known_hosts "$SSH_USER@$SSH_HOST" \
    "cd $dest.new && tar --strip-components=1 -xf $SITE_NAME.tar.gz"

echo Replacing old site
# shellcheck disable=SC2029
ssh -i .ssh/id_rsa -o UserKnownHostsFile=.ssh/known_hosts "$SSH_USER@$SSH_HOST" \
    "mv $dest $dest.old ; mv $dest.new $dest; rm -rf $dest.old"

echo "Site is https://$SPEC_SERVER/$SITE_NAME"
