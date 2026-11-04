#!/usr/bin/env bash

punkty=0
max_punkty=0

# Plik, w którym UFW trzyma swoje parametry jądra - wczytywany przy starcie po plikach systemowych
ufw_sysctl_file=$(grep -E '^\s*IPT_SYSCTL=' /etc/default/ufw 2>/dev/null | cut -d= -f2)

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
if [[ -n "$max_auth_tries_value" && "$max_auth_tries_value" -le 4 ]]; then
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
max_punkty=$((max_punkty + 1))

ufw_service_enabled=$(systemctl is-enabled ufw.service 2>/dev/null)

if [[ "$ufw_service_enabled" == "enabled" ]]; then
  echo "UFW service jest włączone (zgodnie z wymaganiami CIS)"
  punkty=$((punkty + 1))
else
  echo "UFW service jest wyłączone (niezgodne z wymaganiami CIS)"
fi

max_punkty=$((max_punkty + 1))

ufw_service_active=$(systemctl is-active ufw.service 2>/dev/null)

if [[ "$ufw_service_active" == "active" ]]; then
  echo "UFW service jest aktywne (zgodnie z wymaganiami CIS)"
  punkty=$((punkty + 1))
else
  echo "UFW service jest nieaktywne (niezgodne z wymaganiami CIS)"
fi

max_punkty=$((max_punkty + 1))

ufw_status_active=$(ufw status 2>/dev/null | grep '^Status:' | awk '{print $2}')

if [[ "$ufw_status_active" == "active" ]]; then
  echo "UFW jest aktywne (zgodnie z wymaganiami CIS)"
  punkty=$((punkty + 1))
else
  echo "UFW ma status $ufw_status_active (niezgodne z wymaganiami CIS)"
fi


# 4.1.3 Ensure ufw incoming default is configured (Automated)

max_punkty=$((max_punkty + 2))

ufw_incoming_default=$(ufw status verbose | awk -F',' '$1~/Default/ {print $1}' | awk '{print $2}')

if [[ "$ufw_incoming_default" == "deny" || "$ufw_incoming_default" == "reject" ]]; then
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

# 3.3.1.18 Ensure net.ipv4.tcp_syncookies is configured

max_punkty=$((max_punkty + 2))

# wartość teraz

tcp_syncookies_value=$(sysctl net.ipv4.tcp_syncookies | awk '{print $3}')

if [[ "$tcp_syncookies_value" == "1" ]]; then
  echo "net.ipv4.tcp_syncookies jest ustawione na 1 (zgodnie z wymaganiami CIS)"
  punkty=$((punkty + 1))
else
  echo "net.ipv4.tcp_syncookies ma wartość $tcp_syncookies_value (niezgodne z wymaganiami CIS)"
fi

#plik

tcp_syncookies_file=$(/usr/lib/systemd/systemd-sysctl --cat-config | grep -E '^\s*net[./]ipv4[./]tcp_syncookies\s*=' | tail -n 1 | cut -d= -f2 | xargs)

if [[ -f "$ufw_sysctl_file" ]]; then
  ufw_value=$(grep -E '^\s*net[./]ipv4[./]tcp_syncookies\s*=' "$ufw_sysctl_file" \
    | tail -n 1 | cut -d= -f2 | xargs)
  if [[ -n "$ufw_value" ]]; then
    tcp_syncookies_file="$ufw_value"
  fi
fi

if [[ "$tcp_syncookies_file" == "1" ]]; then
  echo "net.ipv4.tcp_syncookies w plikach konfiguracyjnych = 1 (zgodnie z wymaganiami CIS)"
  punkty=$((punkty + 1))
else
  echo "net.ipv4.tcp_syncookies w plikach konfiguracyjnych = ${tcp_syncookies_file:-brak} (niezgodne z wymaganiami CIS)"
fi

# 5.2.3 Ensure sudo log file exists (Automated)

max_punkty=$((max_punkty + 2))

sudo_log_file=$(grep -rPsi "^\h*Defaults\h+([^#]+,\h*)?logfile\h*=\h*(\"|\')?\H+(\"|\')?(,\h*\H+\h*)*\h*(#.*)?$" /etc/sudoers*)

if [[ -n "$sudo_log_file" ]]; then
  echo "Osobny plik logu sudo istnieje (zgodnie z wymaganiami CIS)"
  punkty=$((punkty + 2))
else
  echo "Osobny plik logu sudo nie istnieje (niezgodne z wymaganiami CIS)"
fi

# 5.2.7 Ensure access to the su command is restricted

max_punkty=$((max_punkty + 2))

su_line=$(grep -Pi '^\h*auth\h+(?:required|requisite)\h+pam_wheel\.so\h+(?:[^#\n\r]+\h+)?((?!\2)(use_uid\b|group=\H+\b))\h+(?:[^#\n\r]+\h+)?((?!\1)(use_uid\b|group=\H+\b))(\h+.*)?$' /etc/pam.d/su)

su_group=$(echo "$su_line" | grep -oP 'group=\K\H+' | head -n 1)

su_group_line=$(grep "^${su_group}:" /etc/group)
su_members=$(echo "$su_group_line" | cut -d: -f4)

