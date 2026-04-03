# BlindJam — Capacitor / Android player shell
#
# The native app is a WebView client for the existing Rails + Hotwire app. Player flows
# (home, join/create room, scan or enter code, now playing, guesses, leaderboard, profile)
# stay in Rails; Capacitor supplies installable packaging, splash/icon, camera, and push hooks.
#
# Prereqs (host targets): Node 18+, npm; Android Studio (SDK + platform tools); JDK 17 (Android Gradle).
# Docker targets: only Docker + Compose; Android Studio still runs on the host to deploy/run the APK.
#
# Dev server: Rails on port 3024 (docker compose) — Android emulator reaches the host as 10.0.2.2
# Physical device: use your machine LAN IP, e.g. CAPACITOR_SERVER_URL=http://192.168.1.10:3024

MOBILE_DIR        := mobile
COMPOSE           := docker compose
# docker-compose.yml sets top-level `name: beatdrop` — volume is ${COMPOSE_PROJECT_NAME}_capacitor_node_modules
COMPOSE_PROJECT_NAME ?= beatdrop
export COMPOSE_PROJECT_NAME
COMPOSE_CAP       := $(COMPOSE) --profile capacitor
# Run as root so npm can write to the named volume `capacitor_node_modules` (avoids EACCES with random host UIDs).
# Fix bind-mount ownership of `mobile/android` after sync with: make mobile-fix-android-perms
CAP_RUN           := $(COMPOSE_CAP) run --rm
HOST_UID          := $(shell id -u)
HOST_GID          := $(shell id -g)
# Default: emulator → host Rails (see https://developer.android.com/studio/run/emulator-networking)
CAPACITOR_SERVER_URL ?= http://10.0.2.2:3024
export CAPACITOR_SERVER_URL

.PHONY: help mobile-install mobile-install-docker mobile-fix-android-perms \
	capacitor-init-android capacitor-init-android-docker \
	capacitor-sync capacitor-sync-docker capacitor-sync-offline capacitor-sync-offline-docker \
	capacitor-sync-local capacitor-sync-local-docker \
	capacitor-sync-prod capacitor-sync-prod-docker android-open android-open-docker \
	android-build-debug clean-mobile clean-mobile-docker

help:
	@echo "Capacitor / Android (player app shell)"
	@echo ""
	@echo "Host (requires local Node):"
	@echo "  make mobile-install          Install npm deps in $(MOBILE_DIR)/"
	@echo "  make capacitor-init-android  Add Android platform (once) + sync"
	@echo "  make capacitor-sync          cap sync (uses CAPACITOR_SERVER_URL=$(CAPACITOR_SERVER_URL))"
	@echo "  make capacitor-sync-offline    cap sync with CAPACITOR_OFFLINE=1 (www only, no Rails URL)"
	@echo "  make capacitor-sync-local    Same with http://127.0.0.1:3024 (AVD host loopback)"
	@echo "  make capacitor-sync-prod     Sync for production (set PROD_SERVER_URL first)"
	@echo "  make android-open            sync + open Android Studio"
	@echo "  make android-build-debug     sync + assembleDebug (requires ANDROID_HOME)"
	@echo ""
	@echo "Docker (uses compose service 'capacitor'; separate volume from icons 'node' service):"
	@echo "  make mobile-install-docker"
	@echo "  make capacitor-sync-docker"
	@echo "  make capacitor-sync-offline-docker   # no server.url — mobile/www only (scroll/perf baseline)"
	@echo "  make capacitor-sync-local-docker"
	@echo "  make capacitor-sync-prod-docker   (needs PROD_SERVER_URL)"
	@echo "  make capacitor-init-android-docker"
	@echo "  make android-open-docker          sync in Docker; cap open on host if npx exists"
	@echo "  make mobile-fix-android-perms     chown mobile/android to your user (after Docker sync as root)"
	@echo "  make clean-mobile-docker          remove capacitor_node_modules volume"
	@echo ""
	@echo "Env: CAPACITOR_SERVER_URL — Rails base URL baked in at sync time."
	@echo "     CAPACITOR_OFFLINE=1 — omit server.url (see capacitor-sync-offline*)."
	@echo "     PROD_SERVER_URL — https origin for capacitor-sync-prod"
	@echo "Note: Pick host XOR Docker npm for mobile/; Docker stores deps in volume 'capacitor_node_modules'."

