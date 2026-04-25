PREFIX ?= $(HOME)/.local
BIN_DIR = $(PREFIX)/bin
CONFIG_DIR = $(HOME)/.config/yt-player
CACHE_DIR = $(HOME)/.cache/yt-player

install:
	@echo "Installing yt-player..."

	mkdir -p $(BIN_DIR)
	mkdir -p $(CONFIG_DIR)
	mkdir -p $(CACHE_DIR)

	# Install script
	cp yt-player.sh $(BIN_DIR)/yt-player
	chmod +x $(BIN_DIR)/yt-player

	# Install default config (only if not exists)
	if [ ! -f $(CONFIG_DIR)/config.json ]; then \
		cp config/config.example.json $(CONFIG_DIR)/config.json; \
	fi

	cp config/fav.config.json $(CONFIG_DIR)/

	# Install cache files
	cp -r cache/* $(CACHE_DIR)/ 2>/dev/null || true

	@echo "Done."
	@echo "Make sure $(BIN_DIR) is in your PATH"

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