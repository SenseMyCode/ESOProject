# Raport końcowy

Hardening Ubuntu 24.04 LTS Server według CIS Ubuntu Linux 24.04 LTS Benchmark v2.0.0 (Level 1 - Server), 21 zaleceń.
Pełny cykl (audyt przed → harden → audyt po → testy) wykonany 10.11.2026 na VM w VirtualBox.

Pliki źródłowe:

- [results/audit_przed_20261110_110758.csv](../results/audit_przed_20261110_110758.csv) - audyt przed
- [results/audit_po_20261110_111153.csv](../results/audit_po_20261110_111153.csv) - audyt po
- [results/harden_1.txt](../results/harden_1.txt), [results/harden_2.txt](../results/harden_2.txt) - dwa uruchomienia `harden.sh`
- [results/testy.txt](../results/testy.txt) - wynik `tests.sh`

## 1. Tabela przed / po

Status: **0** - niezgodne, **1** - częściowo, **2** - zgodne. Tabela jest złożona z dwóch plików CSV (kolumny `punkty`, `max_punkty`, `status`).

| Nr CIS | Zalecenie | Pkt przed | Status przed | Pkt po | Status po | Zmiana |
|---|---|---|---|---|---|---|
| 5.1.20 | Ensure sshd PermitRootLogin is disabled | 0/2 | 0 | 2/2 | 2 | ↑ |
| 5.1.16 | Ensure sshd MaxAuthTries is configured | 0/2 | 0 | 2/2 | 2 | ↑ |
| 5.1.7 | Ensure sshd ClientAliveInterval and ClientAliveCountMax are configured | 1/2 | 1 | 2/2 | 2 | ↑ |
| 5.1.4 | Ensure sshd access is configured | 0/2 | 0 | 2/2 | 2 | ↑ |
| 4.1.2 | Ensure ufw service is configured | 2/3 | 1 | 3/3 | 2 | ↑ |
| 4.1.3 | Ensure ufw incoming default is configured | 0/2 | 0 | 2/2 | 2 | ↑ |
| 3.3.1.8 | Ensure net.ipv4.conf.all.accept_redirects is configured | 1/2 | 1 | 2/2 | 2 | ↑ |
| 3.3.1.16 | Ensure net.ipv4.conf.all.log_martians is configured | 0/2 | 0 | 2/2 | 2 | ↑ |
| 3.3.1.18 | Ensure net.ipv4.tcp_syncookies is configured | 1/2 | 1 | 2/2 | 2 | ↑ |
| 5.2.3 | Ensure sudo log file exists | 0/2 | 0 | 2/2 | 2 | ↑ |
| 5.2.7 | Ensure access to the su command is restricted | 0/2 | 0 | 2/2 | 2 | ↑ |
| 2.3.1.1 | Ensure a single time synchronization daemon is in use | 2/2 | 2 | 2/2 | 2 | = |
| 5.4.3.2 | Ensure default user shell timeout is configured | 0/2 | 0 | 2/2 | 2 | ↑ |
| 5.1.13 | Ensure sshd LoginGraceTime is configured | 0/2 | 0 | 2/2 | 2 | ↑ |
| 1.4.2 | Ensure access to bootloader config is configured | 2/2 | 2 | 2/2 | 2 | = |
| 1.1.1.10 | Ensure usb-storage kernel module is not available | 1/2 | 1 | 2/2 | 2 | ↑ |
| 2.4.1.2 | Ensure access to /etc/crontab is configured | 1/2 | 1 | 2/2 | 2 | ↑ |
| 5.4.3.3 | Ensure default user umask is configured | 0/2 | 0 | 2/2 | 2 | ↑ |
| 1.6.2 | Ensure /etc/issue is configured | 0/2 | 0 | 2/2 | 2 | ↑ |
| 5.4.1.1 | Ensure password expiration is configured | 0/2 | 0 | 2/2 | 2 | ↑ |
| 1.5.7 | Ensure Automatic Error Reporting is configured | 0/2 | 0 | 2/2 | 2 | ↑ |
| **SUMA** | | **11/43** | | **43/43** | | |

