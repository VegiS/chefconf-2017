#!/usr/bin/env bash
set -e

echo "==> Habitat"

echo "--> Grabbing IPs"
PRIVATE_IP=$(curl --silent http://169.254.169.254/latest/meta-data/local-ipv4)
PUBLIC_IP=$(curl --silent http://169.254.169.254/latest/meta-data/public-ipv4)

echo "--> Adding habitat user"
sudo adduser --group hab
sudo useradd -g hab hab

echo "--> Fetching"
pushd /tmp &>/dev/null
curl \
  --silent \
  --location \
  --output habitat.tgz \
  https://api.bintray.com/content/habitat/stable/linux/x86_64/hab-%24latest-x86_64-linux.tar.gz?bt_package=hab-x86_64-linux
tar -zxvf habitat.tgz
sudo mv hab-*/hab /usr/local/bin/hab
sudo chmod +x /usr/local/bin/hab
rm -rf habitat.tgz
rm -rf hab-*
popd &>/dev/null

echo "--> Generating upstart configuration"
sudo tee /etc/systemd/system/habitat.service > /dev/null <<EOF
[Unit]
Description=Habitat Supervisor

[Service]
Environment=RUST_LOG=debug
ExecStart=/usr/local/bin/hab sup run

[Install]
WantedBy=default.target
EOF

echo "--> Starting habitat"
sudo systemctl enable habitat
sudo systemctl start habitat
sleep 2

echo "==> Habitat is done!"
