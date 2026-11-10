#!/usr/bin/env bash
# run.sh - wysyła aktualne skrypty na VM i uruchamia wybrany
# Użycie: ./run.sh <skrypt.sh> [argumenty]
#   np.   ./run.sh audit.sh przed    ->  wynik CSV trafia do results/ na tym komputerze

VM="cisvm"
CEL="cis"

skrypt="$1"
if [ -z "$skrypt" ] || [ ! -f "$skrypt" ]; then
    echo "Użycie: ./run.sh <skrypt.sh> [argumenty]"
    exit 1
fi
shift

ssh "$VM" "mkdir -p ~/$CEL" || exit 1
scp ./*.sh "$VM:~/$CEL/" || exit 1
ssh -t "$VM" "cd ~/$CEL && chmod +x ./*.sh && sudo ./$skrypt $*"
kod=$?

# Po audycie pobieram pliki CSV z VM do lokalnego katalogu results/
if [ "$skrypt" = "audit.sh" ]; then
    mkdir -p ./results
    scp "$VM:~/$CEL/results/*.csv" ./results/ && echo "Pobrano wyniki CSV do ./results/"
fi

exit $kod
