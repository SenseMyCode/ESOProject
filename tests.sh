#!/usr/bin/env bash

VM="cisvm"
ok=0
fail=0

# 5.1.20 Ensure sshd PermitRootLogin is disabled

# Test 1 Zwykły użytkownik może zalogować się przez SSH
# Jeśli to nie działa, reszta testów nie ma sensu - kończymy od razu

if ssh -o BatchMode=yes -o ConnectTimeout=5 "$VM" 'echo OK' 2>/dev/null | grep -q '^OK$'; then
    echo "OK: Logowanie zwykłego użytkownika przez SSH"
    ok=$((ok + 1))
else
    echo "FAIL: Logowanie zwykłego użytkownika przez SSH - przerywam testy"
    exit 1
fi

# Test 2 Root nie może się zalogować przez ssh nawet z kluczem

if ! ssh -t "$VM" 'sudo mkdir -p /root/.ssh && sudo cp ~/.ssh/authorized_keys /root/.ssh/authorized_keys'; then
    echo "FAIL: Nie udało się przygotować testu 2 (kopiowanie klucza dla roota)"
    fail=$((fail + 1))
else
    wynik=$(ssh -o BatchMode=yes -o ConnectTimeout=5 -l root "$VM" 'echo OK' 2>&1)

    if echo "$wynik" | grep -q 'Permission denied'; then
        echo "OK: Root nie może zalogować się przez SSH"
        ok=$((ok + 1))
    elif echo "$wynik" | grep -q '^OK$'; then
        echo "FAIL: Root zalogował się przez SSH kluczem"
        fail=$((fail + 1))
    else
        echo "FAIL: Błąd testu: $wynik"
        fail=$((fail + 1))
    fi
fi

ssh -t "$VM" 'sudo rm -f /root/.ssh/authorized_keys'

# 5.1.16 Ensure sshd MaxAuthTries is configured (Automated)

KLUCZE="$(dirname "$0")/cis-zle-klucze"
mkdir -p "$KLUCZE"
for i in 1 2 3 4; do
    if [[ ! -f "$KLUCZE/zly$i" ]]; then #generuje tylko jeżeli jeszcze nie istnieje
        ssh-keygen -t ed25519 -N "" -q -f "$KLUCZE/zly$i" #puste hasło do klucza
    fi
done

wynik=$(ssh -o BatchMode=yes -o ConnectTimeout=5 -o IdentitiesOnly=yes -i "$KLUCZE/zly1" -i "$KLUCZE/zly2" -i "$KLUCZE/zly3" -i "$KLUCZE/zly4" "$VM" 'echo OK' 2>&1)
if echo "$wynik" | grep -q 'Too many authentication failures'; then
    echo "OK: MaxAuthTries działa poprawnie"
    ok=$((ok + 1))
elif echo "$wynik" | grep -q '^OK$'; then
    echo "FAIL: MaxAuthTries nie działa poprawnie"
    fail=$((fail + 1))
else
    echo "FAIL: Błąd testu: $wynik"
    fail=$((fail + 1))
fi

# 5.1.7 Ensure sshd ClientAliveInterval and ClientAliveCountMax are configured (Automated)
if ssh -o BatchMode=yes "$VM" 'sleep 50; echo OK' 2>/dev/null | grep -q '^OK$'; then
    echo "OK: Bezczynna sesja SSH przetrwała 50 s"
    ok=$((ok + 1))
else
    echo "FAIL: Bezczynna sesja SSH została zerwana"
    fail=$((fail + 1))
fi

# 5.1.13 Ensure sshd LoginGraceTime is configured (Automated)
# Otwieram połączenie TCP do SSH i nic nie wysyłam - serwer ma je zamknąć najpóźniej po 60 s

start=$SECONDS
timeout 130 bash -c 'exec 3<>/dev/tcp/127.0.0.1/2222 && cat <&3 > /dev/null' 2>/dev/null
czas=$((SECONDS - start))

if [[ "$czas" -lt 5 ]]; then
    echo "FAIL: Nie udało się nawiązać połączenia testowego (zakończone po ${czas} s)"
    fail=$((fail + 1))
