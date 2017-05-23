#!/usr/bin/env bash
set -e

echo "==> Nomad (server)"

echo "--> Grabbing IPs"
PRIVATE_IP=$(curl --silent http://169.254.169.254/latest/meta-data/local-ipv4)
PUBLIC_IP=$(curl --silent http://169.254.169.254/latest/meta-data/public-ipv4)

echo "--> Fetching"
pushd /tmp &>/dev/null
curl \
  --silent \
  --location \
  --output nomad.zip \
  https://releases.hashicorp.com/nomad/${nomad_version}/nomad_${nomad_version}_linux_amd64.zip
unzip -qq nomad.zip
sudo mv nomad /usr/local/bin/nomad
sudo chmod +x /usr/local/bin/nomad
rm -rf nomad.zip
popd &>/dev/null

echo "--> Writing configuration"
sudo mkdir -p /mnt/nomad
sudo mkdir -p /etc/nomad.d
sudo tee /etc/nomad.d/config.hcl > /dev/null <<EOF
name         = "${hostname}"
data_dir     = "/mnt/nomad"
enable_debug = true

bind_addr = "0.0.0.0"

advertise {
  http = "$PRIVATE_IP:4646"
  rpc  = "$PRIVATE_IP:4647"
  serf = "$PRIVATE_IP:4648"
}

server {
  enabled          = true
  bootstrap_expect = ${servers}
}
EOF

echo "--> Writing profile"
sudo tee /etc/profile.d/nomad.sh > /dev/null <<EOF
alias noamd="nomad"
alias nomas="nomad"
alias nomda="nomad"
export NOMAD_ADDR="http://$PRIVATE_IP:4646"
EOF
source /etc/profile.d/nomad.sh

echo "--> Generating upstart configuration"
sudo tee /etc/systemd/system/nomad.service > /dev/null <<EOF
[Unit]
Description=Nomad Agent
Requires=network-online.target
After=network.target

[Service]
Environment=GOMAXPROCS=8
Restart=on-failure
ExecStart=/usr/local/bin/nomad agent -config="/etc/nomad.d"
ExecReload=/bin/kill -HUP $MAINPID
KillSignal=SIGTERM

[Install]
WantedBy=multi-user.target
EOF

echo "--> Starting nomad"
sudo systemctl enable nomad
sleep 2

echo "==> Nomad is done!"
