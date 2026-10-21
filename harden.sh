#!/usr/bin/env bash

if [[ "$EUID" -ne 0 ]]; then
  echo "Uruchom skrypt jako root (sudo)"
  exit 1
fi

# 5.1.20 Ensure sshd PermitRootLogin is disabled
# 5.1.16 Ensure sshd MaxAuthTries is configured (Automated)
# 5.1.7 Ensure sshd ClientAliveInterval and ClientAliveCountMax are configured (Automated)
# 5.1.4 Ensure sshd access is configured (Automated)


cat > /etc/ssh/sshd_config.d/00-cis.conf <<EOF || exit 1
PermitRootLogin no
MaxAuthTries 4
ClientAliveInterval 15
ClientAliveCountMax 3
AllowGroups $SUDO_USER
EOF


# 3.3.1.8 Ensure net.ipv4.conf.all.accept_redirects is configured

#zakomentuj parametr we wszystkich innych plikach, tak żeby mój plik
#był jedynym miejscem które go ustawia
for plik in /etc/sysctl.conf /etc/sysctl.d/*.conf; do
  if [[ -f "$plik" && "$plik" != "/etc/sysctl.d/60-cis.conf" ]]; then
    sed -ri 's/^\s*net[./]ipv4[./]conf[./]all[./]accept_redirects\s*=/# &/' "$plik"
  fi
done

#mój plik z odpowiednią konfiguracją
cat > "/etc/sysctl.d/60-cis.conf" <<EOF || exit 1
net.ipv4.conf.all.accept_redirects = 0
EOF

#wczytuję wszystkie pliki sysctl do jądra
sysctl --system > /dev/null

# 4.1.3 Ensure ufw incoming default is configured (Automated)
ufw default deny incoming

# 4.1.2 Ensure ufw service is configured (Automated) NA SAMYM KOŃCU HARDEN!!!!!!!!!!!!!!!!!!!!!!!!!!
ufw allow 22/tcp
systemctl unmask ufw.service          #odblokowuje ufw service
systemctl --now enable ufw.service
ufw --force enable

if sshd -t; then
  systemctl restart ssh
else
  echo "Błąd w konfiguracji SSH - nie restartuję usługi"
  exit 1
fi