if [[ -z "$su_line" ]]; then
  echo "5.2.7 su: brak linii pam_wheel.so use_uid group=... w /etc/pam.d/su (niezgodne z wymaganiami CIS)"
elif [[ -z "$su_group_line" ]]; then
  echo "5.2.7 su: grupa $su_group nie istnieje w /etc/group (niezgodne z wymaganiami CIS)"
elif [[ -n "$su_members" ]]; then
  echo "5.2.7 su: grupa $su_group ma członków: $su_members (niezgodne z wymaganiami CIS)"
else
  echo "5.2.7 su: dostęp ograniczony do pustej grupy $su_group (zgodne z wymaganiami CIS)"
  punkty=$((punkty + 2))
fi

# 2.3.1.1 Ensure a single time synchronization daemon is in use

max_punkty=$((max_punkty + 2))

time_count=0
time_list=""

for daemon in systemd-timesyncd.service chrony.service; do
  if systemctl is-enabled "$daemon" 2>/dev/null |grep -q '^enabled' || systemctl is-active "$daemon" 2>/dev/null |grep -q '^active'; then
    time_count=$((time_count + 1))
    time_list="$time_list $daemon"
  fi
done

if [[ "$time_count" -eq 1 ]]; then
  echo "Używany jest jeden demon synchronizacji czasu: $time_list (zgodnie z wymaganiami CIS)"
  punkty=$((punkty + 2))
elif [[ "$time_count" -gt 1 ]]; then
  echo "Używanych jest wiele demonów synchronizacji czasu: $time_list (niezgodne z wymaganiami CIS)"
else
  echo "Nie używany jest żaden demon synchronizacji czasu (niezgodne z wymaganiami CIS)"
fi

# 5.4.3.2 Ensure default user shell timeout is configured
max_punkty=$((max_punkty + 2))

tmout_decl=$(bash -lc 'declare -p TMOUT' 2>/dev/null)          # np. declare -rx TMOUT="900"
tmout_flags=$(echo "$tmout_decl" | awk '{print $2}')            # np. -rx
tmout_value=$(echo "$tmout_decl" | grep -oP 'TMOUT="\K\d+')      # np. 900

if [[ -n "$tmout_value" && "$tmout_value" -ge 1 && "$tmout_value" -le 900 ]]; then
  echo "5.4.3.2 TMOUT = $tmout_value s (zgodne z wymaganiami CIS)"
  punkty=$((punkty + 1))
else
  echo "5.4.3.2 TMOUT = ${tmout_value:-nie ustawione}, wymagane 1-900 s (niezgodne z wymaganiami CIS)"
fi

if [[ "$tmout_flags" == *r* && "$tmout_flags" == *x* ]]; then
  echo "5.4.3.2 TMOUT jest readonly i exportowane (zgodne z wymaganiami CIS)"
  punkty=$((punkty + 1))
else
  echo "5.4.3.2 TMOUT atrybuty: ${tmout_flags:-brak}, wymagane readonly i export (niezgodne z wymaganiami CIS)"
fi

# 5.1.13 Ensure sshd LoginGraceTime is configured (Automated)

max_punkty=$((max_punkty + 2))

login_grace_time=$(sshd -T | grep "^logingracetime" | awk '{print $2}')
if [[ -n "$login_grace_time" && "$login_grace_time" -ge 1 && "$login_grace_time" -le 60 ]]; then
  echo "LoginGraceTime jest ustawione na $login_grace_time s (zgodnie z wymaganiami CIS)"
  punkty=$((punkty + 2))
else
  echo "LoginGraceTime ma wartość ${login_grace_time:-nie ustawione}, wymagane <= 60 s (niezgodne z wymaganiami CIS)"
fi

# 1.4.2 Ensure access to bootloader config is configured

max_punkty=$((max_punkty + 2))

grub_cfg="/boot/grub/grub.cfg"
grub_mode=$(stat -Lc '%a' "$grub_cfg")
grub_owner=$(stat -Lc '%u:%g' "$grub_cfg")

