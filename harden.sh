#!/usr/bin/env bash

if [[ "$EUID" -ne 0 ]]; then
  echo "Uruchom skrypt jako root (sudo)"
  exit 1
fi

# 5.1.20 Ensure sshd PermitRootLogin is disabled
# 5.1.16 Ensure sshd MaxAuthTries is configured (Automated)
# 5.1.7 Ensure sshd ClientAliveInterval and ClientAliveCountMax are configured (Automated)


cat > /etc/ssh/sshd_config.d/00-cis.conf <<EOF || exit 1
PermitRootLogin no
MaxAuthTries 4
ClientAliveInterval 15
ClientAliveCountMax 3
EOF


if sshd -t; then
  systemctl restart ssh
else
  echo "Błąd w konfiguracji SSH - nie restartuję usługi"
  exit 1
fi