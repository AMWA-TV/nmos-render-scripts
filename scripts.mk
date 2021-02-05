.PHONY: build source-repo docs indexes fix-links layouts site rewrites upload server server-ext clean

build: source-repo docs indexes fix-links layouts site rewrites

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

rewrites:
	.scripts/make-rewrites.sh

upload:
	.scripts/upload-site.sh

server:
	.scripts/run-server.sh

server-ext:
	.scripts/run-server.sh --host 0.0.0.0

clean:
	.scripts/make-clean.sh
