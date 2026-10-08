#!/usr/bin/env bash

VM="cisvm"
ok=0
fail=0

# 5.1.20 Ensure sshd PermitRootLogin is disabled

# Test 1 Zwykły użytkownik może zalogować się przez SSH 

if ssh -o BatchMode=yes -o ConnectTimeout=5 "$VM" 'echo OK' 2>/dev/null | grep -q '^OK$'; then
    echo "OK: Logowanie zwykłego użytkownika przez SSH"
    ok=$((ok + 1))
else
    echo "FAIL: Logowanie zwykłego użytkownika przez SSH"
    fail=$((fail + 1))
fi

# Test 2 Root nie może się zalogować przez ssh nawet z kluczem

ssh -t "$VM" 'sudo mkdir -p /root/.ssh && sudo cp ~/.ssh/authorized_keys /root/.ssh/authorized_keys'

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

ssh -t "$VM" 'sudo rm -f /root/.ssh/authorized_keys'

# 5.1.16 Ensure sshd MaxAuthTries is configured (Automated)

KLUCZE="$(dirname "$0")/cis-zle-klucze"
mkdir -p "$KLUCZE"
for i in 1 2 3 4; do
    if [[ ! -f "$KLUCZE/zly$i" ]]; then
        ssh-keygen -t ed25519 -N "" -q -f "$KLUCZE/zly$i"
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


# Wynik testów

echo "Wynik: $ok OK, $fail FAIL"
[ "$fail" -eq 0 ]


