# Testing Checklist for New Mac Setup

Use this checklist when testing the playbook on a fresh macOS installation (like your new Mac mini).

## Phase 1: Prerequisites (Manual)

- [ ] **Install Xcode Command Line Tools**
  ```bash
  xcode-select --install
  ```
  Wait for installation to complete, then verify:
  ```bash
  xcode-select -p
  # Should output: /Library/Developer/CommandLineTools
  ```

- [ ] **Install Homebrew**
  ```bash
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  ```
  Add to PATH (follow the instructions Homebrew prints):
  ```bash
  eval "$(/opt/homebrew/bin/brew shellenv)"
  ```
  Verify installation:
  ```bash
  brew --version
  brew doctor
  ```

- [ ] **Install Ansible**
  ```bash
  export PATH="$HOME/Library/Python/3.9/bin:/opt/homebrew/bin:$PATH"
  pip3 install --upgrade pip
  pip3 install ansible
  ```
  Verify:
  ```bash
  ansible --version
  ```

- [ ] **Setup GitHub SSH** (recommended)
  ```bash
  # Generate key
  ssh-keygen -t ed25519 -C "your_email@example.com"

  # Display public key
  cat ~/.ssh/id_ed25519.pub
  ```
  Add the key to GitHub: https://github.com/settings/keys

  Test connection:
  ```bash
  ssh -T git@github.com
  # Should see: "Hi username! You've successfully authenticated..."
  ```

## Phase 2: Run Preflight Checks Only

- [ ] **Clone ansible-dev**
  ```bash
  git clone git@github.com:afromankenobi/ansible-dev.git
  cd ansible-dev
  ```

- [ ] **Install Ansible roles**
  ```bash
  ansible-galaxy install -r requirements.yml
  ```

- [ ] **Run preflight checks**
  ```bash
  ansible-playbook playbook.yml --tags preflight --check
  ```
  Expected output:
  - ✅ All checks should pass
  - Green "ok" messages for each check
  - No red "failed" messages

## Phase 3: Dry Run (Check Mode)

- [ ] **Dry run the full playbook**
  ```bash
  ansible-playbook playbook.yml --ask-become-pass --check
  ```
  This shows what would change without actually making changes.

  Expected behavior:
  - Shows all tasks that would run
  - Reports what would be created/changed
  - No actual changes made to system

## Phase 4: Actual Playbook Run

- [ ] **Run the full playbook**
  ```bash
  ansible-playbook playbook.yml --ask-become-pass
  ```
  Enter your Mac password when prompted.

  Watch for:
  - Green "ok" = already configured
  - Yellow "changed" = something was modified
  - Red "failed" = error (note the task name)

- [ ] **Wait for completion**
  The playbook can take 15-30 minutes depending on:
  - Internet speed (downloading packages)
  - Number of packages to install
  - Doom Emacs compilation

## Phase 5: Verification

After the playbook completes successfully:

- [ ] **Verify dotfiles cloned**
  ```bash
  ls ~/dotfiles
  # Should see: doom/, tmux/, vim/, zshrc, Brewfile, etc.
  ```

- [ ] **Verify symlinks created**
  ```bash
  ls -la ~/.zshrc ~/.tmux.conf ~/.vimrc
  # Should show symlinks (->) pointing to ~/dotfiles/
  ```

- [ ] **Verify Doom Emacs installed**
  ```bash
  ls ~/.config/emacs/bin/doom
  ls -la ~/.config/doom/
  # Should see: config.org, packages.org, init.el (symlinks)
  # And: config.el, packages.el (generated files)
  ```

- [ ] **Test Doom Emacs**
  ```bash
  ~/.config/emacs/bin/doom doctor
  # Should show mostly green checks

  # Start Emacs
  emacs
  # Should load without errors
  ```

- [ ] **Test Zsh config**
  ```bash
  # Open new terminal window
  # Should see starship prompt
  # Should have syntax highlighting
  # Should have autosuggestions
  ```

- [ ] **Test Tmux**
  ```bash
  tmux
  # Should load with custom config
  # Check status bar shows time, Ruby version, etc.
  ```

- [ ] **Verify packages installed**
  ```bash
  which ripgrep fd bat eza zoxide
  # Should show paths for all
  ```

## Common Issues & Solutions

### Issue: "Homebrew not found"
**Solution:** Make sure Homebrew is in your PATH:
```bash
eval "$(/opt/homebrew/bin/brew shellenv)"
```
Add to your current shell's rc file if needed.

### Issue: "Permission denied (publickey)" when cloning dotfiles
**Solution:** GitHub SSH not configured. Either:
1. Setup SSH key (see Phase 1)
2. Or temporarily change to HTTPS in `roles/dotfiles/tasks/main.yml`:
   ```yaml
   repo: https://github.com/afromankenobi/dotfiles.git
   ```

### Issue: "xcode-select: error: tool 'xcodebuild' requires Xcode"
**Solution:** You need Command Line Tools, not full Xcode:
```bash
xcode-select --install
```

### Issue: Doom sync fails with native-comp errors
**Solution:** Check if libgccjit is installed:
```bash
brew list libgccjit
```
If not:
```bash
brew install libgccjit
~/.config/emacs/bin/doom sync
```

### Issue: Some Homebrew packages fail to install
**Solution:**
1. Check which package failed
2. Try installing it manually:
   ```bash
   brew install <package-name>
   ```
3. Check for known issues: `brew search <package-name>`
4. Some packages might not support the latest macOS yet

## Success Criteria

The setup is successful when:

- ✅ No red "failed" messages in playbook output
- ✅ All symlinks pointing to ~/dotfiles/
- ✅ Emacs launches without errors
- ✅ Zsh has custom prompt, syntax highlighting, autosuggestions
- ✅ Tmux loads with custom configuration
- ✅ Can run `rg`, `fd`, `bat`, and other CLI tools

## Notes

- **First run**: Takes longer (15-30 minutes) due to package downloads
- **Subsequent runs**: Much faster (1-2 minutes) - only updates what changed
- **Idempotent**: Safe to run multiple times, won't duplicate or break things
- **Rollback**: If something goes wrong, dotfiles are just symlinks - easy to undo

## Reporting Issues

If you encounter issues:

1. Note the exact error message
2. Note which task failed (task name shown in output)
3. Check if it's a known issue in the list above
4. Run with verbose mode for more details:
   ```bash
   ansible-playbook playbook.yml --ask-become-pass -vvv
   ```
