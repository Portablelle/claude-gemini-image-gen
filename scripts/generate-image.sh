#!/bin/bash
# Gemini Image Generation Script
# Generates images using Google Gemini API via curl + jq

set -euo pipefail

# --- Configuration ---
OUTPUT_DIR="${GEMINI_OUTPUT_DIR:-$HOME/generated-images}"
CONFIG_FILE="$HOME/.gemini-config"
DEFAULT_MODEL="gemini-3-pro-image-preview"
DEFAULT_ASPECT_RATIO="1:1"
DEFAULT_SIZE="2K"

# --- Load API key ---
if [[ -f "$CONFIG_FILE" ]]; then
  source "$CONFIG_FILE"
fi

if [[ -z "${GEMINI_API_KEY:-}" ]]; then
  echo "ERROR: GEMINI_API_KEY not configured." >&2
  echo "Run /setup-gemini or create ~/.gemini-config with:" >&2
  echo '  export GEMINI_API_KEY="your-key-here"' >&2
  exit 1
fi

# --- Parse arguments ---
PROMPT=""
MODEL="$DEFAULT_MODEL"
ASPECT_RATIO="$DEFAULT_ASPECT_RATIO"
SIZE="$DEFAULT_SIZE"

while [[ $# -gt 0 ]]; do
  case $1 in
    --model)
      MODEL="$2"
      shift 2
      ;;
    --aspect-ratio)
      ASPECT_RATIO="$2"
      shift 2
      ;;
    --size)
      SIZE="$2"
      shift 2
      ;;
    --output-dir)
      OUTPUT_DIR="$2"
      shift 2
      ;;
    *)
      if [[ -z "$PROMPT" ]]; then
        PROMPT="$1"
      else
        PROMPT="$PROMPT $1"
      fi
      shift
      ;;
  esac
done

if [[ -z "$PROMPT" ]]; then
  echo "ERROR: No prompt provided." >&2
  echo "Usage: generate-image.sh <prompt> [--model MODEL] [--aspect-ratio RATIO] [--size SIZE]" >&2
  exit 1
fi

# --- Validate parameters ---
valid_models=("gemini-2.5-flash-image" "gemini-3-pro-image-preview")
model_ok=false
for m in "${valid_models[@]}"; do
  [[ "$m" == "$MODEL" ]] && model_ok=true
done
if ! $model_ok; then
  echo "ERROR: Invalid model '$MODEL'. Valid: ${valid_models[*]}" >&2
  exit 1
fi

valid_ratios=("1:1" "2:3" "3:2" "3:4" "4:3" "4:5" "5:4" "9:16" "16:9" "21:9")
ratio_ok=false
for r in "${valid_ratios[@]}"; do
  [[ "$r" == "$ASPECT_RATIO" ]] && ratio_ok=true
done
if ! $ratio_ok; then
  echo "ERROR: Invalid aspect ratio '$ASPECT_RATIO'. Valid: ${valid_ratios[*]}" >&2
  exit 1
fi

valid_sizes=("1K" "2K" "4K")
size_ok=false
for s in "${valid_sizes[@]}"; do
  [[ "$s" == "$SIZE" ]] && size_ok=true
done
if ! $size_ok; then
  echo "ERROR: Invalid size '$SIZE'. Valid: ${valid_sizes[*]}" >&2
  exit 1
fi

# --- Prepare output ---
mkdir -p "$OUTPUT_DIR"

TIMESTAMP=$(date +%Y%m%d-%H%M%S)
SANITIZED=$(echo "$PROMPT" | tr -cs '[:alnum:]-' '_' | cut -c1-50 | sed 's/_$//')
OUTPUT_FILE="$OUTPUT_DIR/${TIMESTAMP}-${SANITIZED}.png"

echo "Generating image..." >&2
echo "  Model: $MODEL" >&2
echo "  Prompt: $PROMPT" >&2
echo "  Aspect Ratio: $ASPECT_RATIO" >&2
echo "  Size: $SIZE" >&2

# --- Build request JSON ---
# Use jq to safely escape the prompt string
REQUEST_JSON=$(jq -n \
  --arg prompt "$PROMPT" \
  --arg ratio "$ASPECT_RATIO" \
  --arg size "$SIZE" \
  '{
    contents: [{parts: [{text: $prompt}]}],
    generationConfig: {
      responseModalities: ["TEXT", "IMAGE"],
      imageConfig: {
        aspectRatio: $ratio,
        imageSize: $size
      }
    }
  }')

# --- Call Gemini API ---
API_URL="https://generativelanguage.googleapis.com/v1beta/models/${MODEL}:generateContent"

HTTP_RESPONSE=$(mktemp)
HTTP_CODE=$(curl -s -w "%{http_code}" -o "$HTTP_RESPONSE" -X POST "$API_URL" \
  -H "Content-Type: application/json" \
  -H "x-goog-api-key: $GEMINI_API_KEY" \
  -d "$REQUEST_JSON")

RESPONSE_BODY=$(cat "$HTTP_RESPONSE")
rm -f "$HTTP_RESPONSE"

if [[ "$HTTP_CODE" != "200" ]]; then
  echo "ERROR: API request failed (HTTP $HTTP_CODE)" >&2
  ERROR_MSG=$(echo "$RESPONSE_BODY" | jq -r '.error.message // empty' 2>/dev/null)
  if [[ -n "$ERROR_MSG" ]]; then
    echo "  $ERROR_MSG" >&2
  fi
  case "$HTTP_CODE" in
    400) echo "  Bad request — check prompt or parameters" >&2 ;;
    401|403) echo "  Authentication failed — check your API key" >&2 ;;
    429) echo "  Rate limit exceeded — wait and retry" >&2 ;;
    500|503) echo "  Server error — try again later" >&2 ;;
  esac
  exit 1
fi

# --- Extract image data ---
IMAGE_DATA=$(echo "$RESPONSE_BODY" | jq -r '
  .candidates[0].content.parts[]
  | select(.inlineData)
  | .inlineData.data
' 2>/dev/null | head -1)

if [[ -z "$IMAGE_DATA" ]] || [[ "$IMAGE_DATA" == "null" ]]; then
  # Try alternate field name (inline_data vs inlineData)
  IMAGE_DATA=$(echo "$RESPONSE_BODY" | jq -r '
    .candidates[0].content.parts[]
    | select(.inline_data)
    | .inline_data.data
  ' 2>/dev/null | head -1)
fi

if [[ -z "$IMAGE_DATA" ]] || [[ "$IMAGE_DATA" == "null" ]]; then
  echo "ERROR: No image data in response." >&2
  TEXT_MSG=$(echo "$RESPONSE_BODY" | jq -r '.candidates[0].content.parts[] | select(.text) | .text' 2>/dev/null | head -1)
  if [[ -n "$TEXT_MSG" ]] && [[ "$TEXT_MSG" != "null" ]]; then
    echo "  API message: $TEXT_MSG" >&2
  fi
  exit 1
fi

# --- Save image ---
echo "$IMAGE_DATA" | base64 -d > "$OUTPUT_FILE"

if [[ ! -s "$OUTPUT_FILE" ]]; then
  echo "ERROR: Saved file is empty." >&2
  rm -f "$OUTPUT_FILE"
  exit 1
fi

FILE_SIZE=$(du -h "$OUTPUT_FILE" | cut -f1)
echo "Image saved: $OUTPUT_FILE ($FILE_SIZE)" >&2

# Output path on stdout for Claude to read
echo "$OUTPUT_FILE"
