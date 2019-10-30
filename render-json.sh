#!/bin/bash

set -o errexit

JSON_FILE=$1
NAME=$2
ALT_HREF=$3
ALT_TEXT=$4

LINT="${BASH_SOURCE[0]%/*}/node_modules/.bin/jsonlint -q"

cat <<EOF
---
layout: default
title: $NAME
---

<html>
<meta charset="UTF-8">
<h2>$NAME</h2>
EOF

if [ "$ALT_HREF" ]; then
    cat <<EOF
<p>
    <a href="$ALT_HREF">$ALT_TEXT</a>
</p>
EOF
fi

cat <<EOF
<div id="json-render">
EOF

if $LINT $JSON_FILE ; then

    cat <<-EOF
<script type="text/javascript" src="json-formatter.js"></script>
<script>
const formatter = new JSONFormatter.default(
EOF

    cat $JSON_FILE # My JSON

    cat <<-EOF
,
    3, // Collapse depth
    {
        pathsToCollapse: [
            "properties.id"
        ]
    });
document.getElementsByClassName("content")[0].appendChild(formatter.render());
</script>
EOF

else # Failed lint so do minimal render
    echo "<pre>"
    cat $JSON_FILE
    echo "</pre>"
fi

    cat <<-EOF
</div>
</html>
EOF
