.PHONY: build clean install-dev sync

# Build the standalone binary
build:
	uv sync --group dev
	uv run pyinstaller --clean fetch-usage.spec
	@echo "Binary created: dist/claude-usage"

# Install development dependencies
install-dev:
	uv sync --group dev

# Sync dependencies
sync:
	uv sync

# Clean build artifacts
clean:
	rm -rf build dist __pycache__ *.egg-info
	rm -rf .eggs .pytest_cache

# Clean everything including venv
clean-all: clean
	rm -rf .venv
