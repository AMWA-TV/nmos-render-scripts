# syntax=docker/dockerfile:1

# Container image that runs your code
FROM jekyll/jekyll

RUN apk update

# Common commands needed by the render scripts
RUN apk add --no-cache --update \
    git \
    perl \
    ed \
    openssh

# Python modules 
RUN pip3 install --upgrade pip && pip3 install \
    setuptools \
    jsonref \
    pathlib

# Needed for GitHub Pages plugin
COPY Gemfile /Gemfile
RUN bundle install

# NMOS has its own RAML2HTML theme
RUN git clone --depth 1 https://${GITHUB_TOKEN:+${GITHUB_TOKEN}@}github.com/AMWA-TV/raml2html-nmos-theme /raml2html-nmos-theme

# Node modules
RUN yarn global add \
    jsonlint \
    raml2html \
    remark-cli \
    remark-preset-lint-recommended \
    remark-validate-links \
    yaml-lint \
    file:/raml2html-nmos-theme

# Copy the render scripts etc.
COPY *.sh *.py \
    json-formatter.js \
    scripts.mk \
    intro_common.md \
    /.scripts/
COPY codemirror /.scripts/codemirror/

# /entrypoint.sh is executed by default when the container runs
COPY entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]

COPY multi-repo.sh /multi-repo.sh
