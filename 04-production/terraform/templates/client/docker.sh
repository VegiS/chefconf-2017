#!/usr/bin/env bash
set -e

echo "==> Docker"

echo "--> Adding keyserver"
sudo apt-key adv \
  -qq \
  --keyserver hkp://p80.pool.sks-keyservers.net:80 \
  --recv-keys 58118E89F3A912897C070ADBF76221572C52609D \
  &> /dev/null

echo "--> Adding repo"
sudo apt-add-repository \
  -y \
  'deb https://apt.dockerproject.org/repo ubuntu-xenial main' \
  &> /dev/null

echo "--> Updating cache"
sudo apt-get -qq update &>/dev/null

echo "--> Installing"
sudo apt-get install -yqq docker-engine &>/dev/null

echo "--> Allowing docker without sudo"
sudo usermod -aG docker $(whoami)

echo "==> Docker is done!"
