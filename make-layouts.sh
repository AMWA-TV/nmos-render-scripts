#!/usr/bin/env bash

# Make the dirs required for Jekyll, copy common files from layouts repo, 
# and copy any local files, overwriting as required. 

set -o errexit
shopt -s nullglob

echo Setting up layouts

# Load environment variables from .env (if present)
# shellcheck disable=SC1091
if [ -f .env ]; then
    set -a
    source .env
    set +a
fi

if [[ -d .layouts ]]; then
	echo "Warning: .layouts exists so not cloning"
else
	git clone --single-branch --branch "${NMOS_DOC_LAYOUTS_BRANCH:-main}" https://${GITHUB_TOKEN:+${GITHUB_TOKEN}@}github.com/AMWA-TV/nmos-render-layouts .layouts
fi

for dir in _layouts _includes assets/css assets/images; do
	[[ ! -d "$dir" ]] && mkdir -p "$dir"
	for file in ".layouts/$dir"/*; do
		cp "$file" "$dir/"
	done
	for file in "_local/$dir"/*; do
		cp "$file" "$dir/"
	done
done

exit 0
