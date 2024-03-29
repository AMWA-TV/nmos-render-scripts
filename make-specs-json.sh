#!/usr/bin/env bash

set -o errexit

CONCAT=/tmp/concat.json
rm -f "$CONCAT"

echo "Getting spec info: "
for id in $(yaml2json ../spec_list.yml | jq -r '.[]'); do
	echo "$id"
	wget -O- -q "https://specs.amwa.tv/${id,,}/spec.json" >> "$CONCAT"
done
echo

jq --slurp . "$CONCAT" > _data/specs.json