elif [[ "$czas" -le 65 ]]; then
    echo "OK: Serwer zamknął nieuwierzytelnione połączenie po ${czas} s"
    ok=$((ok + 1))
else
    echo "FAIL: Nieuwierzytelnione połączenie trwało ${czas} s (dłużej niż 60 s)"
    fail=$((fail + 1))
fi

# 5.1.4 Ensure sshd access is configured (Automated)

# Użytkownik spoza AllowUsers nie może zalogować się przez SSH - 5.1.4
# Ten sam użytkownik (z hasłem) jest potem używany w teście su - 5.2.7
TEST_USER="cistest"
TEST_PASS="Cistest2026x"
cistest_gotowy=0

if ! ssh -t "$VM" "(id $TEST_USER >/dev/null 2>&1 || sudo useradd -m -s /bin/bash $TEST_USER) && \
    echo '$TEST_USER:$TEST_PASS' | sudo chpasswd && \
    sudo mkdir -p /home/$TEST_USER/.ssh && \
    sudo cp ~/.ssh/authorized_keys /home/$TEST_USER/.ssh/authorized_keys && \
    sudo chown -R $TEST_USER:$TEST_USER /home/$TEST_USER/.ssh && \
    sudo chmod 700 /home/$TEST_USER/.ssh && \
    sudo chmod 600 /home/$TEST_USER/.ssh/authorized_keys"; then
    echo "FAIL: Nie udało się przygotować testu 5.1.4 (tworzenie użytkownika $TEST_USER)"
    fail=$((fail + 1))
    #sprawdza czy uzytkownik istnieje, jeśli nie to go tworzy, ustawia hasło, kopiuje klucz (ma poprawne dane logowania) i ustawia uprawnienia
    #ustawienia praw na koncu muszą być, bo ktoś inny mógłby dopisać swoj klucz do authorized_keys
else
    cistest_gotowy=1
    wynik=$(ssh -o BatchMode=yes -o ConnectTimeout=5 -l "$TEST_USER" "$VM" 'echo OK' 2>&1)

    if echo "$wynik" | grep -q 'Permission denied'; then
        echo "OK: Użytkownik spoza listy AllowUsers nie może zalogować się przez SSH"
        ok=$((ok + 1))
    elif echo "$wynik" | grep -q '^OK$'; then
        echo "FAIL: Użytkownik spoza listy AllowUsers zalogował się przez SSH"
        fail=$((fail + 1))
    else
        echo "FAIL: Nie udało się przeprowadzić testu: $wynik"
        fail=$((fail + 1))
    fi
fi

# 5.2.7 Ensure access to the su command is restricted (Automated)
# Mój użytkownik (spoza sugroup) próbuje su na konto cistest z POPRAWNYM hasłem
# script daje su terminal, a hasło jest wpisywane po 2 s przez printf

if [[ "$cistest_gotowy" -ne 1 ]]; then
    echo "FAIL: Test su pominięty - brak użytkownika $TEST_USER"
    fail=$((fail + 1))
else
    wynik=$(ssh "$VM" "(sleep 2; printf '%s\n' '$TEST_PASS') | timeout 15 script -qc 'su - $TEST_USER -c \"echo SU_OK\"' /dev/null" 2>&1)

    if echo "$wynik" | grep -q 'Permission denied'; then
        echo "OK: su z poprawnym hasłem zablokowane dla użytkownika spoza sugroup"
        ok=$((ok + 1))
    elif echo "$wynik" | grep -q 'SU_OK'; then
        echo "FAIL: Zwykły użytkownik przełączył się przez su na $TEST_USER"
        fail=$((fail + 1))
    else
        echo "FAIL: Nieoczekiwany wynik testu su (np. złe hasło): $wynik"
        fail=$((fail + 1))
    fi
fi

ssh -t "$VM" "sudo userdel -r $TEST_USER 2>/dev/null"

