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


cat > /etc/ssh/sshd_config.d/00-cis.conf <<EOF || exit 1
PermitRootLogin no
MaxAuthTries 4
ClientAliveInterval 15
ClientAliveCountMax 3
AllowGroups $SUDO_USER
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

#zakomentuj parametr we wszystkich innych plikach, tak żeby mój plik
#był jedynym miejscem które go ustawia
UFW_SYSCTL_FILE=$(grep -E '^\s*IPT_SYSCTL=' /etc/default/ufw 2>/dev/null | cut -d= -f2)

for plik in /etc/sysctl.conf /etc/sysctl.d/*.conf "$UFW_SYSCTL_FILE"; do
  if [[ -f "$plik" && "$plik" != "/etc/sysctl.d/60-cis.conf" ]]; then
    sed -ri 's/^\s*net[./]ipv4[./]conf[./]all[./]accept_redirects\s*=/# &/' "$plik"
    sed -ri 's/^\s*net[./]ipv4[./]conf[./]all[./]log_martians\s*=/# &/' "$plik"
  fi
done

#mój plik z odpowiednią konfiguracją
cat > "/etc/sysctl.d/60-cis.conf" <<EOF || exit 1
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.all.log_martians = 1
EOF

#wczytuję wszystkie pliki sysctl do jądra
sysctl --system > /dev/null



# 4.1.2 Ensure ufw service is configured (Automated) NA SAMYM KOŃCU HARDEN!!!!!!!!!!!!!!!!!!!!!!!!!!
ufw allow 22/tcp
ufw default deny incoming             # 4.1.3 Ensure ufw incoming default is configured (Automated)
systemctl unmask ufw.service          #odblokowuje ufw service
systemctl --now enable ufw.service
ufw --force enable
