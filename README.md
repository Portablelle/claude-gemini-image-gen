# Gemini Image Generation — Claude Code Plugin

Generate images using Google Gemini API directly from Claude Code. Supports **gemini-3-pro-image-preview** (high quality) and **gemini-2.5-flash-image** (fast).

## Installation

```
/plugin install gemini-image-gen@gemini-image-gen
```

Then run `/setup-gemini` to configure your API key.

## Setup

1. Get a Gemini API key from [Google AI Studio](https://aistudio.google.com/apikey)
2. Run `/setup-gemini` in Claude Code
3. Follow the interactive setup

Or manually create `~/.gemini-config`:
```bash
export GEMINI_API_KEY="your-key-here"
```

## Usage

Just ask Claude naturally:

- *"Generate an image of a sunset over mountains"*
- *"Crée une illustration d'un chat astronaute"*
- *"Create a landscape picture of a futuristic city in 4K"*

The skill auto-triggers when you ask to generate, create, or draw images.

## Options

| Option | Values | Default |
|--------|--------|---------|
| Model | `gemini-3-pro-image-preview`, `gemini-2.5-flash-image` | `gemini-3-pro-image-preview` |
| Aspect Ratio | `1:1`, `16:9`, `9:16`, `4:3`, `3:4`, `21:9`, etc. | `1:1` |
| Size | `1K`, `2K`, `4K` | `2K` |

Natural language mappings:
- "landscape" / "paysage" → 16:9
- "portrait" / "vertical" → 9:16
- "high quality" / "haute qualité" → 4K
- "quick" / "rapide" → gemini-2.5-flash-image + 1K

## Output

Images are saved to `~/generated-images/` with descriptive filenames:
```
~/generated-images/20260216-153000-a_sunset_over_mountains.png
```

## Security

- API key stored locally in `~/.gemini-config` with `chmod 600`
- Never committed to git
- Images saved locally only

## License

MIT
