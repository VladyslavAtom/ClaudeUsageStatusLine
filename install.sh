#!/bin/bash
# Claude Usage Statusline Installer

set -e

CLAUDE_DIR="$HOME/.claude"
SCRIPT_URL_BASE="https://raw.githubusercontent.com/VladyslavAtom/ClaudeUsageStatusLine/main"

echo "=== Claude Usage Statusline Installer ==="
echo

# Check dependencies
check_deps() {
    local missing=()

    if ! command -v jq &>/dev/null; then
        missing+=("jq")
    fi

    if ! command -v python3 &>/dev/null; then
        missing+=("python3")
    fi

    if ! python3 -c "import requests" &>/dev/null 2>&1; then
        missing+=("python-requests")
    fi

    if [ ${#missing[@]} -gt 0 ]; then
        echo "Missing dependencies: ${missing[*]}"
        echo
        echo "Install them with:"
        echo "  Arch:   sudo pacman -S ${missing[*]}"
        echo "  Ubuntu: sudo apt install ${missing[*]}"
        echo "  Fedora: sudo dnf install ${missing[*]}"
        echo "  pip:    pip install requests"
        echo
        read -p "Continue anyway? [y/N] " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            exit 1
        fi
    else
        echo "✓ All dependencies installed"
    fi
}

# Download scripts
download_scripts() {
    echo "Downloading scripts to $CLAUDE_DIR..."

    mkdir -p "$CLAUDE_DIR"

    curl -fsSL "$SCRIPT_URL_BASE/statusline.sh" -o "$CLAUDE_DIR/statusline.sh"
    curl -fsSL "$SCRIPT_URL_BASE/fetch-usage.py" -o "$CLAUDE_DIR/fetch-usage.py"

    chmod +x "$CLAUDE_DIR/statusline.sh" "$CLAUDE_DIR/fetch-usage.py"

    echo "✓ Scripts installed"
}

# Configure session key
setup_session_key() {
    local key_file="$HOME/.claude-session-key"

    if [ -f "$key_file" ]; then
        echo "✓ Session key already exists at $key_file"
        return
    fi

    echo
    echo "Session key setup:"
    echo "  1. Open https://claude.ai in your browser"
    echo "  2. Open Developer Tools (F12) → Application → Cookies"
    echo "  3. Copy the 'sessionKey' value"
    echo
    read -p "Paste your session key (or press Enter to skip): " session_key

    if [ -n "$session_key" ]; then
        echo "$session_key" > "$key_file"
        chmod 600 "$key_file"
        echo "✓ Session key saved to $key_file"
    else
        echo "⚠ Skipped. Create $key_file manually later."
    fi
}

# Update settings.json
update_settings() {
    local settings_file="$CLAUDE_DIR/settings.json"
    local script_path="$CLAUDE_DIR/statusline.sh"

    if [ -f "$settings_file" ]; then
        if grep -q '"statusline"' "$settings_file"; then
            echo "⚠ statusline already configured in $settings_file"
            echo "  Verify it points to: $script_path"
            return
        fi

        # Add statusline to existing settings
        if command -v jq &>/dev/null; then
            local tmp=$(mktemp)
            jq --arg script "$script_path" '. + {"statusline": {"script": $script}}' "$settings_file" > "$tmp"
            mv "$tmp" "$settings_file"
            echo "✓ Updated $settings_file"
        else
            echo "⚠ Cannot update settings (jq not available)"
            echo "  Add manually to $settings_file:"
            echo '  "statusline": {"script": "'"$script_path"'"}'
        fi
    else
        # Create new settings file
        cat > "$settings_file" << EOF
{
  "statusline": {
    "script": "$script_path"
  }
}
EOF
        echo "✓ Created $settings_file"
    fi
}

# Main
main() {
    check_deps
    echo
    download_scripts
    echo
    setup_session_key
    echo
    update_settings
    echo
    echo "=== Installation complete ==="
    echo
    echo "Restart Claude Code to see the statusline."
    echo "If usage shows '--', check your session key."
}

main
