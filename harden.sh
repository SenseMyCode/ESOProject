#!/usr/bin/env bash

if [[ "$EUID" -ne 0 ]]; then
  echo "Uruchom skrypt jako root (sudo)"
  exit 1
fi

# 5.1.20 Ensure sshd PermitRootLogin is disabled

echo "permitrootlogin no" > /etc/ssh/sshd_config.d/00-cis.conf 

if sshd -t; then
  systemctl restart ssh
else
  echo "Błąd w konfiguracji SSH - nie restartuję usługi"
  exit 1
fi