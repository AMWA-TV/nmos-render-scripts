#!/usr/bin/env bash

# Make the dirs required for Jekyll, copy common files from layouts repo, 
# and copy any local files, overwriting as required. 

set -o errexit

echo Setting up layouts

if [[ -d .layouts ]]; then
	echo "Warning: .layouts exists so not cloning"
else
	git clone --single-branch --branch "${NMOS_DOC_LAYOUTS_BRANCH:-main}" https://${GITHUB_TOKEN:+${GITHUB_TOKEN}@}github.com/AMWA-TV/nmos-doc-layouts .layouts
fi

for dir in _layouts _includes assets assets/css assets/images; do
	cp -r ".layouts/$dir" "$dir"
	[[ -d "_local/$dir" ]] && cp -r "_local/$dir"/* "$dir"
done

exit 0