SHELL := /bin/sh
.DEFAULT_GOAL := help

IMAGES ?= debian:12-slim fedora:41
RUNS   ?= 50

.PHONY: help bootstrap test test-debian test-fedora lint lint-sh lint-lua packages packages-check bench nvim-lock clean

help: ## Show this help
	@grep -hE '^[a-z][a-z-]*:.*?## ' $(MAKEFILE_LIST) \
		| awk 'BEGIN {FS = ":.*?## "}; {printf "  %-15s %s\n", $$1, $$2}'

bootstrap: ## Install the environment on this machine
	./bootstrap.sh

test: ## Run the full suite in a container for every supported Linux
	IMAGES="$(IMAGES)" RUNS="$(RUNS)" ./tests/run.sh

test-debian: ## Run the suite on debian:12-slim only
	IMAGES=debian:12-slim RUNS="$(RUNS)" ./tests/run.sh

test-fedora: ## Run the suite on fedora:41 only
	IMAGES=fedora:41 RUNS="$(RUNS)" ./tests/run.sh

lint: lint-sh lint-lua packages-check ## Run every linter

lint-sh: ## ShellCheck over every shell script
	./scripts/lint-sh.sh

lint-lua: ## StyLua --check over the Neovim configuration
	./scripts/lint-lua.sh

packages: ## Regenerate the package lists from packages/manifest.tsv
	./scripts/gen-packages.sh

packages-check: ## Fail if the generated package lists are stale
	./scripts/gen-packages.sh --check

bench: ## Measure zsh startup in a container
	docker run --rm -i -v "$(CURDIR):/opt/dev-env:ro" -e HOME=/root -e RUNS=$(RUNS) \
		debian:12-slim sh -c '/opt/dev-env/bootstrap.sh >/dev/null && /opt/dev-env/scripts/bench-zsh.sh'

nvim-lock: ## Regenerate home/.config/nvim/lazy-lock.json in a container
	docker run --rm -i -v "$(CURDIR):/opt/dev-env" -e HOME=/root debian:12-slim \
		sh -c '/opt/dev-env/bootstrap.sh >/dev/null && nvim --headless "+Lazy! sync" +qa'
	@printf 'lazy-lock.json regenerated; review the diff before committing\n'

clean: ## Remove the download and tool cache
	rm -rf .cache
