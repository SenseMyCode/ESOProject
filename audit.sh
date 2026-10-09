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

# 5.1.7 Ensure sshd ClientAliveInterval and ClientAliveCountMax are configured (Automated)

max_punkty=$((max_punkty + 2))

client_alive_interval=$(sshd -T | grep -i "^clientaliveinterval" | awk '{print $2}')
if [[ "$client_alive_interval" -gt 0 ]]; then
  echo "ClientAliveInterval jest ustawione na $client_alive_interval (zgodnie z wymaganiami CIS)"
  punkty=$((punkty + 2))
else
  echo "ClientAliveInterval ma wartość $client_alive_interval (niezgodne z wymaganiami CIS)"
fi

max_punkty=$((max_punkty + 2))

client_alive_count_max=$(sshd -T | grep -i "^clientalivecountmax" | awk '{print $2}')
if [[ "$client_alive_count_max" -gt 0 ]]; then
  echo "ClientAliveCountMax jest ustawione na $client_alive_count_max (zgodnie z wymaganiami CIS)"
  punkty=$((punkty + 2))
else
  echo "ClientAliveCountMax ma wartość $client_alive_count_max (niezgodne z wymaganiami CIS)"
fi

# 5.1.4 Ensure sshd access is configured (Automated)

max_punkty=$((max_punkty + 2))

sshd_access_au=$(sshd -T | grep -i "^allowusers" | awk '{print $2}')
sshd_access_ag=$(sshd -T | grep -i "^allowgroups" | awk '{print $2}')
sshd_access_du=$(sshd -T | grep -i "^denyusers" | awk '{print $2}')
sshd_access_dg=$(sshd -T | grep -i "^denygroups" | awk '{print $2}')

if [[ -n "$sshd_access_au" || -n "$sshd_access_ag" || -n "$sshd_access_du" || -n "$sshd_access_dg" ]]; then
  echo "sshd access jest skonfigurowane (zgodnie z wymaganiami CIS)"
  punkty=$((punkty + 2))
else
  echo "sshd access nie jest skonfigurowane (niezgodne z wymaganiami CIS)"
fi


echo "Wynik: $punkty/$max_punkty pkt ($((punkty * 100 / max_punkty))%)"