# 4.1.2 Ensure ufw service is configured (Automated)
# 4.1.3 Ensure ufw incoming default is configured (Automated)
# Na VM startuje serwer na porcie 8080 (bez reguły allow) - z komputera ma być nieosiągalny
# Wymaga przekierowania portu 8080 -> 8080 w VirtualBox

ssh "$VM" 'nohup timeout 30 python3 -m http.server 8080 > /dev/null 2>&1 < /dev/null &'
sleep 2

if [[ "$(ssh "$VM" 'curl -s -o /dev/null -w "%{http_code}" http://127.0.0.1:8080/')" != "200" ]]; then
    echo "FAIL: Nie udało się uruchomić serwera testowego na porcie 8080"
    fail=$((fail + 1))
else
    curl -s --max-time 5 -o /dev/null http://127.0.0.1:8080/
    kod=$?
    if [[ "$kod" -eq 0 ]]; then
        echo "FAIL: Port 8080 bez reguły allow jest osiągalny z zewnątrz"
        fail=$((fail + 1))
    elif [[ "$kod" -eq 7 ]]; then
        echo "FAIL: Brak przekierowania portu 8080 w VirtualBox (test niemożliwy)"
        fail=$((fail + 1))
    else
        echo "OK: Firewall blokuje port 8080 bez reguły allow (curl kod $kod)"
        ok=$((ok + 1))
    fi
fi

# 5.2.3 Ensure sudo log file exists (Automated)
# Wykonuję polecenie z unikalnym znacznikiem przez sudo i sprawdzam czy trafiło do /var/log/sudo.log
# Wynik trafia do pliku na VM, żeby prośba o hasło sudo była widoczna na ekranie

ZNACZNIK="cistest_$RANDOM"

ssh -t "$VM" "rm -f /tmp/cis_wynik
sudo echo $ZNACZNIK > /dev/null || { echo BLAD > /tmp/cis_wynik; exit; }
if sudo grep -q $ZNACZNIK /var/log/sudo.log 2>/dev/null; then echo JEST > /tmp/cis_wynik; else echo BRAK > /tmp/cis_wynik; fi"

wynik=$(ssh "$VM" 'cat /tmp/cis_wynik 2>/dev/null; rm -f /tmp/cis_wynik')

if [[ "$wynik" == "JEST" ]]; then
    echo "OK: Polecenie wykonane przez sudo zapisało się w /var/log/sudo.log"
    ok=$((ok + 1))
elif [[ "$wynik" == "BRAK" ]]; then
    echo "FAIL: Polecenia sudo nie ma w /var/log/sudo.log"
    fail=$((fail + 1))
else
    echo "FAIL: Nie udało się przeprowadzić testu sudo: ${wynik:-brak wyniku}"
    fail=$((fail + 1))
fi

# 5.4.3.2 Ensure default user shell timeout is configured
# Użytkownik próbuje wyłączyć TMOUT w powłoce logowania - ma dostać błąd readonly

wynik=$(ssh "$VM" 'bash -lc "TMOUT=0; echo ZMIENIONO"' 2>&1)

if echo "$wynik" | grep -q 'readonly variable'; then
    echo "OK: Użytkownik nie może wyłączyć TMOUT"
    ok=$((ok + 1))
elif echo "$wynik" | grep -q 'ZMIENIONO'; then
    echo "FAIL: Użytkownik wyłączył TMOUT"
    fail=$((fail + 1))
else
    echo "FAIL: Nieoczekiwany wynik testu TMOUT: $wynik"
    fail=$((fail + 1))
fi

# 1.4.2 Ensure access to bootloader config is configured (Automated)
# Zwykły użytkownik nie może odczytać grub.cfg

if ! ssh "$VM" 'test -f /boot/grub/grub.cfg'; then
    echo "FAIL: Brak pliku /boot/grub/grub.cfg"
    fail=$((fail + 1))
