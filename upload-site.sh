#!/usr/bin/env bash

# shellcheck source=get-config.sh
. .scripts/get-config.sh

# The $SSH_ env variables are provided by GitHub secret

# This assumes that the spec is served from a URL that matches the SSH host
server_dir="/var/www/$SSH_HOST/$SITE_NAME"

if [[ -e .ssh ]]; then
  echo Temp .ssh already exists: exiting
  exit 1
fi

mkdir .ssh
chmod 700 .ssh
echo "$SSH_PRIVATE_KEY" > .ssh/id_rsa && chmod 600 .ssh/id_rsa
echo "$SSH_KNOWN_HOSTS" > .ssh/known_hosts && chmod 600 .ssh/known_hosts

echo Uploading
scp -r -i .ssh/id_rsa -o UserKnownHostsFile=.ssh/known_hosts _site "$SSH_USER@$SSH_HOST:$server_dir.new"

echo Replacing old site
ssh -i .ssh/id_rsa -o UserKnownHostsFile=.ssh/known_hosts "$SSH_USER@$SSH_HOST" \
    "mv $server_dir $server_dir.old ; mv $server_dir.new $server_dir; rm -rf $server_dir.old"

echo "Site is https://$SSH_HOST/$SITE_NAME"

