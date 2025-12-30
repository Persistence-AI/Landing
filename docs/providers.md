---
layout: default
title: Providers
permalink: /docs/providers.html
---

# Providers

PersistenceAI supports multiple LLM providers. You can configure API keys for any provider you want to use.

## Connecting a Provider

1. Run the `/connect` command in the TUI
2. Select a provider from the list
3. Follow the provider-specific authentication steps
4. Enter your API key when prompted

```
/connect
```

## Supported Providers

PersistenceAI supports all major LLM providers:

- **OpenAI** - GPT-4, GPT-3.5, and more
- **Anthropic** - Claude models
- **Google** - Gemini models
- **Ollama** - Local models (self-hosted)
- **PersistenceAI Zen** - Curated list of tested models
- And many more...

## Provider Configuration

Provider configurations are stored in your global config file:

- **Windows**: `%USERPROFILE%\.config\pai\pai.json`
- **Linux/macOS**: `~/.config/pai/pai.json`

### Example Configuration

```json
{
  "providers": {
    "openai": {
      "apiKey": "sk-..."
    },
    "anthropic": {
      "apiKey": "sk-ant-..."
    },
    "ollama": {
      "baseURL": "http://localhost:11434"
    }
  }
}
```

## Ollama (Self-Hosted)

PersistenceAI has excellent support for Ollama, allowing you to run models locally without API costs.

### Setup

1. Install Ollama from [ollama.ai](https://ollama.ai)
2. Pull the models you want to use:
   ```bash
   ollama pull llama2
   ollama pull codellama
   ```
3. Connect to Ollama in PersistenceAI:
   ```
   /connect
   ```
   Select "Ollama" and enter your base URL (default: `http://localhost:11434`)

### Recommended Models

- **cogito:3b** - Fast, lightweight for simple tasks
- **qwen2.5-coder:4b** - Good balance of speed and capability
- **qwen2.5-coder:7b** - More capable for complex tasks
- **qwen2.5-coder:13b+** - Maximum capability

## PersistenceAI Zen

PersistenceAI Zen is a curated list of models that have been tested and verified by the PersistenceAI team.

1. Run `/connect` and select "PersistenceAI Zen"
2. Visit the authentication page
3. Sign in and get your API key
4. Paste the key in PersistenceAI

## Model Selection

You can switch between models using:

- **Keyboard**: `F2` to cycle through recently used models
- **Command**: `/models` to see all available models
- **Shortcut**: `<leader>M` (default: `Ctrl+X M`)

## Provider-Specific Notes

### OpenAI

- Requires API key from [platform.openai.com](https://platform.openai.com)
- Supports GPT-4, GPT-3.5, and other models
- Usage-based billing

### Anthropic

- Requires API key from [console.anthropic.com](https://console.anthropic.com)
- Supports Claude 3 models
- Usage-based billing

### Google

- Requires API key from [Google AI Studio](https://makersuite.google.com/app/apikey)
- Supports Gemini models
- Usage-based billing

### Ollama

- Free and self-hosted
- No API key required
- Runs models locally on your machine
- Best for privacy-sensitive projects

---

For more information, see:
- [Configuration](./config.md) - Full configuration options
- [Models](./models.md) - Model selection and usage
