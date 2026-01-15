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

### Package Management via Dotfiles

Each language has its own default package file that asdf reads automatically. These files are managed in the dotfiles repository and symlinked by the dotfiles role:

| Language | Dotfiles Source | Symlink Target | Package Manager |
|----------|----------------|----------------|-----------------|
| Ruby | `dotfiles/asdf/default-gems` | `~/.default-gems` | gem |
| Node.js | `dotfiles/asdf/default-npm-packages` | `~/.default-npm-packages` | npm |
| Python | `dotfiles/asdf/default-python-packages` | `~/.default-python-packages` | pip |
| Elixir | `dotfiles/asdf/default-elixir-packages` | `~/.default-elixir-packages` | mix |
| Go | `dotfiles/asdf/default-golang-packages` | `~/.default-golang-packages` | go install |
| Rust | `dotfiles/asdf/default-cargo-crates` | `~/.default-cargo-crates` | cargo |

### Package Installation

When `asdf install <language> <version>` runs (either manually or via `asdf install`), asdf automatically:
1. Installs the language version
2. Reads the corresponding `~/.default-*` file
3. Installs all listed packages for that language version

### Example Package Files

Package files contain one package per line:

```
# dotfiles/asdf/default-gems
solargraph
rubocop
ruby-lsp
```

```
# dotfiles/asdf/default-npm-packages
typescript
typescript-language-server
eslint
prettier
```

To modify packages:
1. Edit the file in the dotfiles repository
2. Commit and push changes
3. Re-run the Ansible playbook (dotfiles will be updated, but existing versions won't reinstall)
4. For existing versions, manually run: `asdf reshim <language>` or reinstall the version

## Task Orchestration

### Playbook Execution Order

```yaml
# 1. Dotfiles role runs first
- name: Include dotfiles role
  include_role:
    name: dotfiles
  # Clones dotfiles repo and symlinks:
  # - dotfiles/asdf/tool-versions → ~/.tool-versions
  # - dotfiles/asdf/default-* → ~/.default-*

# 2. asdf role runs after dotfiles
- name: Include asdf role
  include_role:
    name: asdf
```

### asdf Role Task Flow

```yaml
# roles/asdf/tasks/main.yml
- name: Install asdf
  include_tasks: install.yml
  tags: ['asdf', 'asdf:install']

- name: Configure shell initialization
  include_tasks: configure-shell.yml
  tags: ['asdf', 'asdf:shell']

- name: Install language versions from .tool-versions
  include_tasks: versions.yml
  tags: ['asdf', 'asdf:versions']
```

### versions.yml Implementation

```yaml
- name: Check if .tool-versions file exists
  stat:
    path: "{{ ansible_env.HOME }}/.tool-versions"
  register: tool_versions_file

- name: Install all language versions from .tool-versions
  command: asdf install
  args:
    chdir: "{{ ansible_env.HOME }}"
  when: tool_versions_file.stat.exists
  register: asdf_install_result
  changed_when: "'Installing' in asdf_install_result.stdout or 'Installing' in asdf_install_result.stderr"
  failed_when: false
```

The `versions.yml` task:
- Only runs if `.tool-versions` exists (meaning dotfiles were cloned)
- Runs `asdf install` from the home directory
- asdf automatically installs plugins, versions, and default packages

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

# New - no variables needed!
- role: dotfiles  # Must run before asdf
- role: asdf      # Reads config from dotfiles
```

### Migration Safety

- asdf and rbenv can coexist temporarily (different PATH)
- Test on non-production first
- Manual cleanup: Remove rbenv/nvm from dotfiles if initialized outside ansible
- Run `asdf reshim` after migration

## Variables

### No Variables Required

The asdf role requires no variables. All configuration is managed in the dotfiles repository:

- **Language versions**: Defined in `dotfiles/asdf/tool-versions`
- **Default packages**: Defined in `dotfiles/asdf/default-*` files
- **Plugins**: Automatically detected and installed by asdf based on `.tool-versions`

### Future Extensions

If needed, the `roles/asdf/defaults/main.yml` file can be used for:
- Conditional behavior flags
- Platform-specific overrides
- Optional feature toggles

Currently, it remains empty as the implementation requires no configuration.

## Benefits

✅ **Single tool**: All language version management through asdf
✅ **Consistent approach**: Same workflow for Ruby, Node, Python, Go, Rust, etc.
✅ **No duplication**: Configuration lives in dotfiles, not Ansible variables
✅ **Single source of truth**: Dotfiles repository is the authoritative config source
✅ **Version controlled**: All asdf configuration tracked in git
✅ **Automatic installation**: `asdf install` handles plugins, versions, and packages
✅ **Idempotent**: Safe to re-run playbook multiple times
✅ **Platform-aware**: Works on macOS and Debian
✅ **Simple**: Minimal Ansible code, maximum functionality
✅ **Easy updates**: Edit dotfiles and re-run playbook

## Implementation Status

### Completed (2026-01-15)

✅ Created asdf role with:
  - `install.yml` - Installs asdf via Homebrew (macOS) or apt (Debian)
  - `configure-shell.yml` - Configures zsh/bash integration
  - `versions.yml` - Runs `asdf install` to install versions from `.tool-versions`

✅ Updated dotfiles role to:
  - Symlink `dotfiles/asdf/tool-versions` → `~/.tool-versions`
  - Symlink `dotfiles/asdf/default-*` → `~/.default-*`

✅ Updated playbook execution order:
  - Dotfiles role runs first (clones and symlinks configuration)
  - asdf role runs second (installs asdf and runs `asdf install`)

### Remaining Tasks

- [ ] Test on clean system
- [ ] Update README with asdf usage documentation
- [ ] Verify all languages install correctly
- [ ] Remove old rbenv/nvm roles (if they exist)
- [ ] Update any remaining playbook references to rbenv/nvm
