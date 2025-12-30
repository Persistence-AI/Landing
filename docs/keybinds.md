---
layout: default
title: Keybinds
permalink: /docs/keybinds.html
---

# Keybinds

PersistenceAI has a comprehensive list of keybinds that you can customize through the PersistenceAI config.

## Leader Key

PersistenceAI uses a `leader` key for most keybinds. This avoids conflicts in your terminal.

By default, `Ctrl+X` is the leader key and most actions require you to first press the leader key and then the shortcut. For example, to start a new session you first press `Ctrl+X` and then press `N`.

## Configuration

Keybinds can be customized in your configuration file (`pai.json` or `pai.jsonc`):

```json
{
  "keybinds": {
    "leader": "ctrl+x",
    "app_exit": "ctrl+c,ctrl+d,<leader>q",
    "editor_open": "<leader>e",
    "theme_list": "<leader>t",
    "sidebar_toggle": "<leader>b",
    "username_toggle": "none",
    "status_view": "<leader>s",
    "session_export": "<leader>x",
    "session_new": "<leader>n",
    "session_list": "<leader>l",
    "session_timeline": "<leader>g",
    "session_share": "none",
    "session_unshare": "none",
    "session_interrupt": "escape",
    "session_compact": "<leader>c",
    "session_child_cycle": "<leader>+right",
    "session_child_cycle_reverse": "<leader>+left",
    "messages_page_up": "pageup",
    "messages_page_down": "pagedown",
    "messages_half_page_up": "ctrl+alt+u",
    "messages_half_page_down": "ctrl+alt+d",
    "messages_first": "ctrl+g,home",
    "messages_last": "ctrl+alt+g,end",
    "messages_copy": "<leader>y",
    "messages_undo": "<leader>u",
    "messages_redo": "<leader>r",
    "messages_last_user": "none",
    "messages_toggle_conceal": "<leader>h",
    "model_list": "<leader>m",
    "model_cycle_recent": "f2",
    "model_cycle_recent_reverse": "shift+f2",
    "command_list": "ctrl+p",
    "agent_list": "<leader>a",
    "agent_cycle": "tab",
    "agent_cycle_reverse": "shift+tab",
    "input_clear": "ctrl+c",
    "input_paste": "ctrl+v",
    "input_submit": "enter",
    "input_newline": "shift+enter,ctrl+j",
    "history_previous": "up",
    "history_next": "down"
  }
}
```

## Leader Key Syntax

- `<leader>` - Replaced with the leader key (default: `Ctrl+X`)
- Example: `<leader>N` = `Ctrl+X` then `N`

## Multiple Keybind Options

Some keybinds support multiple options (comma-separated):

```json
{
  "app_exit": "ctrl+c,ctrl+d,<leader>q",
  "input_newline": "shift+return,ctrl+j"
}
```

The first matching keybind will be used.

## Disabling Keybinds

Set a keybind to `"none"` to disable it:

```json
{
  "session_share": "none",
  "username_toggle": "none"
}
```

---

## Application-Level Keybinds

### Application Control

| Keybind | Default | Description |
|---------|---------|-------------|
| `app_exit` | `Ctrl+C`, `Ctrl+D`, `<leader>Q` | Exit the application |
| `terminal_suspend` | `Ctrl+Z` | Suspend terminal (send SIGTSTP) |

### Session Management

| Keybind | Default | Description |
|---------|---------|-------------|
| `session_new` | `<leader>N` | Create a new session |
| `session_list` | `<leader>L` | List all sessions |
| `session_export` | `<leader>X` | Export session to editor |
| `session_timeline` | `<leader>G` | Show session timeline |
| `session_share` | `none` | Share current session |
| `session_unshare` | `none` | Unshare current session |
| `session_interrupt` | `Escape` | Interrupt current session |
| `session_compact` | `<leader>C` | Compact the session |
| `session_child_cycle` | `<leader>→` (Right Arrow) | Next child session |
| `session_child_cycle_reverse` | `<leader>←` (Left Arrow) | Previous child session |

### Message Navigation

| Keybind | Default | Description |
|---------|---------|-------------|
| `messages_page_up` | `PageUp` | Scroll messages up by one page |
| `messages_page_down` | `PageDown` | Scroll messages down by one page |
| `messages_half_page_up` | `Ctrl+Alt+U` | Scroll messages up by half page |
| `messages_half_page_down` | `Ctrl+Alt+D` | Scroll messages down by half page |
| `messages_first` | `Ctrl+G, Home` | Navigate to first message |
| `messages_last` | `Ctrl+Alt+G, End` | Navigate to last message |
| `messages_last_user` | `none` | Navigate to last user message |
| `messages_copy` | `<leader>Y` | Copy message |
| `messages_undo` | `<leader>U` | Undo message |
| `messages_redo` | `<leader>R` | Redo message |
| `messages_toggle_conceal` | `<leader>H` | Toggle code block concealment in messages |

### Agent & Model Management

| Keybind | Default | Description |
|---------|---------|-------------|
| `agent_list` | `<leader>A` | List agents |
| `agent_cycle` | `Tab` | Next agent |
| `agent_cycle_reverse` | `Shift+Tab` | Previous agent |
| `model_list` | `<leader>M` | List available models |
| `model_cycle_recent` | `F2` | Next recently used model |
| `model_cycle_recent_reverse` | `Shift+F2` | Previous recently used model |

