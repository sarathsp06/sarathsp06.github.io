.DEFAULT_GOAL := help
OUT ?= _site
PORT ?= 8000
# Settings `make configure` may write to site.conf.
CONF_KEYS := OWNER SITE_URL SECURITY_CONTACTS SECURITY_POLICY SECURITY_ACKNOWLEDGMENTS \
             SECURITY_ENCRYPTION SECURITY_NOTES PREFERRED_LANGUAGES EXPIRES_DAYS SITEMAPS \
             SITE_TITLE SITE_DESCRIPTION PROJECTS

.PHONY: help configure build check check-live serve clean

help: ## List targets
	@grep -E '^[a-z-]+:.*## ' $(MAKEFILE_LIST) | awk -F':.*## ' '{printf "  make %-11s %s\n", $$1, $$2}'
	@echo; echo "  First time: make configure OWNER=<github-user> SECURITY_CONTACTS=you@example.org"

configure: ## Write settings to site.conf: make configure KEY=value ... (OWNER defaults to the git remote's owner)
	@owner="$(OWNER)"; \
	if [ -z "$$owner" ]; then owner=$$(git remote get-url origin 2>/dev/null | sed -E 's#.*[:/]([^/]+)/[^/]+(\.git)?$$#\1#'); fi; \
	[ -n "$$owner" ] && sh scripts/set-conf.sh OWNER "$$owner"; \
	$(foreach k,$(filter-out OWNER,$(CONF_KEYS)),$(if $(filter command line,$(origin $(k))),sh scripts/set-conf.sh $(k) "$($(k))";)) \
	grep -E '^[A-Z_]+=' site.conf

build: ## Render the site into $(OUT)/
	@OUT=$(OUT) sh scripts/build.sh

check: build ## Build, then validate the output
	@OUT=$(OUT) sh scripts/check.sh

check-live: ## Validate what is being served (default: SITE_URL or https://OWNER.github.io)
	@. ./site.conf; sh scripts/check.sh "$${SITE_URL:-https://$$OWNER.github.io}"

serve: build ## Serve $(OUT)/ on http://localhost:$(PORT)
	python3 -m http.server $(PORT) -d $(OUT)

clean: ## Remove $(OUT)/
	rm -rf $(OUT)
