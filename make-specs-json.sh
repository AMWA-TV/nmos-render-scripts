#!/usr/bin/env bash
set -o errexit

TMP=$(mktemp -d -t make-specs-json)

echo "Getting themes"
themes=$(yaml2json ../themes.yml)

echo "Getting spec info"
for id in $(yaml2json ../spec_list.yml | jq -r '.[]'); do
    echo "$id"
    # themes for this id to mix in
    id_themes=$(echo "$themes" | jq "[ .[] | select(.members[] == \"$id\").name ]")
    wget -O- -q "https://specs.amwa.tv/${id,,}/spec.json" | jq ".themes = $id_themes" >> "$TMP/specs"
done
echo

echo "Making specs.json"
jq --slurp . "$TMP/specs" > _data/specs.json

rm -r "$TMP"