### Input/Prompt Keybindings

| Keybind | Default | Description |
|---------|---------|-------------|
| `input_clear` | `Ctrl+C` | Clear input field |
| `input_paste` | `Ctrl+V` | Paste from clipboard |
| `input_submit` | `Enter` | Submit input |
| `input_newline` | `Shift+Enter`, `Ctrl+J` | Insert newline in input |
| `history_previous` | `↑` (Up Arrow) | Previous history item |
| `history_next` | `↓` (Down Arrow) | Next history item |

### Commands & Dialogs

| Keybind | Default | Description |
|---------|---------|-------------|
| `command_list` | `Ctrl+P` | List available commands |
| `editor_open` | `<leader>E` | Open external editor |
| `theme_list` | `<leader>T` | List available themes |
| `sidebar_toggle` | `<leader>B` | Toggle sidebar |
| `status_view` | `<leader>S` | View status |
| `scrollbar_toggle` | `none` | Toggle session scrollbar |
| `username_toggle` | `none` | Toggle username visibility |
| `tool_details` | `none` | Toggle tool details visibility |

---

## Editor Pane Keybindings

These shortcuts work when the editor is focused.

### File Operations

| Shortcut | Action | Description |
|----------|--------|-------------|
| `Ctrl+S` | Save file | Saves the current file (only if modified) |
| `Ctrl+F` | Toggle search | Opens/closes the search bar |
| `Escape` | Close search | Closes search bar when search is visible |

### Undo/Redo

| Shortcut | Action | Description |
|----------|--------|-------------|
| `Ctrl+Z` | Undo | Undo last change (per-file history) |
| `Ctrl+Y` | Redo | Redo last undone change |
| `Ctrl+Shift+Z` | Redo | Alternative redo shortcut |

---

## Workspace & Editor Toggle Shortcuts

These shortcuts work globally (when no dialog is open).

| Shortcut | Action | Description |
|----------|--------|-------------|
| `Ctrl+B` | Toggle workspace | Show/hide file explorer pane |
| `Ctrl+E` | Toggle editor | Show/hide editor pane |

**Note**: When workspace is toggled on, it automatically refreshes the file tree.

---

## Pane Resize Shortcuts

### Workspace Resize (when workspace visible)

| Shortcut | Action | Description |
|----------|--------|-------------|
| `Shift+Left` | Shrink workspace | Decrease workspace width by 2 characters (min: 15) |
| `Shift+Right` | Expand workspace | Increase workspace width by 2 characters (max: 50) |
| `Ctrl+Shift+Left` | Shrink workspace | Alternative: Decrease workspace width by 2 characters |
| `Ctrl+Shift+Right` | Expand workspace | Alternative: Increase workspace width by 2 characters |

### Editor Resize (when editor visible)

| Shortcut | Action | Description |
|----------|--------|-------------|
| `Ctrl+Shift+,` (Comma) | Shrink editor | Decrease editor width by 5 characters (min: 30) |
| `Ctrl+Shift+.` (Period) | Expand editor | Increase editor width by 5 characters (max: screen width - 50) |

---

## Special Features

### @ File Search

Press `@` in the chat input to fuzzy search for files and agents in your project.

- Type `@` followed by a filename or path
- Use arrow keys to navigate suggestions
- Press `Enter` to select
- Works for both files and agents

Example:
```
How does authentication work in @src/auth/login.ts
```

### Command Palette

Press `Ctrl+P` to open the command palette with all available commands.

---

## Quick Reference

### Most Used Shortcuts

**Editor:**
- `Ctrl+S` - Save file
- `Ctrl+F` - Search
- `Ctrl+Z` - Undo
- `Ctrl+Y` - Redo

**Workspace:**
- `Ctrl+B` - Toggle workspace
- `Ctrl+E` - Toggle editor
- `Shift+←/→` - Resize workspace

**Chat:**
- `Enter` - Submit message
- `Shift+Enter` - Newline
- `Ctrl+P` - Command palette
- `↑/↓` - History navigation
- `@` - File/agent search

**Session:**
- `<leader>N` (default: `Ctrl+X N`) - New session
- `<leader>L` (default: `Ctrl+X L`) - List sessions
- `Escape` - Interrupt session

**Navigation:**
- `PageUp/PageDown` - Scroll messages
- `<leader>→/←` - Navigate child sessions
- `Tab/Shift+Tab` - Cycle agents

---

## Notes

1. **Leader Key**: Most keybinds use the leader key (`Ctrl+X` by default) to avoid conflicts with terminal shortcuts.

2. **Focus Context**: Some shortcuts only work when specific components are focused:
   - Editor shortcuts only work when editor pane is focused
   - Input shortcuts only work when chat input is focused
   - Message navigation works globally (when no dialog is open)

3. **Dialog Priority**: When a dialog is open, most global shortcuts are disabled to prevent conflicts.

4. **Hardcoded vs Configurable**:
   - **Configurable**: Most application-level keybinds (session, messages, agents, etc.)
   - **Hardcoded**: Editor pane shortcuts, workspace/editor toggles, resize shortcuts

---

For a complete reference, see the [Full Keybindings Reference](https://github.com/Persistence-AI/PersistenceCLI/blob/main/Persistencedev/ALL_KEYBINDINGS_REFERENCE.md).
