#!/bin/bash

set -o errexit

./make-clean.sh
rm -rf node_modules/ yarn.lock package-lock.json raml2html-nmos-theme/
