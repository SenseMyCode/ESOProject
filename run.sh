#!/usr/bin/env bash
# run.sh - wysyła aktualne skrypty na VM i uruchamia wybrany
# Użycie: ./run.sh audit.sh

VM="cisvm"     
CEL="cis"      

skrypt="$1"
if [ -z "$skrypt" ] || [ ! -f "$skrypt" ]; then
    echo "Użycie: ./run.sh <skrypt.sh>"
    exit 1
fi

ssh "$VM" "mkdir -p ~/$CEL" || exit 1
scp ./*.sh "$VM:~/$CEL/" || exit 1
ssh -t "$VM" "cd ~/$CEL && chmod +x ./*.sh && sudo ./$skrypt"