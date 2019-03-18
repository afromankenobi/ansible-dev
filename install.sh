#!/usr/bin/env bash

main() {
  set -e

  # Install ansible
  echo "Updating operating system package versions"
  sudo apt-add-repository -y ppa:ansible/ansible > /dev/null
  sudo apt-get update > /dev/null

  echo 'Installing ansible'
  sudo apt-get install -y ansible

  # Copy ansible configuration
  cp ansible.cfg ~/.ansible.cfg
  mkdir -p ~/.ansible
  echo "localhost" > ~/.ansible/hosts

  echo 'Setting your system up'
  ansible-playbook -K playbook.yml

  echo 'Done, now re-open your terminal window to finish'
}

main