if [[ -n "$grub_mode" ]] && (( (8#$grub_mode & 8#177) == 0 )); then
  echo "1.4.2 Uprawnienia $grub_cfg: $grub_mode (zgodne z wymaganiami CIS)"
  punkty=$((punkty + 1))
else
  echo "1.4.2 Uprawnienia $grub_cfg: ${grub_mode:-brak pliku}, wymagane 600 lub mniej (niezgodne z wymaganiami CIS)"
fi

if [[ "$grub_owner" == "0:0" ]]; then
  echo "1.4.2 Właściciel $grub_cfg: root:root (zgodne z wymaganiami CIS)"
  punkty=$((punkty + 1))
else
  echo "1.4.2 Właściciel $grub_cfg: ${grub_owner:-brak pliku}, wymagany root:root (niezgodne z wymaganiami CIS)"
fi

# 1.1.1.10 Ensure usb-storage kernel module is not available (Automated)

max_punkty=$((max_punkty + 2))

# czy moduł usb-storage istnieje na dysku (w którymkolwiek zainstalowanym jądrze)
usb_mod_exists=""
while IFS= read -r mod_path; do
  if [ -d "$mod_path/usb/storage" ] && [ -n "$(ls -A "$mod_path/usb/storage")" ]; then
    usb_mod_exists="tak"
  fi
done < <(readlink -e /usr/lib/modules/*/kernel/drivers || readlink -e /lib/modules/*/kernel/drivers)

if [[ -z "$usb_mod_exists" ]]; then
  echo "1.1.1.10 Moduł usb-storage nie istnieje w systemie (zgodne z wymaganiami CIS)"
  punkty=$((punkty + 2))
else
  # czy moduł nie jest teraz załadowany
  if ! lsmod | grep -Pq -- '^usb(_|-)storage\b'; then
    echo "1.1.1.10 Moduł usb-storage nie jest załadowany (zgodne z wymaganiami CIS)"
    punkty=$((punkty + 1))
  else
    echo "1.1.1.10 Moduł usb-storage jest załadowany (niezgodne z wymaganiami CIS)"
  fi

  # czy w konfiguracji modprobe są obie blokady: blacklist i install /bin/false
  usb_config=$(modprobe --showconfig | grep -P -- '\b(install|blacklist)\h+usb_storage\b')
  if grep -Pq -- '^\h*blacklist\h+usb_storage\b' <<< "$usb_config" && \
     grep -Pq -- '^\h*install\h+usb_storage\h+/bin/(false|true)\b' <<< "$usb_config"; then
    echo "1.1.1.10 Moduł usb-storage jest zablokowany (blacklist + install) (zgodne z wymaganiami CIS)"
    punkty=$((punkty + 1))
  else
    echo "1.1.1.10 Brak blacklist lub install dla usb_storage (niezgodne z wymaganiami CIS)"
  fi
fi

# 2.4.1.2 Ensure access to /etc/crontab is configured (Automated)

# 2.4.1.2 Ensure access to /etc/crontab is configured (Automated)
max_punkty=$((max_punkty + 2))

if ! dpkg-query -s cron &>/dev/null; then
  echo "2.4.1.2 cron nie jest zainstalowany - zalecenie nie dotyczy (zgodne z wymaganiami CIS)"
  punkty=$((punkty + 2))
else
  crontab_mode=$(stat -Lc '%a' /etc/crontab)
  crontab_owner=$(stat -Lc '%u:%g' /etc/crontab)

  if [[ -n "$crontab_mode" ]] && (( (8#$crontab_mode & 8#077) == 0 )); then
    echo "2.4.1.2 Uprawnienia /etc/crontab: $crontab_mode (zgodne z wymaganiami CIS)"
    punkty=$((punkty + 1))
  else
    echo "2.4.1.2 Uprawnienia /etc/crontab: ${crontab_mode:-brak pliku}, grupa i inni nie mogą mieć praw (niezgodne z wymaganiami CIS)"
  fi

  if [[ "$crontab_owner" == "0:0" ]]; then
    echo "2.4.1.2 Właściciel /etc/crontab: root:root (zgodne z wymaganiami CIS)"
    punkty=$((punkty + 1))
  else
    echo "2.4.1.2 Właściciel /etc/crontab: ${crontab_owner:-brak pliku}, wymagany root:root (niezgodne z wymaganiami CIS)"
  fi
fi

# 5.4.3.3 Ensure default user umask is configured (Automated)
max_punkty=$((max_punkty + 2))

# umask w plikach /etc/profile.d/*.sh 
umask_profile=$(grep -Phi -- '^\h*umask\h+[0-7]+' /etc/profile.d/*.sh 2>/dev/null | awk '{print $2}')
umask_profile_ok="tak"

if [[ -z "$umask_profile" ]]; then
  umask_profile_ok=""
fi
for wartosc in $umask_profile; do
  if (( (8#$wartosc & 8#027) != 8#027 )); then
    umask_profile_ok=""
  fi
done

if [[ -n "$umask_profile_ok" ]]; then
  echo "5.4.3.3 umask w /etc/profile.d: $(echo $umask_profile) (zgodne z wymaganiami CIS)"
  punkty=$((punkty + 1))
else
  echo "5.4.3.3 umask w /etc/profile.d: ${umask_profile:-brak}, wymagane 027 lub bardziej restrykcyjne (niezgodne z wymaganiami CIS)"
fi

# UMASK w /etc/login.defs
umask_logindefs=$(grep -Pi -- '^\h*UMASK\h+[0-7]+' /etc/login.defs | tail -n 1 | awk '{print $2}')

if [[ -n "$umask_logindefs" ]] && (( (8#$umask_logindefs & 8#027) == 8#027 )); then
  echo "5.4.3.3 UMASK w /etc/login.defs: $umask_logindefs (zgodne z wymaganiami CIS)"
  punkty=$((punkty + 1))
else
  echo "5.4.3.3 UMASK w /etc/login.defs: ${umask_logindefs:-brak}, wymagane 027 lub bardziej restrykcyjne (niezgodne z wymaganiami CIS)"
fi

echo "Wynik: $punkty/$max_punkty pkt ($((punkty * 100 / max_punkty))%)"
