---
name: image-generation
description: This skill should be used when the user asks to "generate an image", "create a picture", "make an illustration", "draw something", "create artwork", "génère une image", "crée une illustration", "dessine", "fais une image", or discusses creating visual content, pictures, photos, or artwork using AI image generation.
---

# Image Generation via Gemini API

You have access to Google Gemini's image generation API through a bash script. When the user asks you to generate, create, draw, or make an image/picture/illustration/artwork, follow these steps.

## Step 1: Extract the prompt

Take the user's description and craft a detailed, effective image generation prompt in English. Enhance the prompt with relevant details (style, lighting, composition) while staying true to the user's intent.

## Step 2: Determine options

Map the user's preferences to technical parameters:

| User says | Parameter |
|-----------|-----------|
| "landscape", "paysage", "wide" | `--aspect-ratio 16:9` |
| "portrait", "vertical", "tall" | `--aspect-ratio 9:16` |
| "square", "carré" | `--aspect-ratio 1:1` (default) |
| "ultrawide", "cinematic", "panoramique" | `--aspect-ratio 21:9` |
| "high quality", "haute qualité", "detailed", "4K" | `--size 4K` |
| "standard", "normal" | `--size 2K` (default) |
| "quick", "fast", "rapide", "draft" | `--model gemini-2.5-flash-image --size 1K` |

If no preference is specified, use defaults (1:1, 2K, gemini-3-pro-image-preview).

## Step 3: Generate the image

Run the generation script. The prompt MUST be passed as a single quoted argument:

```bash
bash ~/.claude/plugins/cache/gemini-image-gen/gemini-image-gen/*/scripts/generate-image.sh '<enhanced prompt>' --aspect-ratio <ratio> --size <size>
```

Example:
```bash
bash ~/.claude/plugins/cache/gemini-image-gen/gemini-image-gen/*/scripts/generate-image.sh 'a majestic lion resting on a savanna at golden hour, photorealistic, dramatic lighting' --aspect-ratio 16:9 --size 4K
```

## Step 4: Display the result

The script outputs the file path on the last line of stdout. Use the **Read** tool to display the generated image to the user.

If the script fails, read the stderr output and help the user:
- Missing API key → suggest running `/setup-gemini`
- HTTP 429 → ask to wait and retry
- No image data → suggest rephrasing the prompt

## Step 5: Offer refinements

After displaying the image, ask if the user wants to:
- Modify the prompt and regenerate
- Change aspect ratio or quality
- Generate a variation

## Important Notes

- Always enhance the user's prompt with descriptive details for better results
- Translate non-English prompts to English for the API call (Gemini works best with English prompts)
- The script saves images to `~/generated-images/` with timestamped filenames
- For multiple images, run the script multiple times with different prompts
