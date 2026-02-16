---
description: Configure your Gemini API key for image generation
allowed-tools: [AskUserQuestion, Bash, Write, Read]
---

# Gemini API Key Setup

Guide the user through configuring their Google Gemini API key for image generation.

## Step 1: Check existing configuration

Check if `~/.gemini-config` already exists:
```bash
test -f ~/.gemini-config && echo "EXISTS" || echo "NOT_FOUND"
```

If it exists, ask the user if they want to reconfigure.

## Step 2: Get API key

Use AskUserQuestion to ask the user for their Gemini API key:
- Explain they need to get one from https://aistudio.google.com/apikey
- Provide a text input option for pasting the key

## Step 3: Validate the key

Test the API key:
```bash
curl -s -o /dev/null -w "%{http_code}" "https://generativelanguage.googleapis.com/v1beta/models?key=THE_KEY"
```

If HTTP 200, the key is valid. Otherwise, show an error and ask the user to try again.

## Step 4: Save configuration

Write the config file:
```bash
cat > ~/.gemini-config <<'CONF'
export GEMINI_API_KEY="THE_KEY"
CONF
chmod 600 ~/.gemini-config
```

## Step 5: Confirm

Tell the user:
- Configuration saved to `~/.gemini-config`
- They can now ask you to generate images naturally (e.g., "generate an image of...")
- Images will be saved to `~/generated-images/`
