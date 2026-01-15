# asdf Migration Design

**Date:** 2026-01-07
**Status:** Implemented
**Updated:** 2026-01-15

## Overview

Migrate from rbenv and nvm to asdf for unified language version management. The asdf role handles installation and shell configuration, while all version and package configuration is managed through the dotfiles repository.

## Goals

- Replace rbenv (Ruby) and nvm (Node.js) with asdf
- Support all languages from `.tool-versions`: Ruby, Node.js, Erlang, Elixir, Java, Python, R, Zig, .NET, Istio, Maven, Gradle, Go, Rust
- Manage default packages for Ruby, Node.js, Python, Elixir, Go, and Rust
- Focus on LSP and linting tools for development environments
- Support both macOS (Darwin) and Debian platforms
- Clean up old version manager roles completely

## Architecture

### Actual Implementation Structure

```
roles/asdf/
├── tasks/
│   ├── main.yml              # Orchestrates all tasks
│   ├── install.yml           # Install asdf via package manager
│   ├── configure-shell.yml   # Setup .bashrc and .zshrc
│   └── versions.yml          # Run `asdf install` from .tool-versions
└── defaults/
    └── main.yml             # Empty (for future extensions)

roles/dotfiles/
└── tasks/
    └── main.yml             # Symlinks .tool-versions and default-* files
```

### Configuration Files (Managed in dotfiles repository)

All asdf configuration lives in the separate `dotfiles` repository:

```
dotfiles/asdf/
├── tool-versions                    # Language versions (symlinked to ~/.tool-versions)
├── default-gems                     # Ruby gems (symlinked to ~/.default-gems)
├── default-npm-packages             # Node packages (symlinked to ~/.default-npm-packages)
├── default-python-packages          # Python packages (symlinked to ~/.default-python-packages)
├── default-elixir-packages          # Elixir packages (symlinked to ~/.default-elixir-packages)
├── default-golang-packages          # Go packages (symlinked to ~/.default-golang-packages)
└── default-cargo-crates             # Rust crates (symlinked to ~/.default-cargo-crates)
```

## Installation & Configuration

### Installation Method

- **macOS (Darwin)**: Install via Homebrew (`brew install asdf`)
- **Debian**: Install via apt (`apt install asdf`)
- Idempotent: Check if asdf exists before attempting installation

### Shell Configuration

**For .zshrc (via ohmyzsh):**
- Add `asdf` to the plugins array
- ohmyzsh handles loading automatically

**For .bashrc:**
- Source asdf based on platform:
  - macOS: `/opt/homebrew/opt/asdf/libexec/asdf.sh`
  - Debian: `/usr/share/asdf/asdf.sh`
- Use `lineinfile` for idempotency

## Language Management

### Workflow

1. **Dotfiles role** clones the dotfiles repository and symlinks configuration files:
   - `dotfiles/asdf/tool-versions` → `~/.tool-versions`
   - `dotfiles/asdf/default-*` → `~/.default-*`

2. **asdf role** installs asdf, configures the shell, then runs:
   ```bash
   asdf install
   ```

3. **asdf automatically**:
   - Reads `.tool-versions` to determine which languages and versions to install
   - Installs plugins on-demand as needed for each language
   - Installs the specified versions
   - Installs default packages from `~/.default-*` files for each new language version

### No Ansible Variables Required

All configuration (versions, packages, plugins) is managed in the dotfiles repository. The Ansible roles just:
- Install asdf
- Configure shell integration
- Symlink dotfiles
- Run `asdf install`

This approach provides:
- Version control for all asdf configuration
- Easy updates (just edit dotfiles and re-run playbook)
- No duplication between Ansible and dotfiles
- Single source of truth in dotfiles repository

## Default Packages

### Package Sources & Installation

Each language has its own default package file that asdf reads automatically:

| Language | File | Package Manager | Auto-installed by asdf |
|----------|------|----------------|----------------------|
| Ruby | `~/.default-gems` | gem | Yes |
| Node.js | `~/.default-npm-packages` | npm | Yes |
| Python | `~/.default-python-packages` | pip | Yes |
| Elixir | `~/.default-elixir-packages` | mix | Yes |
| Go | `~/.default-golang-packages` | go install | Yes |
| Rust | `~/.default-cargo-crates` | cargo | Yes |

