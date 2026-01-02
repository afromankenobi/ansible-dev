# Playbook Execution Order

This document explains the order in which roles execute and why it matters.

## High-Level Flow

```
1. System Setup (macOS/Debian specific)
   ↓
2. Homebrew (installs packages including zsh plugins)
   ↓
3. Language Version Managers (nvm, rbenv)
   ↓
4. Oh-My-Zsh (installs framework only)
   ↓
5. Neovim
   ↓
6. Dotfiles (clones configs, installs more packages, symlinks everything)
```

## Detailed Order with Dependencies

### Phase 1: System Foundation (macOS only)
```yaml
- elliotweiser.osx-command-line-tools  # Install Xcode CLI tools
- geerlingguy.mac.homebrew             # Install Homebrew package manager
- geerlingguy.mac.dock                 # Configure macOS dock
```

**Why this order:**
- Xcode CLI tools needed before Homebrew
- Homebrew needed for everything else

### Phase 2: Language Version Managers
```yaml
- nvm     # Node Version Manager
- rbenv   # Ruby Version Manager
```

**Why this order:**
- Independent of other tools
- Can run in any order

### Phase 3: Shell Framework
```yaml
- ohmyzsh  # Install Oh-My-Zsh framework
```

**What it does:**
- Clones Oh-My-Zsh framework to `~/.oh-my-zsh`
- Does NOT install plugins (they come from Homebrew)

**Why here:**
- Needs to be before dotfiles (which symlinks .zshrc)
- After Homebrew (which installs the plugins)

### Phase 4: Editor Setup
```yaml
- neovim  # Configure Neovim
```

**Why here:**
- Relatively independent
- Before dotfiles which symlinks vim configs

### Phase 5: Dotfiles (Final Integration)
```yaml
- dotfiles  # Clone configs, install packages, symlink everything
```

**What it does:**
1. **Preflight checks** - Verify prerequisites
2. **Clone dotfiles** - Get configuration files from GitHub
3. **Install Brewfile packages** - Install via `brew bundle` from Brewfile.minimal
4. **Symlink configs** - Link vim, tmux, zsh configs
5. **Setup Doom Emacs** - Install and configure Emacs
6. **Create local configs** - Generate .zshrc.local from template

**Why last:**
- Needs Homebrew installed (to install Brewfile packages)
- Needs Oh-My-Zsh installed (zshrc references it)
- Ties everything together

## Package Installation Flow

### Zsh Plugins - Where They Come From

The zsh plugins are installed via **Homebrew**, not as Oh-My-Zsh custom plugins:

```bash
# Installed by: dotfiles role via Brewfile.minimal
brew install zsh-autosuggestions       # → /opt/homebrew/share/zsh-autosuggestions/
brew install zsh-syntax-highlighting   # → /opt/homebrew/share/zsh-syntax-highlighting/

# Sourced in zshrc as:
source $BREW_PREFIX/share/zsh-autosuggestions/zsh-autosuggestions.zsh
export ZSH_HIGHLIGHT_HIGHLIGHTERS_DIR=$BREW_PREFIX/share/zsh-syntax-highlighting/highlighters
```

**Why Homebrew instead of Oh-My-Zsh plugins:**
- Centralized package management
- Easier to update (`brew upgrade`)
- Consistent with other CLI tool installations
- Version controlled via Brewfile

## Critical Dependencies

### Must happen BEFORE dotfiles role:
- ✅ Homebrew installed (installs packages from Brewfile)
- ✅ Oh-My-Zsh installed (zshrc references $ZSH)

### Must happen AFTER dotfiles role:
- Nothing! Dotfiles is the final integration step

## Idempotency

All roles are idempotent (safe to run multiple times):

- **Homebrew**: Won't reinstall existing packages
- **Oh-My-Zsh**: Checks if already installed before cloning
- **Dotfiles**:
  - Git updates existing repo
  - Symlinks use `force: yes` to update
  - Brewfile only installs missing packages
  - Doom Emacs checks if already installed

## Testing Order

When testing on a fresh machine:

1. **Install prerequisites** (manual):
   - Xcode Command Line Tools
   - Homebrew
   - Ansible

2. **Run playbook** (automatic):
   ```bash
   ansible-playbook playbook.yml --ask-become-pass
   ```

3. **Verify in this order**:
   - Homebrew packages installed
   - Oh-My-Zsh framework present
   - Dotfiles cloned
   - Configs symlinked
   - Zsh plugins working (from Homebrew)

## Common Mistakes (Now Fixed)

### ❌ OLD: Plugins installed twice
```
ohmyzsh role:
  - Clone plugins to ~/.oh-my-zsh/custom/plugins/  ← Not used!

Brewfile:
  - Install plugins via Homebrew                   ← Used by zshrc

Result: Duplicate installations, confusion about which is used
```

### ✅ NEW: Plugins installed once
```
ohmyzsh role:
  - Only install Oh-My-Zsh framework

dotfiles role (Brewfile.minimal):
  - Install plugins via Homebrew                   ← Used by zshrc

Result: Single source of truth, clear ownership
```

## Quick Reference

| Tool | Installed By | Location | Used By |
|------|-------------|----------|---------|
| Oh-My-Zsh | ohmyzsh role | ~/.oh-my-zsh | zshrc ($ZSH variable) |
| zsh-autosuggestions | Brewfile | /opt/homebrew/share/... | zshrc (sourced) |
| zsh-syntax-highlighting | Brewfile | /opt/homebrew/share/... | zshrc (sourced) |
| zoxide | Brewfile | /opt/homebrew/bin/zoxide | zshrc (eval) |
| starship | Brewfile | /opt/homebrew/bin/starship | zshrc (eval) |
| Doom Emacs | dotfiles role | ~/.config/emacs | Direct |
| Config files | dotfiles role | ~/dotfiles → symlinks | Various tools |
