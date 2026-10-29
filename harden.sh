#!/usr/bin/env bash

if [[ "$EUID" -ne 0 ]]; then
  echo "Uruchom skrypt jako root (sudo)"
  exit 1
fi

if [[ -z "$SUDO_USER" ]] || ! id "$SUDO_USER" &>/dev/null; then
  echo "Nie można ustalić użytkownika z dostępem SSH - uruchom przez sudo jako zwykły użytkownik"
  exit 1
fi

# 5.1.20 Ensure sshd PermitRootLogin is disabled
# 5.1.16 Ensure sshd MaxAuthTries is configured (Automated)
# 5.1.7 Ensure sshd ClientAliveInterval and ClientAliveCountMax are configured (Automated)
# 5.1.4 Ensure sshd access is configured (Automated)
# 5.1.13 Ensure sshd LoginGraceTime is configured (Automated)

cat > /etc/ssh/sshd_config.d/00-cis.conf <<EOF || exit 1
PermitRootLogin no
MaxAuthTries 4
ClientAliveInterval 15
ClientAliveCountMax 3
AllowUsers $SUDO_USER
LoginGraceTime 60
EOF

# Przygotowanie katalogu /run/sshd, jeśli nie istnieje, aby uniknąć błędów przy restarcie usługi SSH
if [[ ! -d /run/sshd ]]; then
  mkdir -p /run/sshd
fi

# Sprawdzenie poprawności konfiguracji SSH i restart usługi, żeby zmiany zostały zastosowane
if sshd -t; then
  systemctl restart ssh
else
  echo "Błąd w konfiguracji SSH - nie restartuję usługi"
  exit 1
fi


# 3.3.1.8 Ensure net.ipv4.conf.all.accept_redirects is configured
# 3.3.1.16 Ensure net.ipv4.conf.all.log_martians is configured 
# 3.3.1.18 Ensure net.ipv4.tcp_syncookies is configured

#zakomentuj parametr we wszystkich innych plikach, tak żeby mój plik
#był jedynym miejscem które go ustawia
UFW_SYSCTL_FILE=$(grep -E '^\s*IPT_SYSCTL=' /etc/default/ufw 2>/dev/null | cut -d= -f2)

for plik in /etc/sysctl.conf /etc/sysctl.d/*.conf "$UFW_SYSCTL_FILE"; do
  if [[ -f "$plik" && "$plik" != "/etc/sysctl.d/60-cis.conf" ]]; then
    sed -ri 's/^\s*net[./]ipv4[./]conf[./]all[./]accept_redirects\s*=/# &/' "$plik"
    sed -ri 's/^\s*net[./]ipv4[./]conf[./]all[./]log_martians\s*=/# &/' "$plik"
    sed -ri 's/^\s*net[./]ipv4[./]tcp_syncookies\s*=/# &/' "$plik"
  fi
done

#mój plik z odpowiednią konfiguracją
cat > "/etc/sysctl.d/60-cis.conf" <<EOF || exit 1
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.all.log_martians = 1
net.ipv4.tcp_syncookies = 1
EOF

#wczytuję wszystkie pliki sysctl do jądra
sysctl --system > /dev/null

# 5.2.3 Ensure sudo log file exists (Automated)

SUDOERS_CIS="/etc/sudoers.d/60-cis"
TMP_SUDOERS=$(mktemp)

cat > "$TMP_SUDOERS" <<'EOF'
Defaults logfile="/var/log/sudo.log"
EOF

if visudo -cf "$TMP_SUDOERS" > /dev/null; then
  install -m 0440 -o root -g root "$TMP_SUDOERS" "$SUDOERS_CIS"
else
  echo "Błąd w konfiguracji sudoers - nie zapisuję zmian"
  rm -f "$TMP_SUDOERS"
  exit 1
fi
rm -f "$TMP_SUDOERS"

# 5.2.7 Ensure access to the su command is restricted (Automated)
groupadd -f sugroup
gpasswd -M "" sugroup

if ! grep -Eq '^\s*auth\s+required\s+pam_wheel\.so\s+use_uid\s+group=sugroup' /etc/pam.d/su; then
  sed -Ei '/^\s*auth\s+sufficient\s+pam_rootok\.so/a auth       required   pam_wheel.so use_uid group=sugroup' /etc/pam.d/su
fi

if ! grep -Eq '^\s*auth\s+required\s+pam_wheel\.so\s+use_uid\s+group=sugroup' /etc/pam.d/su; then
  echo "Nie udało się dodać reguły pam_wheel do /etc/pam.d/su"
  exit 1
fi

# 2.3.1.1 Ensure a single time synchronization daemon is in use. Pozbywamy się chrony bo systemd-timesyncd jest domyślnym i wystarczającym demonem synchronizacji czasu 
if dpkg -s chrony &>/dev/null; then
  apt-get purge -y chrony
fi

systemctl unmask systemd-timesyncd.service
systemctl --now enable systemd-timesyncd.service

# 5.4.3.2 Ensure default user shell timeout is configured
TMOUT_FILE="/etc/profile.d/60-cis-tmout.sh"     

# TMOUT ma być ustawione w jednym miejscu (drugie readonly = błąd przy logowaniu)
for plik in /etc/bash.bashrc /etc/profile /etc/profile.d/*.sh; do
  if [[ -f "$plik" && "$plik" != "$TMOUT_FILE" ]]; then
    sed -ri 's/^([^#]*\bTMOUT\b)/# \1/' "$plik"
  fi
done

cat > "$TMOUT_FILE" <<'EOF' || exit 1
# CIS 5.4.3.2 - wylogowanie nieaktywnej powłoki po 15 minutach; readonly + export
typeset -xr TMOUT=900
EOF
chmod 644 "$TMOUT_FILE"

# 1.4.2 Ensure access to bootloader config is configured (Automated)

chown root:root /boot/grub/grub.cfg || exit 1
chmod u-x,go-rwx /boot/grub/grub.cfg || exit 1

# 4.1.2 Ensure ufw service is configured (Automated) NA SAMYM KOŃCU HARDEN!!!!!!!!!!!!!!!!!!!!!!!!!!
ufw allow 22/tcp
ufw default deny incoming             # 4.1.3 Ensure ufw incoming default is configured (Automated)
systemctl unmask ufw.service          #odblokowuje ufw service
systemctl --now enable ufw.service
ufw --force enable
