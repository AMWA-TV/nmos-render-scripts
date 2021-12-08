#!/bin/bash

# Copyright 2019 British Broadcasting Corporation
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

if $LINT "$JSON_FILE" ; then

    cat <<-EOF
<script type="text/javascript" src="codemirror/lib/codemirror.js"></script>
<link rel="stylesheet" href="codemirror/lib/codemirror.css">
<link rel="stylesheet" href="codemirror/addon/fold/foldgutter.css">
<script src="codemirror/mode/javascript/javascript.js"></script>
<script src="codemirror/addon/fold/foldcode.js"></script>
<script src="codemirror/addon/fold/foldgutter.js"></script>
<script src="codemirror/addon/fold/brace-fold.js"></script>
<script src="codemirror/addon/fold/indent-fold.js"></script>

<style>
  .CodeMirror {
    border-top: 1px solid black; 
    border-bottom: 1px solid black;
    height: 500px;
  }
</style>

<textarea id="mytextarea">
EOF

    cat "$JSON_FILE" # My JSON
    cat <<-EOF
</textarea>
<script>
window.editor_json = CodeMirror.fromTextArea(mytextarea, {
    mode: {
        name: "javascript",
        json: true
    },
    readOnly: true,
    lineNumbers: $SHOW_LINE_NUMBERS,
    lineWrapping: true,
    extraKeys: {"Ctrl-Q": function(cm){ cm.foldCode(cm.getCursor()); }},
    foldGutter: true,
    gutters: ["CodeMirror-linenumbers", "CodeMirror-foldgutter"],
    foldOptions: {
      widget: (from, to) => {
        var count = undefined;

        // Get open / close token
        var startToken = '{', endToken = '}';
        var prevLine = window.editor_json.getLine(from.line);
        if (prevLine.lastIndexOf('[') > prevLine.lastIndexOf('{')) {
          startToken = '[', endToken = ']';
        }

        // Get json content
        var internal = window.editor_json.getRange(from, to);
        var toParse = startToken + internal + endToken;

        // Get key count
        try {
          var parsed = JSON.parse(toParse);
          count = Object.keys(parsed).length;
        } catch(e) { }

        return count ? \`\u21A4\${count}\u21A6\` : '\u2194';
        }
      }
    }
  );
editor_json.foldCode(CodeMirror.Pos(3, 0));
</script>
EOF

else # Failed lint so do minimal render
    echo "<pre>"
    cat "$JSON_FILE"
    echo "</pre>"
fi

    cat <<-EOF
</div>
</html>
EOF
