#!/usr/bin/env bash

# Copyright 2020 British Broadcasting Corporation
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

set -o errexit

JSON_FILE=$1
NAME=$2
ALT_HREF=$3
ALT_TEXT=$4

LINT="jsonlint -q"

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
        ],
        sortPropertiesBy: function(a, b) {
           if (a === "title") { return -1; }
           if (b === "title") { return 1; }
           if (a === "description") { return -1; }
           if (b === "description") { return 1; }
           return a > b;
        }
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