Przed: 2 zalecenia zgodne, 6 częściowo, 13 niezgodnych. Po: 21 zgodnych.

## 2. Metryki

| Metryka | Wynik |
|---|---|
| Zgodność przed (punkty) | 11/43 = **25%** |
| Zgodność przed (zalecenia w pełni zgodne) | 2/21 = 10% |
| Zgodność po (punkty) | 43/43 = **100%** |
| Zgodność po (zalecenia w pełni zgodne) | 21/21 = 100% |
| Automatyzacja implementacji | **21/21** - każde zalecenie wdraża `harden.sh`, bez ręcznych kroków |
| Automatyzacja weryfikacji | **21/21** - każde zalecenie sprawdza `audit.sh` i zapisuje wynik do CSV |
| Wynik testów (`tests.sh`) | **17 OK / 2 FAIL** z 19 testów (89%), oba FAIL z powodu środowiska testowego, opis w punkcie 4 |
| Współczynnik regresji | **0%** - 0 z 2 zaleceń zgodnych przed spadło po hardeningu, 0 funkcji systemu zepsutych (logowanie SSH, sudo, synchronizacja czasu działają) |
| Idempotentność | drugie uruchomienie `harden.sh` niczego nie zepsuło (`Skipping adding existing rule`), audyt dalej 100% |
| Czas | audyt przed 11:07:58 → audyt po 11:11:53 (ok. 4 min z dwoma uruchomieniami harden), testy ok. 6-7 min (w tym czekanie 50 s, 60 s i restart VM), cały cykl ok. **11 min** |

## 3. Skutki uboczne zaleceń

| Nr CIS | Skutek uboczny |
|---|---|
| 5.1.20 | Root nie zaloguje się przez SSH nawet kluczem. Administrator loguje się na własne konto i dopiero robi `sudo`. |
| 5.1.16 | Klient z wieloma kluczami w agencie może dostać `Too many authentication failures` zanim dojdzie do dobrego klucza. Trzeba wtedy użyć `IdentitiesOnly=yes`. |
| 5.1.7 | Zawieszone połączenia (np. po zerwaniu sieci) są zamykane po ok. 45 s. Bezczynna, ale żywa sesja nie jest rozłączana (test: przetrwała 50 s). |
| 5.1.4 | Przez SSH zaloguje się tylko użytkownik, który uruchomił `harden.sh` (`AllowUsers`). Każde nowe konto trzeba dopisać ręcznie. |
| 5.1.13 | Na zalogowanie jest 60 s - przy wolnym wpisywaniu hasła lub 2FA połączenie może zostać zamknięte. |
| 4.1.2 / 4.1.3 | Cały ruch przychodzący oprócz 22/tcp jest blokowany. Każda nowa usługa (np. serwer WWW) wymaga `ufw allow`. Plik sysctl UFW nadpisywał parametry jądra po restarcie - `harden.sh` musi to obsługiwać. |
| 3.3.1.8 | System ignoruje także prawidłowe przekierowania ICMP od routera - w nietypowych sieciach ruch może iść gorszą trasą. |
| 3.3.1.16 | Więcej wpisów w logu jądra; przy dużym ruchu z podejrzanymi adresami log może szybko rosnąć. |
| 3.3.1.18 | Przy zapełnionej kolejce SYN część opcji TCP z pakietu SYN może zostać utracona. W normalnej pracy brak wpływu (Ubuntu ma to domyślnie włączone w jądrze). |
| 5.2.3 | Plik `/var/log/sudo.log` rośnie bez ograniczeń - `harden.sh` nie dodaje dla niego rotacji (logrotate). |
| 5.2.7 | `su` działa tylko dla roota, bo grupa `sugroup` jest pusta. Przełączanie się na inne konto tylko przez `sudo -u` / `sudo -i`. |
| 2.3.1.1 | Jeśli zainstalowane jest chrony, zostaje usunięte razem z `apt autoremove`, które może usunąć też inne nieużywane pakiety. Na tej VM chrony nie było. |
| 5.4.3.2 | Bezczynna powłoka jest zamykana po 15 min i użytkownik nie może tego wyłączyć (readonly). Dotyczy też sesji w tmux/screen czekających na znak zachęty. |
| 1.4.2 | Ręczne `update-grub` przywraca domyślne prawa `grub.cfg` - trzeba ponownie uruchomić `harden.sh`. Przy aktualizacjach przez apt pilnuje tego dodany hook. |
| 1.1.1.10 | Pendrive'y i dyski USB nie działają, także do backupu. |
| 2.4.1.2 | Zwykli użytkownicy nie mogą przeczytać `/etc/crontab`. Na samo działanie crona brak wpływu. |
| 5.4.3.3 | Nowe pliki mają 640, katalogi 750 - pliki, które mają być czytelne dla innych (np. wspólne katalogi), wymagają ręcznego `chmod`. |
| 1.6.2 | Baner przed logowaniem nie pokazuje wersji systemu. Brak wpływu na działanie. |
| 5.4.1.1 | Hasła wygasają po 365 dniach. Po wygaśnięciu system wymusi zmianę hasła przy logowaniu, co może przerwać nieinteraktywne logowania (skrypty, `BatchMode`). |
| 1.5.7 | Po awarii programu nie powstaje raport w `/var/crash/` - trudniej szukać przyczyny błędów. |

