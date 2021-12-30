#!/usr/bin/env bash

set -o errexit

CONCAT=/tmp/concat.json

echo "Getting spec info: "
for id in $(yaml2json _data/spec_list.yml | jq -r '.[]'); do
	echo "$id"
	wget -O- -q "https://specs.amwa.tv/${id,,}/spec.json" >> "$CONCAT"
done
echo

jq --slurp . "$CONCAT" > specs.json