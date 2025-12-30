---
layout: default
title: Troubleshooting
permalink: /docs/troubleshooting.html
---

# Troubleshooting

Common issues and solutions for PersistenceAI.

## Installation Issues

### Install Script Fails

**Problem**: Install script fails to download or execute.

**Solutions**:
1. Check your internet connection
2. Verify the install URL is correct:
   - Linux/macOS: `https://persistence-ai.github.io/Landing/install.sh`
   - Windows: `https://persistence-ai.github.io/Landing/install.ps1`
3. Try downloading the binary directly from [Releases](https://github.com/Persistence-AI/Landing/releases)

### Binary Not Found After Installation

**Problem**: `persistenceai` command not found.

**Solutions**:
1. Verify the binary was installed:
   - Windows: `%USERPROFILE%\.persistenceai\bin\persistenceai.exe`
   - Linux/macOS: `~/.persistenceai/bin/persistenceai`
2. Check your PATH environment variable includes the install directory
3. Restart your terminal after installation

---

## Configuration Issues

### Config File Not Found

**Problem**: PersistenceAI can't find your config file.

**Solutions**:
1. Create the config directory:
   - Windows: `%USERPROFILE%\.config\pai\`
   - Linux/macOS: `~/.config/pai/`
2. Create `pai.json` with basic configuration:
   ```json
   {
     "keybinds": {},
     "providers": {}
   }
   ```

### Keybinds Not Working

**Problem**: Keyboard shortcuts don't work.

**Solutions**:
1. Check your keybind configuration in `pai.json`
2. Verify the leader key is set correctly (default: `Ctrl+X`)
3. Ensure no other application is capturing the shortcuts
4. Try resetting keybinds to defaults

---

## Provider Issues

### API Key Not Working

**Problem**: Provider authentication fails.

**Solutions**:
1. Verify your API key is correct
2. Check API key hasn't expired
3. Ensure you have sufficient credits/quota
4. Try reconnecting: `/connect`

### Ollama Connection Failed

**Problem**: Can't connect to Ollama.

**Solutions**:
1. Verify Ollama is running:
   ```bash
   ollama list
   ```
2. Check Ollama base URL (default: `http://localhost:11434`)
3. Ensure firewall isn't blocking the connection
4. Try restarting Ollama service

---

## Performance Issues

### Slow Response Times

**Problem**: PersistenceAI responds slowly.

**Solutions**:
1. Check your internet connection (for cloud providers)
2. Try a faster model (smaller models are faster)
3. For Ollama: Ensure GPU acceleration is enabled
4. Check system resources (CPU, RAM, GPU)

### High Memory Usage

**Problem**: PersistenceAI uses too much memory.

**Solutions**:
1. Use smaller models
2. Close unused sessions
3. Restart PersistenceAI periodically
4. Check for memory leaks in your terminal

---

## Feature Issues

### @ File Search Not Working

**Problem**: `@` shortcut doesn't show file suggestions.

**Solutions**:
1. Ensure you're in a project directory (not empty)
2. Run `/init` to initialize the project
3. Check file permissions
4. Verify workspace is enabled (`Ctrl+B`)

### Editor Not Opening

**Problem**: Editor pane doesn't open.

**Solutions**:
1. Press `Ctrl+E` to toggle editor
2. Check editor configuration
3. Verify file permissions
4. Try opening external editor: `<leader>E`

### Commands Not Working

**Problem**: Commands like `/undo` don't work.

**Solutions**:
1. Ensure you're in an active session
2. Check command syntax (must start with `/`)
3. Verify the command exists: `/commands`
4. Check session state (some commands require specific states)

---

## Terminal Compatibility

### Windows PowerShell Issues

**Problem**: TUI doesn't render correctly in PowerShell.

**Solutions**:
1. Use Windows Terminal instead of PowerShell 5.1
2. Update to PowerShell 7+
3. Use a modern terminal emulator (WezTerm, Alacritty)

### Terminal Not Supported

**Problem**: Terminal compatibility errors.

**Solutions**:
1. Use a modern terminal emulator:
   - WezTerm (cross-platform)
   - Alacritty (cross-platform)
   - Windows Terminal (Windows)
   - iTerm2 (macOS)
2. Check terminal supports:
   - True color
   - Unicode
   - Mouse events

---

## Getting Help

If you're still experiencing issues:

1. **Check Documentation**: Review the [full documentation](./index.md)
2. **Search Issues**: Check [GitHub Issues](https://github.com/Persistence-AI/.github/issues)
3. **Report Bug**: [Open a new issue](https://github.com/Persistence-AI/.github/issues/new?template=bug-report.yml)
4. **Community**: Join our Discord or community forums

---

## Common Error Messages

### "Provider not configured"

**Solution**: Run `/connect` to configure a provider.

### "Session not found"

**Solution**: Create a new session with `/new` or list sessions with `/session`.

### "Model not available"

**Solution**: Check model name is correct, or select from `/models`.

### "Permission denied"

**Solution**: Check file permissions and ensure PersistenceAI has access.

---

For more help, see:
- [Installation Guide](./index.md#install)
- [Configuration](./config.md)
- [Commands](./commands.md)