### Template Structure

All templates follow the same pattern:

```jinja
# Base packages (always installed)
{% for pkg in default_<lang>_base %}
{{ pkg }}
{% endfor %}

# Optional packages (from playbook variables)
{% if default_<lang>_optional is defined %}
{% for pkg in default_<lang>_optional %}
{{ pkg }}
{% endfor %}
{% endif %}
```

This allows:
- **Base defaults**: Standard packages everyone gets
- **Optional additions**: Playbook-specific extras

### Base Package Lists

Focus on LSP servers, linters, and formatters:

**Ruby (gem):**
- solargraph (Ruby LSP)
- rubocop (Linter/formatter)
- ruby-lsp (Alternative LSP)

**Node.js (npm):**
- typescript
- typescript-language-server
- vscode-langservers-extracted (HTML/CSS/JSON LSPs)
- eslint
- prettier

**Python (pip):**
- python-lsp-server
- pylsp-mypy (Type checking)
- python-lsp-black (Formatter)
- pylsp-rope (Refactoring)
- ruff (Linter)

**Elixir (asdf built-in):**
- elixir_ls (Elixir LSP)

**Go (go install):**
- golang.org/x/tools/gopls@latest
- github.com/golangci/golangci-lint/cmd/golangci-lint@latest
- mvdan.cc/gofumpt@latest

**Rust (cargo):**
- rust-analyzer
- clippy (may be built-in)
- rustfmt (may be built-in)

**Java:**
- Commented out - most Java LSPs install via editor plugins, not Maven

## Task Orchestration

Main task flow with tags for selective execution:

```yaml
- name: Install asdf
  include_tasks: install.yml
  tags: ['asdf', 'asdf:install']

- name: Configure shell initialization
  include_tasks: configure-shell.yml
  tags: ['asdf', 'asdf:shell']

- name: Install asdf plugins
  include_tasks: plugins.yml
  tags: ['asdf', 'asdf:plugins']

- name: Install language versions
  include_tasks: versions.yml
  tags: ['asdf', 'asdf:versions']

- name: Deploy default package configurations
  include_tasks: default-packages.yml
  tags: ['asdf', 'asdf:packages']
```

## Migration & Cleanup

### Roles to Remove

- `roles/rbenv/` - Delete entirely
- `roles/nvm/` - Delete entirely

### Playbook Updates

Find references:
```bash
rg "(rbenv|nvm)" --type yaml
```

Replace with asdf role:
```yaml
# Old
- role: rbenv
  vars:
    ruby_versions: ["3.2.0"]
    ruby_default: "3.2.0"

# New
- role: asdf
  vars:
    local_tool_versions_path: /Users/jvargas/.tool-versions
```

### Migration Safety

- asdf and rbenv can coexist temporarily (different PATH)
- Test on non-production first
- Manual cleanup: Remove rbenv/nvm from dotfiles if initialized outside ansible
- Run `asdf reshim` after migration

## Variables

### defaults/main.yml

```yaml
asdf_plugins:
  - ruby
  - nodejs
  - erlang
  - elixir
  - java
  - python
  - R
  - zig
  - dotnet
  - istioctl
  - maven
  - gradle
  - golang
  - rust

# Optional: Path to existing .tool-versions
# local_tool_versions_path: /Users/jvargas/.tool-versions
```

### vars/main.yml

Contains all `default_<lang>_base` lists (see Base Package Lists section above).

### Optional Playbook Variables

```yaml
# Add extras per playbook
default_gems_optional:
  - rails
  - pry

default_npm_optional:
  - webpack
  - jest
```

## Benefits

✅ Single tool for all language version management
✅ Consistent approach across Ruby, Node, Python, Go, Rust, etc.
✅ Automatic default package installation
✅ LSP and linting tools included by default
✅ Easy to extend (just add plugin + version)
✅ Idempotent and safe to re-run
✅ Platform-aware (macOS and Debian)
✅ Flexible (base + optional packages)

## Post-Implementation

- Update main playbook to use asdf role
- Update README with asdf usage
- Add multiple Ruby versions to `.tool-versions` (3.4, 3.3, 3.2)
- Test on clean system before deploying widely
