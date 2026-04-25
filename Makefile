PREFIX ?= $(HOME)/.local
BIN_DIR = $(PREFIX)/bin
CONFIG_DIR = $(HOME)/.config/yt-player
CACHE_DIR = $(HOME)/.cache/yt-player

install:
	@echo Installing yt-player...

	mkdir -p $(BIN_DIR)
	mkdir -p $(CONFIG_DIR)
	mkdir -p $(CACHE_DIR)

	# Install script
	cp yt-player.sh $(BIN_DIR)/yt-player
	chmod +x $(BIN_DIR)/yt-player

	# Install default config (only if not exists)
	if [ ! -f $(CONFIG_DIR)/config.json ]; then \
		cp config/fav.config.json $(CONFIG_DIR)/config.json; \
	fi

	cp config/fav.config.json $(CONFIG_DIR)/

	# Install cache files
 	#cp -r cache/* $(CACHE_DIR)/ 2>/dev/null || true

	@echo "Done."
	# check if BIN_DIR is in PATH
	if ! echo "$$PATH" | grep -q "$(BIN_DIR)"; then \
		@echo "Warning: $(BIN_DIR) is not in your PATH. You may want to add it to run yt-player from anywhere."; \
	fi

uninstall:
	@echo "Removing yt-player..."

	rm -f $(BIN_DIR)/yt-player
	rm -rf $(CONFIG_DIR)
	rm -rf $(CACHE_DIR)

	@echo "Uninstalled."



reinstall: uninstall install


help:
	@echo "make install   - Install yt-player"
	@echo "make uninstall - Remove yt-player"