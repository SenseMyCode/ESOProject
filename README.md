# ESOProject - hardening Ubuntu 24.04 według CIS

Projekt zabezpiecza świeżo zainstalowany Ubuntu 24.04 LTS Server według wybranych zaleceń z CIS Ubuntu Linux 24.04 LTS Benchmark v2.0.0 (profil Level 1 - Server).

Są tu trzy skrypty w Bashu:

- `audit.sh` sprawdza, czy system spełnia zalecenia, i liczy wynik w punktach i procentach
- `harden.sh` wprowadza zmiany w systemie
- `tests.sh` sprawdza z zewnątrz, czy zabezpieczenia naprawdę działają i czy dalej da się normalnie korzystać z systemu (SSH, sudo itd.)

Lista 21 wybranych zaleceń jest w [docs/zalecenia.md](docs/zalecenia.md), a moje notatki do każdego z nich w [docs/notes.txt](docs/notes.txt).

Samego PDF-a z benchmarkiem nie ma w repo, bo CIS nie pozwala go udostępniać. Można go pobrać za darmo ze strony CIS po rejestracji.

## Struktura

```
audit.sh            audyt zgodności, zapis wyniku do CSV
harden.sh           wdrożenie zaleceń
tests.sh            testy działania (uruchamiane z komputera, nie z VM)
run.sh              wysyła skrypty na VM i uruchamia wybrany
results/            wyniki audytów w CSV
docs/zalecenia.md   tabela wybranych zaleceń
docs/notes.txt      notatki do zaleceń
cis-zle-klucze/     klucze SSH do testu MaxAuthTries (celowo nigdzie nieautoryzowane)
```

## Środowisko

Ja używałem:

- VirtualBox z maszyną Ubuntu 24.04 LTS Server (2 CPU, 2-4 GB RAM, dysk 25 GB)
- przy instalacji zaznaczone "Install OpenSSH server"
- sieć NAT z przekierowaniem portów:
  - host `2222` -> gość `22` (SSH)
  - host `8080` -> gość `8080` (potrzebne tylko do testu firewalla)
- na komputerze Bash (Linux, macOS albo Git Bash na Windowsie) z `ssh`, `scp` i `curl`

Po instalacji warto zrobić aktualizację i snapshot czystego systemu, żeby w każdej chwili móc wrócić do stanu "przed":

```
sudo apt update && sudo apt full-upgrade -y
sudo reboot
```

## Konfiguracja SSH

Skrypty łączą się z VM przez alias `cisvm`. Trzeba go dodać na komputerze w `~/.ssh/config`:

```
Host cisvm
    HostName 127.0.0.1
    Port 2222
    User vboxuser
```

`User` zmień na swojego użytkownika na VM. Potem skopiuj klucz, żeby logowanie działało bez hasła:

```
ssh-copy-id cisvm
ssh cisvm 'echo OK'
```

## Uruchomienie

Wszystko odpalam z katalogu projektu na komputerze. `run.sh` kopiuje skrypty do `~/cis` na VM i uruchamia je przez `sudo`, więc VM zapyta o hasło.

1. Audyt przed zmianami:

   ```
   ./run.sh audit.sh przed
   ```

2. Hardening:

   ```
   ./run.sh harden.sh
   ```

3. Audyt po zmianach:

   ```
   ./run.sh audit.sh po
   ```

4. Testy:

   ```
   ./tests.sh
   ```

Po każdym audycie plik CSV jest pobierany do `results/` jako `audit_<etykieta>_<data>.csv`. Jest w nim jeden wiersz na zalecenie (punkty, maksimum, status), a na końcu suma. Separator to średnik, więc plik otwiera się od razu w Excelu albo LibreOffice.

Skrypty można też uruchomić bezpośrednio na VM, np. `sudo ./audit.sh przed`, wtedy CSV zostaje w `~/cis/results/`.

## O czym trzeba pamiętać

- Przed `harden.sh` zrób snapshot VM.
- `harden.sh` trzeba uruchomić przez `sudo` jako zwykły użytkownik, a nie z konta root. Ustawia on `AllowUsers` na użytkownika, który go uruchomił, więc inne konta stracą dostęp przez SSH.
- Firewall jest włączany na samym końcu `harden.sh`, dopiero po dodaniu reguły dla portu 22, żeby nie odciąć sobie SSH.
- `harden.sh` można uruchomić kilka razy, kolejne uruchomienia nic nie psują.
- `tests.sh` kilka razy prosi o hasło sudo na VM, tworzy na chwilę użytkownika `cistest` i na końcu restartuje VM, żeby sprawdzić, czy ustawienia jądra przetrwały restart.
- Po ręcznym `update-grub` uprawnienia `grub.cfg` wracają do domyślnych i trzeba ponownie uruchomić `harden.sh` (przy aktualizacjach przez apt pilnuje tego hook dodany przez harden).
