# syntax=docker/dockerfile:1

# Container image that runs your code
FROM jekyll/jekyll

RUN apk update
RUN apk add --no-cache --update \
    git \
    perl \
    ed \
    openssh

RUN pip3 install --upgrade pip && pip3 install \
    setuptools \
    jsonref \
    pathlib

# Copies your code file from your action repository to the filesystem path `/` of the container
COPY entrypoint.sh /entrypoint.sh

COPY Gemfile /Gemfile
RUN bundle install

#RUN mkdir /usr/src/node_modules && cd /usr/src/node_modules && npm install -g raml2html
RUN git clone https://${GITHUB_TOKEN:+${GITHUB_TOKEN}@}github.com/AMWA-TV/raml2html-nmos-theme /raml2html-nmos-theme
RUN yarn global add \
    jsonlint \
    raml2html \
    remark-cli \
    remark-preset-lint-recommended \
    remark-validate-links \
    yaml-lint \
    file:/raml2html-nmos-theme

# Code file to execute when the docker container starts up (`entrypoint.sh`)
ENTRYPOINT ["/entrypoint.sh"]
