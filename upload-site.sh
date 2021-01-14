#!/usr/bin/env bash

# shellcheck source=get-config.sh
. .scripts/get-config.sh

# server_host=specs.nmos.bbctest01.uk
# server_dir="/var/www/$server_host/html/$REPO_NAME"

# server_host=specs.amwa.tv
server_host=specs.amwa.tv
server_dir="/var/www/$server_host/$REPO_NAME"

# CHANGE THIS BEFORE PUSHING
ssh_user=nmosmachine
ssh_id="~/.ssh-nmosmachine/id_rsa"

echo "Removing old site..."
ssh -i "$ssh_id" "$ssh_user@$server_host" rm -rf "$server_dir"

echo "Uploading new site..."
scp -q -i "$ssh_id" -r _site "$ssh_user@$server_host:$server_dir"

echo "Site is https://$server_host/$REPO_NAME"
