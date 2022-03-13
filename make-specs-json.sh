#!/usr/bin/env bash

set -o errexit

if [[ -z "$GITHUB_TOKEN" ]]; then
	echo GITHUB_TOKEN not set
	exit 1
fi

SPEC=/tmp/spec.json
ISSUES=/tmp/issues.json
CONCAT=/tmp/concat.json
rm -f "$CONCAT"

echo "Getting spec info: "
for id in $(yaml2json ../spec_list.yml | jq -r '.[]'); do
	echo "$id"
	wget -O- -q "https://specs.amwa.tv/${id,,}/spec.json" > "$SPEC"
	wget -O- -q --header "Authorization: token $GITHUB_TOKEN" "https://api.github.com/repos/AMWA-TV/${id,,}/issues" | \
		jq '{ num_issues: [.[] | select(.pull_request == null)] | length, num_pulls: [.[] | select(.pull_request != null)] | length}' > "$ISSUES"
	jq --slurp '.[0] * .[1]' "$SPEC" "$ISSUES" >> "$CONCAT"
done
echo

jq --slurp . "$CONCAT" > _data/specs.json
