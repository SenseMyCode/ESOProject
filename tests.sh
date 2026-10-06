#!/usr/bin/env bash

VM="cisvm"
ok=0
fail=0

# 5.1.20 Ensure sshd PermitRootLogin is disabled - normal user can still login

if ssh -o BatchMode=yes -o ConnectTimeout=5 "$VM" 'echo OK' 2>/dev/null | grep -q '^OK$'; then
    echo "OK: Logowanie zwykłego użytkownika przez SSH"
    ok=$((ok + 1))
else
    echo "FAIL: Logowanie zwykłego użytkownika przez SSH"
    fail=$((fail + 1))
fi

echo "Wynik: $ok OK, $fail FAIL"
[ "$fail" -eq 0 ]
