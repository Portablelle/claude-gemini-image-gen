#!/bin/bash
# Interactive setup for Gemini API key

set -euo pipefail

CONFIG_FILE="$HOME/.gemini-config"

echo "=== Gemini API Key Setup ==="
echo ""
echo "1. Go to https://aistudio.google.com/apikey"
echo "2. Create or select a project"
echo "3. Generate an API key"
echo ""

# Check existing config
if [[ -f "$CONFIG_FILE" ]]; then
  echo "WARNING: $CONFIG_FILE already exists."
  read -p "Overwrite? (y/N): " -r OVERWRITE
  if [[ ! "$OVERWRITE" =~ ^[Yy]$ ]]; then
    echo "Cancelled."
    exit 0
  fi
fi

# Get API key
read -p "Enter your Gemini API key: " API_KEY

if [[ -z "$API_KEY" ]]; then
  echo "ERROR: No key provided."
  exit 1
fi

# Test the key
echo ""
echo "Testing API key..."
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" \
  "https://generativelanguage.googleapis.com/v1beta/models?key=$API_KEY")

if [[ "$HTTP_CODE" != "200" ]]; then
  echo "ERROR: API key validation failed (HTTP $HTTP_CODE)."
  echo "Please check your key and try again."
  exit 1
fi

echo "API key is valid!"

# Save
cat > "$CONFIG_FILE" <<EOF
# Gemini API Configuration — $(date)
export GEMINI_API_KEY="$API_KEY"
EOF

chmod 600 "$CONFIG_FILE"

echo ""
echo "Saved to $CONFIG_FILE (permissions: 600)"
echo "You can now generate images!"
