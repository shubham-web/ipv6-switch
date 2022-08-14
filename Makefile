APP_NAME := IPv6 Switch
APP      := build/$(APP_NAME).app
VERSION  := $(shell tr -d '[:space:]' < VERSION)
ZIP      := dist/IPv6-Switch-$(VERSION).zip
PREFIX   ?= /Applications

# Passed through to scripts/build-app.sh.
export UNIVERSAL SIGN_IDENTITY VERSION

.PHONY: all help app run test install uninstall zip screenshot clean

all: app

help: ## List targets
	@grep -E '^[a-z]+:.*## ' $(MAKEFILE_LIST) | awk -F ':.*## ' '{printf "  make %-10s %s\n", $$1, $$2}'

app: ## Build build/IPv6 Switch.app
	./scripts/build-app.sh

run: app ## Build and launch the app
	open "$(APP)"

test: ## Run unit tests
	swift test

install: app ## Copy the app to $(PREFIX) (default /Applications)
	rm -rf "$(PREFIX)/$(APP_NAME).app"
	cp -R "$(APP)" "$(PREFIX)/"
	@echo "Installed to $(PREFIX)/$(APP_NAME).app"

uninstall: ## Remove the app from $(PREFIX)
	rm -rf "$(PREFIX)/$(APP_NAME).app"

zip: app ## Package the app as a zip with a SHA-256 checksum in dist/
	mkdir -p dist
	rm -f "$(ZIP)"
	ditto -c -k --keepParent "$(APP)" "$(ZIP)"
	cd dist && shasum -a 256 "$(notdir $(ZIP))" > "$(notdir $(ZIP)).sha256"
	@cat "$(ZIP).sha256"

screenshot: ## Regenerate the README screenshots (demo data, needs Screen Recording permission)
	./scripts/screenshot.sh

clean: ## Remove build output
	rm -rf .build build dist