else
    wynik=$(ssh "$VM" 'cat /boot/grub/grub.cfg > /dev/null 2>&1 && echo CZYTA || echo ODMOWA')
    if [[ "$wynik" == "ODMOWA" ]]; then
        echo "OK: Zwykły użytkownik nie może odczytać grub.cfg"
        ok=$((ok + 1))
    elif [[ "$wynik" == "CZYTA" ]]; then
        echo "FAIL: Zwykły użytkownik może odczytać grub.cfg"
        fail=$((fail + 1))
    else
        echo "FAIL: Nieoczekiwany wynik testu grub.cfg: $wynik"
        fail=$((fail + 1))
    fi
fi

# 1.1.1.10 Ensure usb-storage kernel module is not available (Automated)
# Root próbuje załadować moduł - sprawdzam w lsmod czy się udało

if ! ssh "$VM" 'modinfo usb-storage > /dev/null 2>&1'; then
    echo "FAIL: Brak modułu usb-storage w systemie (test niemożliwy)"
    fail=$((fail + 1))
else
    ssh -t "$VM" 'sudo modprobe usb-storage' > /dev/null 2>&1
    wynik=$(ssh "$VM" 'lsmod | grep -q "^usb_storage" && echo ZALADOWANY || echo BRAK')
    if [[ "$wynik" == "BRAK" ]]; then
        echo "OK: Próba załadowania usb-storage nie powiodła się"
        ok=$((ok + 1))
    elif [[ "$wynik" == "ZALADOWANY" ]]; then
        echo "FAIL: Moduł usb-storage został załadowany"
        fail=$((fail + 1))
    else
        echo "FAIL: Nieoczekiwany wynik testu usb-storage: $wynik"
        fail=$((fail + 1))
    fi
fi

# 2.3.1.1 Ensure a single time synchronization daemon is in use
# Działa timesyncd, nie działa chrony, a zegar jest zsynchronizowany

wynik=$(ssh "$VM" 'echo "$(systemctl is-active systemd-timesyncd) $(systemctl is-active chrony 2>/dev/null) $(timedatectl show -p NTPSynchronized --value)"')

if [[ "$wynik" == "active inactive yes" ]]; then
    echo "OK: Działa tylko systemd-timesyncd i zegar jest zsynchronizowany"
    ok=$((ok + 1))
else
    echo "FAIL: Synchronizacja czasu (timesyncd chrony zsynchronizowany): $wynik"
    fail=$((fail + 1))
fi

# 3.3.1.8 / 3.3.1.16 / 3.3.1.18 - parametry jądra po restarcie
# Restart VM i sprawdzenie czy wartości przetrwały (wcześniej nadpisywał je plik UFW)
# boot_id zmienia się przy każdym starcie - dowód, że VM naprawdę się zrestartowała
# TEN TEST MUSI BYĆ OSTATNI

boot_przed=$(ssh "$VM" 'cat /proc/sys/kernel/random/boot_id')
ssh -t "$VM" 'sudo systemctl reboot' 2>/dev/null
sleep 20

boot_po=""
for i in {1..24}; do
    boot_po=$(ssh -o BatchMode=yes -o ConnectTimeout=5 "$VM" 'cat /proc/sys/kernel/random/boot_id' 2>/dev/null)
    if [[ -n "$boot_po" && "$boot_po" != "$boot_przed" ]]; then
        break
    fi
    sleep 5
done

if [[ -z "$boot_po" || "$boot_po" == "$boot_przed" ]]; then
    echo "FAIL: VM nie wróciła po restarcie w ciągu 2 minut"
    fail=$((fail + 1))
else
    wynik=$(ssh "$VM" 'echo "$(sysctl -n net.ipv4.conf.all.accept_redirects) $(sysctl -n net.ipv4.conf.all.log_martians) $(sysctl -n net.ipv4.tcp_syncookies)"')
    if [[ "$wynik" == "0 1 1" ]]; then
        echo "OK: Po restarcie accept_redirects=0, log_martians=1, tcp_syncookies=1"
        ok=$((ok + 1))
    else
        echo "FAIL: Po restarcie (accept_redirects log_martians tcp_syncookies): $wynik, oczekiwano 0 1 1"
        fail=$((fail + 1))
    fi
fi

# Wynik testów

echo "Wynik: $ok OK, $fail FAIL"
[ "$fail" -eq 0 ]