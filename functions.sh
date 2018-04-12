function install_docker {
  # Prepare to install docker
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
  sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
  sudo apt-get update -y
  # Install docker and immediately stop it
  sudo apt-get install -y docker-ce
}

function require_vars {
  return_code=0
  for var in $@; do
    if [ -z "${!var}" ]; then
     echo "ERROR: required variable '${var}' is not set"
     return_code=1
    fi
  done
  return $return_code
}