## 4. Problemy i wnioski

**Problemy:**

1. **Test firewalla (4.1.2 / 4.1.3) - FAIL.** Brakowało przekierowania portu 8080 w VirtualBox, więc testu nie dało się przeprowadzić. To błąd konfiguracji środowiska, nie zapory - audyt potwierdza `default deny incoming` i aktywny ufw.
2. **Test banera (1.6.2) - FAIL.** `agetty --show-issue` nie działa przez SSH bez terminala i zwraca błąd. Audyt potwierdza poprawną treść `/etc/issue`. Test trzeba poprawić, np. czytając `/etc/issue` bezpośrednio i szukając w nim sekwencji `\m`, `\r`, `\s`, `\v` oraz nazwy systemu.
3. **Parametry jądra po restarcie.** Plik sysctl używany przez UFW wczytuje się po plikach systemowych i nadpisywał ustawienia. Rozwiązanie: `harden.sh` komentuje te parametry we wszystkich plikach, a `tests.sh` sprawdza wartości po restarcie VM.
4. **Uprawnienia `grub.cfg`** wracają do domyślnych po każdym `update-grub` - częściowo rozwiązane hookiem apt.
5. **Testy wymagają wielu haseł sudo** i ręcznego udziału, więc nie da się ich puścić całkiem bez nadzoru.

**Wnioski:**

- Wszystkie 21 zaleceń udało się wdrożyć i sprawdzić automatycznie - zgodność wzrosła z 25% do 100% punktów, bez regresji.
- Sam audyt konfiguracji to za mało - testy z zewnątrz (np. root przez osobny sshd, restart VM dla sysctl) wykazują, czy zabezpieczenie naprawdę działa.
- `harden.sh` jest idempotentny, więc po przerwaniu wystarczy go uruchomić ponownie. Mimo to przed hardeningiem trzeba zrobić snapshot VM.
- Część zaleceń (5.1.4, 5.4.3.2, 5.4.1.1, 4.1.3) ma realny wpływ na pracę administratora - przed wdrożeniem na prawdziwym serwerze trzeba je dopasować do jego użytkowników i usług.
- Do poprawy: przekierowanie portu 8080 w środowisku testowym, test banera 1.6.2 oraz rotacja `/var/log/sudo.log`.
