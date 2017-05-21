#!/usr/bin/env bash
set -e

# Trap the reboot as an exit, because the script has to return 0 or else
# Terraform will thing the provisoiner failed.
function reboot {
  sudo systemctl reboot &>/dev/null
}

trap reboot EXIT

echo "==> Waiting for /etc/nomad.d"
while ! test -d /etc/nomad.d; do
  sleep 2
done

echo "==> Writing joins"
sudo tee /etc/nomad.d/servers.hcl > /dev/null <<EOF
server {
  retry_join = [${server_ips}]
}
EOF
sudo tee /etc/nomad.d/clients.hcl > /dev/null <<EOF
client {
  servers = [${server_ips}]
}
EOF

echo "==> Waiting for cloud-init"
while ! grep -q "Cloud-init .* finished" /var/log/cloud-init.log; do
  sleep 2
done

echo "==> Rebooting"
