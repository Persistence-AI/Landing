---
layout: default
title: Agents
permalink: /docs/agents.html
---

# Agents

PersistenceAI uses an agent system where different agents have specialized roles and capabilities.

## Overview

Agents in PersistenceAI are specialized AI assistants, each designed for specific tasks:

**Built-in Primary Agents:**
- **Build** - Default primary agent with all tools enabled for development work
- **Plan** - Restricted agent for planning and analysis (asks permission before making changes)
- **Oligarchy** - Combines build and plan agents with voting system for consensus-based decisions

**Built-in Subagents:**
- **General** - General-purpose agent for researching complex questions and executing multi-step tasks
- **Explore** - Fast agent specialized for exploring codebases (file search, code search, pattern matching)

**Custom Agents:**
You can also create custom agents (like code reviewers, debuggers, architects) through configuration. See [Agent Configuration](#agent-configuration) below.

## Switching Agents

### Using Keyboard

- **`Tab`** - Cycle to next agent
- **`Shift+Tab`** - Cycle to previous agent

### Using Command

```
/agents
```

This lists all available agents. Select one to switch.

### Using Shortcut

- **`<leader>A`** (default: `Ctrl+X A`) - List agents

## Agent Roles

Each agent has a specific role and set of skills:

### Build Agent

The default primary agent for most coding tasks. Good for:
- General code changes
- Feature implementation
- Code explanations
- Project analysis
- Full development work with all tools enabled

### Plan Agent

A restricted primary agent designed for planning and analysis. Good for:
- Code analysis without making changes
- Suggesting improvements
- Creating implementation plans
- Reviewing code structure

**Note:** Plan agent asks for permission before making any file edits or running bash commands.

### General Subagent

A general-purpose subagent for complex tasks. Good for:
- Researching complex questions
- Executing multi-step tasks
- Searching for keywords or files across the codebase
- Parallel task execution

### Explore Subagent

A fast subagent specialized for codebase exploration. Good for:
- Quickly finding files by patterns (e.g., `src/components/**/*.tsx`)
- Searching code for keywords
- Answering questions about codebase structure
- Fast codebase navigation

**Custom Agents:**
You can create custom agents like code reviewers, debuggers, or architects through configuration. See the [Agent Configuration](#agent-configuration) section for examples.

## Subagents

Subagents are specialized agents that can be invoked using `@` mentions for specific tasks. They operate independently and are designed for focused, single-purpose operations.

### Git Committer (`@git-committer`)

A specialized subagent for git operations. Use this agent when you need to commit and push code changes to a git repository.

**Usage:**
```
@git-committer commit these changes with message "Fix alignment issue in editor pane"
```

**What it does:**
- Commits code changes to your local git repository
- Pushes commits to the remote repository (typically `origin`)
- Automatically performs `git pull --rebase` if there are remote changes before pushing
- Writes commit messages with appropriate prefixes and focused on WHY the change was made

**Commit Message Format:**
Commit messages must include a prefix indicating the type of change:
- `docs:` - Documentation changes
- `tui:` - Terminal UI changes
- `core:` - Core functionality changes
- `ci:` - Continuous integration changes
- `ignore:` - Changes in packages/app
- `wip:` - Work in progress

**Special Prefix Rules:**
- For changes in `packages/web` → use `docs:` prefix
- For changes in `packages/app` → use `ignore:` prefix

**Important Notes:**
- Commit messages should be brief since they're used to generate release notes
- Messages should say **WHY** the change was made from an end-user perspective, not **WHAT** was changed
- Avoid generic messages like "improved agent experience" - be very specific about user-facing changes
- The agent automatically handles `git pull --rebase` before pushing
- If merge conflicts occur during rebase, the agent will **not** fix them automatically - it will notify you to resolve them manually
- The agent uses your repository's configured remote (check with `git remote -v`)
- Your repository must be initialized with `git init` and have a remote configured

**Examples:**
```
@git-committer commit and push with message "tui: Add workspace file filtering to @ mention feature"
@git-committer commit these changes with message "docs: Update agent documentation with git-committer details"
@git-committer commit and push with message "core: Fix memory retrieval bottleneck in LanceDBBackend"
```

## Agent Skills

Agents have access to different skills (tools) based on their role:

- **File Operations** - Read, write, modify files
- **Code Analysis** - Analyze codebase structure
- **Search** - Search code and files
- **Execution** - Run commands and scripts
- **And more...**

## Using @ Mentions

You can mention specific **subagents** in your prompts using `@`:

```
@general help me search for this function across the codebase
```

This ensures the right subagent handles your request.

**Built-in Subagents Available for @ Mentions:**
- `@general` - General-purpose agent for researching complex questions and executing multi-step tasks
- `@explore` - Fast agent specialized for exploring codebases (file search, code search, pattern matching)
- `@git-committer` - Specialized subagent for git operations (commit and push)

**Note:** Primary agents (`build`, `plan`, `oligarchy`) are switched using the **Tab** key, not @ mentions. The @ mention feature is specifically for subagents.

**Custom Agents:**
You can also create custom agents (like `@code-reviewer`, `@debugger`, `@architect`) through configuration. These will appear in the autocomplete when you type `@`.

When you type `@` in the prompt, you'll see an autocomplete list of available subagents and files in your workspace.

## Agent Configuration

Agents can be configured in your project's `AGENTS.md` file or in the global config.

### Example Agent Config

```json
{
  "agents": [
    {
      "name": "general",
      "role": "General coding assistant",
      "skills": ["file", "search", "execute"]
    }
  ]
}
```

---

For more information, see:
- [Commands](./commands.md) - Agent-related commands
- [Keybinds](./keybinds.md) - Agent switching shortcuts
- [Configuration](./config.md) - Agent configuration
