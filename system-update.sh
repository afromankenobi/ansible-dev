dev_system_update() {
  local ref=$(pwd)
  local name=dev-install
  local url='http://domain.com' # TODO: set production url

  # Get latest version
  cd /tmp
  echo 'Downloading latest version'
  wget "${url}/${name}.tar.gz" -O ${name}.tar.gz
  tar xzf ${name}.tar.gz
  cd ${name}

  # Run installation
  $SHELL ./install.sh

  # End
  cd ${ref}
  rm -rf /tmp/${name}
  echo "FINISHED (stable version)"
}

dev_system_update
