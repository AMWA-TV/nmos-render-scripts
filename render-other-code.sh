#!/bin/bash

# Copyright 2022 British Broadcasting Corporation
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

if [ "$1" == "-n" ]; then
    SHOW_LINE_NUMBERS=true
    shift
else
    SHOW_LINE_NUMBERS=false
fi

CODE_FILE=$1
NAME=$2
ALT_HREF=$3
ALT_TEXT=$4
RAW_HREF=$5
RAW_TEXT=$6

LINT=: # return true

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

if [ "$RAW_HREF" ]; then
    cat <<EOF
<p>
    <a href="$RAW_HREF">$RAW_TEXT</a>
</p>
EOF
fi

cat <<EOF
<div id="json-render">
EOF

if $LINT "$CODE_FILE" ; then

    cat <<-EOF
<script type="text/javascript" src="codemirror/lib/codemirror.js"></script>
<link rel="stylesheet" href="codemirror/lib/codemirror.css">

<style>
  .CodeMirror {
    border-top: 1px solid black; 
    border-bottom: 1px solid black;
    height: 500px;
  }
</style>

<textarea id="mytextarea">
EOF

    cat "$CODE_FILE"
    cat <<-EOF
</textarea>
<script>
window.editor_json = CodeMirror.fromTextArea(mytextarea, {
    lineNumbers: $SHOW_LINE_NUMBERS,
    matchBrackets: true
  }
);
</script>
EOF

else # Failed lint so do minimal render
    echo "<pre>"
    cat "$CODE_FILE"
    echo "</pre>"
fi

    cat <<-EOF
</div>
</html>
EOF
