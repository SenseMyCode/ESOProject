# Wybrane zalecenia

CIS Ubuntu Linux 24.04 LTS Benchmark v2.0.0, profil Server.

21 zaleceń z różnych obszarów systemu.
Wszystkie mają status Automated, czyli da się je sprawdzić skryptem.
Wszystkie należą do profilu Level 1 - Server.
Wybrałem tylko zalecenia, które nie wymagają wcześniejszego wdrożenia innych zaleceń z benchmarku, żeby każde dało się wdrożyć i sprawdzić samodzielnie.

Trudność w skali: 1 – łatwe, 2 – średnie, 3 – trudne.

Pkt audytu – ile punktów maksymalnie daje zalecenie w `audit.sh` (każde sprawdzenie cząstkowe = 1 pkt).

Wdrożone – ✓ oznacza, że zalecenie ma sprawdzenie w `audit.sh`, naprawę w `harden.sh` i test w `tests.sh`.

| Nr CIS | Zalecenie | Kategoria | Profil | Trudność | Pkt audytu | Wdrożone |
|---|---|---|---|---|---|---|
| 1.1.1.10 | Wyłączony moduł jądra usb-storage (brak obsługi pamięci USB) | Moduły jądra | L1 | 2 | 2 | ✓ |
| 1.4.2 | Dostęp do konfiguracji bootloadera (grub.cfg) tylko dla roota | Rozruch systemu | L1 | 1 | 2 | ✓ |
| 1.5.7 | Wyłączone automatyczne raportowanie błędów (Apport) | Utwardzanie procesów | L1 | 1 | 2 | ✓ |
| 1.6.2 | Baner /etc/issue bez informacji o systemie | Banery logowania | L1 | 1 | 2 | ✓ |
| 2.3.1.1 | Działa tylko jedna usługa synchronizacji czasu | Usługi systemowe | L1 | 1 | 2 | ✓ |
| 2.4.1.2 | Dostęp do /etc/crontab tylko dla roota | Harmonogram zadań | L1 | 1 | 2 | ✓ |
| 3.3.1.8 | Ignorowanie przekierowań ICMP | Bezpieczeństwo sieci | L1 | 1 | 2 | ✓ |
| 3.3.1.16 | Logowanie podejrzanych pakietów (martians) | Bezpieczeństwo sieci | L1 | 1 | 2 | ✓ |
| 3.3.1.18 | Włączone TCP SYN cookies | Bezpieczeństwo sieci | L1 | 1 | 2 | ✓ |
| 4.1.2 | Usługa ufw jest włączona i aktywna | Firewall | L1 | 2 | 3 | ✓ |
| 4.1.3 | Domyślne blokowanie ruchu przychodzącego w ufw | Firewall | L1 | 2 | 2 | ✓ |
| 5.1.4 | Ograniczenie dostępu SSH do wybranych użytkowników lub grup | SSH | L1 | 2 | 2 | ✓ |
| 5.1.7 | Rozłączanie niereagujących (martwych) połączeń SSH | SSH | L1 | 1 | 2 | ✓ |
| 5.1.13 | Limit czasu na zalogowanie się przez SSH (LoginGraceTime) | SSH | L1 | 1 | 2 | ✓ |
| 5.1.16 | Limit prób uwierzytelnienia w SSH (MaxAuthTries) | SSH | L1 | 1 | 2 | ✓ |
| 5.1.20 | Zakaz logowania na konto root przez SSH | SSH | L1 | 1 | 2 | ✓ |
| 5.2.3 | Osobny plik logu dla sudo | Uprawnienia | L1 | 1 | 2 | ✓ |
| 5.2.7 | Ograniczenie dostępu do polecenia su | Uprawnienia | L1 | 2 | 2 | ✓ |
| 5.4.1.1 | Maksymalny okres ważności hasła | Polityka haseł | L1 | 2 | 2 | ✓ |
| 5.4.3.2 | Automatyczne wylogowanie nieaktywnej powłoki | Konta i uwierzytelnianie | L1 | 1 | 2 | ✓ |
| 5.4.3.3 | Domyślna maska uprawnień nowych plików (umask 027) | Konta i uwierzytelnianie | L1 | 2 | 2 | ✓ |

Łącznie: 21 zaleceń, 28 punktów trudności, 43 punkty w audycie.

## Wyniki

`audit.sh` zapisuje wynik do pliku CSV w katalogu `results/` (jeden wiersz na zalecenie: punkty, maksimum, status zgodne / częściowo / niezgodne, na końcu wiersz SUMA).
Uruchomienie z komputera: `./run.sh audit.sh przed` lub `./run.sh audit.sh po` – plik `audit_<etykieta>_<data>.csv` jest pobierany do lokalnego `results/`.
