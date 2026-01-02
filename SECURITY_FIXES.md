# Security Fixes

This document tracks security improvements made to the playbook.

## Fixed: Hardcoded Password in vars/main.yml

### Issue
The `roles/ohmyzsh/vars/main.yml` file contained a hardcoded password placeholder:
```yaml
user_password: PASSWORD_HERE
```

This password was used by the `expect` module to interactively provide the user's password when changing the default shell to zsh.

**Problems:**
1. 🔴 Hardcoded credential in version control
2. 🔴 Required users to edit vars file with their actual password
3. 🔴 Password stored in plain text
4. 🔴 Required additional dependency (python3-pexpect)

### Solution

Replaced the interactive `expect` module approach with Ansible's built-in `user` module:

**Before:**
```yaml
- name: Install pexpect
  apt:
    name: python3-pexpect

- name: Default shell
  expect:
    command: "chsh -s /bin/zsh"
    responses:
      (?i)password:
        - "{{ user_password }}"  # ← Hardcoded password needed
```

**After:**
```yaml
- name: Set zsh as default shell (Debian only)
  become: true
  user:
    name: "{{ ansible_user_id }}"
    shell: /bin/zsh
  when: ansible_os_family == "Debian"
```

**Benefits:**
1. ✅ No hardcoded passwords
2. ✅ Uses sudo password already provided via `--ask-become-pass`
3. ✅ No additional dependencies (pexpect removed)
4. ✅ Cleaner, more idiomatic Ansible code
5. ✅ Removed `roles/ohmyzsh/vars/main.yml` entirely

## Password Handling Best Practices

### What We Do Now

The playbook uses a single password prompt at the start:
```bash
ansible-playbook playbook.yml --ask-become-pass
```

This prompts for the **sudo password** which is used for:
- Installing system packages (via apt/homebrew)
- Changing system settings
- Setting default shell (via `become: true`)

### What We Don't Do

❌ Store passwords in vars files
❌ Commit passwords to git
❌ Use plain text passwords
❌ Prompt for passwords multiple times

### macOS Note

On macOS (Catalina 10.15+), zsh is already the default shell, so no shell change is needed. The `become: true` task only runs on Debian systems.

## Related Changes

As part of this fix, we also:
- Removed duplicate zsh plugin installations (see EXECUTION_ORDER.md)
- Added preflight checks to validate prerequisites
- Improved idempotency checks

## Testing

After this fix:
```bash
# Clone the repo
git clone git@github.com:afromankenobi/ansible-dev.git
cd ansible-dev

# Install roles
ansible-galaxy install -r requirements.yml

# Run playbook - only asks for sudo password once
ansible-playbook playbook.yml --ask-become-pass
```

No additional passwords needed!
