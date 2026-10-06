#!/usr/bin/env bash

# 5.1.20 Ensure sshd PermitRootLogin is disabled

if [[ "$EUID" -ne 0 ]]; then
  echo "Uruchom skrypt jako root (sudo)"
  exit 1
fi

permit_root_login_value=$(sshd -T | grep "^permitrootlogin" | awk '{print $2}')
if [[ "$permit_root_login_value" == "no" ]]; then
  echo "PermitRootLogin jest wyłączone (zgodnie z wymaganiami CIS)"
else
  echo "PermitRootLogin jest włączone (niezgodne z wymaganiami CIS)"
fi