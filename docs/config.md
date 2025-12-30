---
layout: default
title: Configuration
permalink: /docs/config.html
---

# Configuration

PersistenceAI can be configured through a JSON configuration file.

## Configuration File Location

- **Windows**: `%USERPROFILE%\.config\pai\pai.json`
- **Linux/macOS**: `~/.config/pai/pai.json`

You can also use `pai.jsonc` (JSON with Comments) for better readability.

## Configuration Structure

```json
{
  "keybinds": {
    "leader": "ctrl+x",
    "session_new": "<leader>n"
  },
  "providers": {
    "openai": {
      "apiKey": "sk-..."
    }
  },
  "agents": [],
  "theme": "default",
  "models": {
    "default": "openai/gpt-4"
  }
}
```

## Keybind Configuration

See the [Keybinds documentation](./keybinds.md) for detailed keybind configuration.

## Provider Configuration

See the [Providers documentation](./providers.md) for provider setup.

## Agent Configuration

See the [Agents documentation](./agents.md) for agent configuration.

## Theme Configuration

Set your preferred theme:

```json
{
  "theme": "opencode"
}
```

Available themes:
- `opencode` (default)
- `dark`
- `light`
- And more...

## Model Configuration

Set default models:

```json
{
  "models": {
    "default": "openai/gpt-4",
    "small": "cogito:3b",
    "medium": "qwen2.5-coder:4b",
    "large": "qwen2.5-coder:7b"
  }
}
```

## Project-Specific Configuration

You can also create a project-specific config file:

- `pai.json` in your project root
- `pai.jsonc` in your project root

Project configs override global configs.

---

For more information, see:
- [Keybinds](./keybinds.md) - Keyboard shortcuts
- [Providers](./providers.md) - LLM provider setup
- [Agents](./agents.md) - Agent configuration
