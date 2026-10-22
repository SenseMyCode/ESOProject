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
  echo "ClientAliveInterval jest ustawione na $client_alive_interval (częściowo zgodnie z wymaganiami CIS)"
  punkty=$((punkty + 1))
else
  echo "ClientAliveInterval ma wartość $client_alive_interval (niezgodne z wymaganiami CIS (wymaga też count alive max))"
fi

client_alive_count_max=$(sshd -T | grep -i "^clientalivecountmax" | awk '{print $2}')
if [[ "$client_alive_count_max" -gt 0 ]]; then
  echo "ClientAliveCountMax jest ustawione na $client_alive_count_max (częściowo zgodnie z wymaganiami CIS (wymaga też count alive interval))"
  punkty=$((punkty + 1))
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

# 4.1.2 Ensure ufw service is configured (Automated)
max_punkty=$((max_punkty + 2))

ufw_service_enabled=$(systemctl is-enabled ufw.service 2>/dev/null)

if [[ "$ufw_service_enabled" == "enabled" ]]; then
  echo "UFW service jest włączone (zgodnie z wymaganiami CIS)"
  punkty=$((punkty + 2))
else
  echo "UFW service jest wyłączone (niezgodne z wymaganiami CIS)"
fi

max_punkty=$((max_punkty + 2))

ufw_service_active=$(systemctl is-active ufw.service 2>/dev/null)

if [[ "$ufw_service_active" == "active" ]]; then
  echo "UFW service jest aktywne (zgodnie z wymaganiami CIS)"
  punkty=$((punkty + 2))
else
  echo "UFW service jest nieaktywne (niezgodne z wymaganiami CIS)"
fi

max_punkty=$((max_punkty + 2))

ufw_status_active=$(ufw status 2>/dev/null | grep '^Status:' | awk '{print $2}')

if [[ "$ufw_status_active" == "active" ]]; then
  echo "UFW jest aktywne (zgodnie z wymaganiami CIS)"
  punkty=$((punkty + 2))
else
  echo "UFW ma status $ufw_status_active (niezgodne z wymaganiami CIS)"
fi


# 4.1.3 Ensure ufw incoming default is configured (Automated)

max_punkty=$((max_punkty + 2))

ufw_incoming_default=$(ufw status verbose | awk -F',' '$1~/Default/ {print $1}' | awk '{print $2}')

if [[ "$ufw_incoming_default" == "deny" ]]; then
  echo "UFW incoming default jest ustawione na deny (zgodnie z wymaganiami CIS)"
  punkty=$((punkty + 2))
else
  echo "UFW incoming default ma wartość $ufw_incoming_default (niezgodne z wymaganiami CIS)"
fi

# 3.3.1.8 Ensure net.ipv4.conf.all.accept_redirects is configured

max_punkty=$((max_punkty + 2))

# Sprawdzenie wartości teraz

accept_redirects_value=$(sysctl net.ipv4.conf.all.accept_redirects | awk '{print $3}')

if [[ "$accept_redirects_value" == "0" ]]; then
  echo "net.ipv4.conf.all.accept_redirects jest ustawione na 0 (zgodnie z wymaganiami CIS)"
  punkty=$((punkty + 1))
else
  echo "net.ipv4.conf.all.accept_redirects ma wartość $accept_redirects_value (niezgodne z wymaganiami CIS)"
fi

# Sprawdzenie wartości po restarcie - !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

accept_redirects_file=$(/usr/lib/systemd/systemd-sysctl --cat-config | grep -E '^\s*net[./]ipv4[./]conf[./]all[./]accept_redirects\s*=' | tail -n 1 | cut -d= -f2 | xargs)

ufw_sysctl_file=$(grep -E '^\s*IPT_SYSCTL=' /etc/default/ufw 2>/dev/null | cut -d= -f2)

if [[ -f "$ufw_sysctl_file" ]]; then
  ufw_value=$(grep -E '^\s*net[./]ipv4[./]conf[./]all[./]accept_redirects\s*=' "$ufw_sysctl_file" \
    | tail -n 1 | cut -d= -f2 | xargs)
  if [[ -n "$ufw_value" ]]; then
    accept_redirects_file="$ufw_value"
  fi
fi

if [[ "$accept_redirects_file" == "0" ]]; then
  echo "net.ipv4.conf.all.accept_redirects w plikach konfiguracyjnych = 0 (zgodnie z wymaganiami CIS)"
  punkty=$((punkty + 1))
else
  echo "net.ipv4.conf.all.accept_redirects w plikach konfiguracyjnych = ${accept_redirects_file:-brak} (niezgodne z wymaganiami CIS)"
fi

# 3.3.1.16 Ensure net.ipv4.conf.all.log_martians is configured !!!!!!!!!!!!!!!!!!!!

max_punkty=$((max_punkty + 2))

# wartość teraz

log_martians_value=$(sysctl net.ipv4.conf.all.log_martians | awk '{print $3}')

if [[ "$log_martians_value" == "1" ]]; then
  echo "net.ipv4.conf.all.log_martians jest ustawione na 1 (zgodnie z wymaganiami CIS)"
  punkty=$((punkty + 1))
else
  echo "net.ipv4.conf.all.log_martians ma wartość $log_martians_value (niezgodne z wymaganiami CIS)"
fi

#plik

log_martians_file=$(/usr/lib/systemd/systemd-sysctl --cat-config | grep -E '^\s*net[./]ipv4[./]conf[./]all[./]log_martians\s*=' | tail -n 1 | cut -d= -f2 | xargs)

ufw_sysctl_file=$(grep -E '^\s*IPT_SYSCTL=' /etc/default/ufw 2>/dev/null | cut -d= -f2)

if [[ -f "$ufw_sysctl_file" ]]; then
  ufw_value=$(grep -E '^\s*net[./]ipv4[./]conf[./]all[./]log_martians\s*=' "$ufw_sysctl_file" \
    | tail -n 1 | cut -d= -f2 | xargs)
  if [[ -n "$ufw_value" ]]; then
    log_martians_file="$ufw_value"
  fi
fi

if [[ "$log_martians_file" == "1" ]]; then
  echo "net.ipv4.conf.all.log_martians w plikach konfiguracyjnych = 1 (zgodnie z wymaganiami CIS)"
  punkty=$((punkty + 1))
else
  echo "net.ipv4.conf.all.log_martians w plikach konfiguracyjnych = ${log_martians_file:-brak} (niezgodne z wymaganiami CIS)"
fi

echo "Wynik: $punkty/$max_punkty pkt ($((punkty * 100 / max_punkty))%)"
