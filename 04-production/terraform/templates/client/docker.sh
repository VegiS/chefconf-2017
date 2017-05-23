#!/usr/bin/env bash
set -e

echo "==> Docker"

echo "--> Removing old"
sudo apt-get -yqq remove docker docker-engine

echo "--> Adding GPG key"
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -

echo "--> Adding repo"
sudo add-apt-repository \
  -y \
  "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) \
  stable"

echo "--> Updating cache"
sudo apt-get -yqq update

echo "--> Installing"
sudo apt-get install -yqq docker-ce

echo "--> Allowing docker without sudo"
sudo usermod -aG docker ubuntu

echo "--> Enabling docker at boot"
sudo systemctl enable docker

echo "--> Adding config"
sudo tee /etc/docker/daemon.json > /dev/null <<EOF
{
  "graph": "/mnt/docker",
  "storage-driver": "overlay"
}
EOF
sudo systemctl restart docker

echo "--> Pulling containers"
sudo docker pull sethvargo/http-echo
sudo docker pull sethvargo/nginx-lb

echo "==> Docker is done!"
