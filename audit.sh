#!/usr/bin/env bash

punkty=0
max_punkty=0

if [[ "$EUID" -ne 0 ]]; then
  echo "Uruchom skrypt jako root (sudo)"
  exit 1
fi

# 5.1.20 Ensure sshd PermitRootLogin is disabled
max_punkty=$((max_punkty + 2))

permit_root_login_value=$(sshd -T | grep "^permitrootlogin" | awk '{print $2}')
if [[ "$permit_root_login_value" == "no" ]]; then
  echo "PermitRootLogin jest wyłączone (zgodnie z wymaganiami CIS)"
  punkty=$((punkty + 2))
else
  echo "PermitRootLogin ma wartość $permit_root_login_value (niezgodne z wymaganiami CIS)"
fi

# 5.1.16 Ensure sshd MaxAuthTries is configured (Automated)
max_punkty=$((max_punkty + 2))

max_auth_tries_value=$(sshd -T | grep "^maxauthtries" | awk '{print $2}')
if [[ "$max_auth_tries_value" -le 4 ]]; then
  echo "MaxAuthTries jest ustawione na $max_auth_tries_value (zgodnie z wymaganiami CIS)"
  punkty=$((punkty + 2))
else
  echo "MaxAuthTries ma wartość $max_auth_tries_value (niezgodne z wymaganiami CIS)"
fi

echo "Wynik: $punkty/$max_punkty pkt ($((punkty * 100 / max_punkty))%)"