mobile-install:
	cd $(MOBILE_DIR) && npm install

mobile-install-docker:
	$(CAP_RUN) -e CAPACITOR_SERVER_URL="$(CAPACITOR_SERVER_URL)" capacitor npm install

# Docker sync runs as root; Gradle/Android Studio on the host need owned files.
mobile-fix-android-perms:
	$(COMPOSE_CAP) run --rm --user root \
		-e HOST_UID=$(HOST_UID) -e HOST_GID=$(HOST_GID) \
		capacitor sh -lc 'chown -R $$HOST_UID:$$HOST_GID /app/mobile/android'

# First-time: creates mobile/android/ (commit or regenerate per team policy)
capacitor-init-android: mobile-install
	cd $(MOBILE_DIR) && (test -d android || npx cap add android)
	@$(MAKE) capacitor-sync

capacitor-init-android-docker: mobile-install-docker
	$(CAP_RUN) -e CAPACITOR_SERVER_URL="$(CAPACITOR_SERVER_URL)" capacitor sh -lc 'test -d android || npx cap add android'
	@$(MAKE) capacitor-sync-docker

capacitor-sync: mobile-install
	cd $(MOBILE_DIR) && npx cap sync

capacitor-sync-docker: mobile-install-docker
	$(CAP_RUN) -e CAPACITOR_SERVER_URL="$(CAPACITOR_SERVER_URL)" capacitor npx cap sync
	@$(MAKE) mobile-fix-android-perms

# No server.url — loads mobile/www only (isolates WebView jank from 10.0.2.2 + Rails). Not the full app.
capacitor-sync-offline: mobile-install
	cd $(MOBILE_DIR) && CAPACITOR_OFFLINE=1 npx cap sync

capacitor-sync-offline-docker: mobile-install-docker
	$(CAP_RUN) -e CAPACITOR_OFFLINE=1 capacitor npx cap sync
	@$(MAKE) mobile-fix-android-perms

capacitor-sync-local: mobile-install
	cd $(MOBILE_DIR) && CAPACITOR_SERVER_URL=http://127.0.0.1:3024 npx cap sync

capacitor-sync-local-docker: mobile-install-docker
	$(CAP_RUN) -e CAPACITOR_SERVER_URL=http://127.0.0.1:3024 capacitor npx cap sync
	@$(MAKE) mobile-fix-android-perms

capacitor-sync-prod: mobile-install
	@test -n "$(PROD_SERVER_URL)" || (echo "Set PROD_SERVER_URL, e.g. https://app.example.com" && exit 1)
	cd $(MOBILE_DIR) && CAPACITOR_SERVER_URL="$(PROD_SERVER_URL)" npx cap sync

capacitor-sync-prod-docker: mobile-install-docker
	@test -n "$(PROD_SERVER_URL)" || (echo "Set PROD_SERVER_URL, e.g. https://app.example.com" && exit 1)
	$(CAP_RUN) -e CAPACITOR_SERVER_URL="$(PROD_SERVER_URL)" capacitor npx cap sync
	@$(MAKE) mobile-fix-android-perms

android-open: capacitor-sync
	cd $(MOBILE_DIR) && npx cap open android

android-open-docker: capacitor-sync-docker
	@if command -v npx >/dev/null 2>&1; then \
		cd $(MOBILE_DIR) && npx cap open android; \
	else \
		echo "npx not on PATH — open folder $(MOBILE_DIR)/android in Android Studio."; \
	fi

android-build-debug: capacitor-sync
	cd $(MOBILE_DIR)/android && ./gradlew assembleDebug

clean-mobile:
	rm -rf $(MOBILE_DIR)/node_modules

# Remove only the Capacitor npm volume (does not touch icons `node_modules` or Rails volumes).
clean-mobile-docker:
	@docker volume rm -f $(COMPOSE_PROJECT_NAME)_capacitor_node_modules 2>/dev/null || \
		echo "Volume $(COMPOSE_PROJECT_NAME)_capacitor_node_modules not found (try: docker volume ls | grep capacitor)."

# Live room (root React bundle — not mobile/)
.PHONY: js-install js-build js-build-prod js-watch
js-install:
	npm install

js-build: js-install
	npm run build

js-build-prod: js-install
	npm run build:prod

js-watch: js-install
	npm run build:watch
