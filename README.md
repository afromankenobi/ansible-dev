# Mac Development Ansible Playbook

This playbook installs and configures most of the software I use on my Mac for web and software development. It automates:

- Cloning and symlinking dotfiles from [github.com/afromankenobi/dotfiles](https://github.com/afromankenobi/dotfiles)
- Installing Homebrew packages via Brewfile
- Installing Doom Emacs and symlinking configuration
- Setting up Oh-My-Zsh with plugins
- Configuring Vim/Neovim, Tmux, and Zsh
- Installing language version managers (rbenv, nvm, asdf)

## Installation

### Prerequisites

Before running the playbook, you need:

1. **Xcode Command Line Tools** - Required for building software on macOS
   ```bash
   xcode-select --install
   ```

2. **Homebrew** - Package manager for macOS
   ```bash
   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

   # Add Homebrew to PATH
   eval "$(/opt/homebrew/bin/brew shellenv)"
   ```

3. **Ansible** - Automation tool
   ```bash
   export PATH="$HOME/Library/Python/3.9/bin:/opt/homebrew/bin:$PATH"
   pip3 install --upgrade pip
   pip3 install ansible
   ```

4. **SSH Key for GitHub** (optional but recommended) - For cloning private repos
   ```bash
   # Generate key
   ssh-keygen -t ed25519 -C "your_email@example.com"

   # Add to GitHub: https://github.com/settings/keys
   cat ~/.ssh/id_ed25519.pub

   # Test connection
   ssh -T git@github.com
   ```

### Running the Playbook

  1. Clone this repository:
     ```bash
     git clone git@github.com:afromankenobi/ansible-dev.git
     cd ansible-dev
     ```

  2. Install required Ansible roles:
     ```bash
     ansible-galaxy install -r requirements.yml
     ```

  3. Run the playbook:
     ```bash
     ansible-playbook playbook.yml --ask-become-pass
     ```
     Enter your macOS account password when prompted for the 'BECOME' password.

### Preflight Checks

The playbook includes automatic preflight checks that verify:

- ✅ Homebrew is installed and accessible
- ✅ Xcode Command Line Tools are available
- ✅ Git is installed
- ✅ GitHub SSH access is configured (warns if not)
- ✅ Sufficient disk space is available

If any critical check fails, the playbook will stop with a helpful error message explaining how to fix the issue.

To run only the preflight checks without making changes:
```bash
ansible-playbook playbook.yml --tags preflight --check
```

> **Note:** If some Homebrew commands fail, you might need to agree to Xcode's license or fix other Brew issues. Run `brew doctor` to diagnose.

## What This Playbook Does

### Dotfiles Setup
- Clones [afromankenobi/dotfiles](https://github.com/afromankenobi/dotfiles) to `~/dotfiles`
- Installs packages from `Brewfile.minimal` (core dependencies for dotfiles)
- Symlinks configurations: Vim, Neovim, Tmux, Zsh
- Creates `~/.zshrc.local` from example for machine-specific settings

### Doom Emacs
- Installs Doom Emacs to `~/.config/emacs`
- Symlinks literate configuration files (`config.org`, `packages.org`, `init.el`)
- Runs `doom sync` to generate Emacs Lisp from org files

### Language Environments
- Installs rbenv (Ruby version manager)
- Installs nvm (Node version manager)
- Configures Oh-My-Zsh with plugins

## Package Management

**Important:** Package installation is now managed via the **Brewfile** in the dotfiles repository, not through Ansible variables.

- The dotfiles role installs packages from `~/dotfiles/Brewfile.minimal`
- To add/remove packages, update the Brewfile in the dotfiles repo
- The old `homebrew_installed_packages` list in `macos/variables.yml` is still used for packages not in dotfiles

## Changing Defaults

You can override any of the defaults configured in `variables.yml`. You can customize the installed packages and apps with something like:

```yaml
homebrew_installed_packages:
  - cowsay
  - git
  - go

configure_dock: true
dockitems_remove:
  - Launchpad
  - TV
dockitems_persist:
  - name: "Sublime Text"
    path: "/Applications/Sublime Text.app/"
    pos: 5
```
