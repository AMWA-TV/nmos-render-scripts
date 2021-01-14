.PHONY: build source-repo docs indexes fix-links layouts server push clean

build: source-repo docs indexes fix-links layouts

source-repo:
	.scripts/get-source-repo.sh

docs:
	.scripts/extract-docs.sh

indexes:
	.scripts/make-indexes.sh

fix-links:
	.scripts/fix-links.sh

layouts:
	.scripts/make-layouts.sh

site:
	.scripts/make-site.sh

upload:
	.scripts/upload-site.sh

server:
	.scripts/run-server.sh

push:
	.scripts/push-to-github.sh

clean:
	.scripts/make-clean.sh
