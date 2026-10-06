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


# Wynik testów

echo "Wynik: $ok OK, $fail FAIL"
[ "$fail" -eq 0 ]
