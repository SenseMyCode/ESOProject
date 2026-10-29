# Wybrane zalecenia

CIS Ubuntu Linux 24.04 LTS Benchmark v2.0.0, profil Server.

22 zalecenia z różnych obszarów.
Wszystkie mają status Automated, czyli da się je sprawdzić skryptem.
21 z nich należy do Level 1, a jedno (5.1.8) do Level 2.
Wybrałem tylko zalecenia, które nie wymagają wcześniejszego wdrożenia innych zaleceń z benchmarku, żeby każde dało się wdrożyć i sprawdzić samodzielnie.

Trudność w skali: 1 – łatwe, 2 – średnie, 3 – trudne, 5 – bardzo trudne.

| Nr CIS | Zalecenie | Kategoria | Profil | Trudność | Zaliczone |
|---|---|---|---|---|---|
| 1.5.4 | Brak zrzutów pamięci programów z podwyższonymi uprawnieniami (fs.suid_dumpable) | Jądro systemu | L1 | 1 | X |
| 1.6.2 | Baner /etc/issue bez informacji o systemie | Banery logowania | L1 | 1 | X |
| 2.3.1.1 | Działa tylko jedna usługa synchronizacji czasu | Usługi systemowe | L1 | 1 | X |
| 3.3.1.4 | Serwer nie wysyła przekierowań ICMP (send_redirects) | Bezpieczeństwo sieci | L1 | 1 | X |
| 3.3.1.8 | Ignorowanie przekierowań ICMP | Bezpieczeństwo sieci | L1 | 1 | X |
| 3.3.1.12 | Odrzucanie pakietów ze sfałszowanym adresem źródłowym (rp_filter) | Bezpieczeństwo sieci | L1 | 1 | X |
| 3.3.1.16 | Logowanie podejrzanych pakietów (martians) | Bezpieczeństwo sieci | L1 | 1 | X |
| 3.3.1.18 | Włączone TCP SYN cookies | Bezpieczeństwo sieci | L1 | 1 | X |
| 4.1.2 | Usługa ufw jest włączona i aktywna | Firewall | L1 | 2 | ✓ |
| 4.1.3 | Domyślne blokowanie ruchu przychodzącego w ufw | Firewall | L1 | 2 | ✓ |
| 5.1.4 | Ograniczenie dostępu SSH do wybranych użytkowników lub grup | SSH | L1 | 2 | ✓ |
| 5.1.7 | Rozłączanie niereagujących (martwych) połączeń SSH | SSH | L1 | 1 | ✓ |
| 5.1.8 | Wyłączenie przekierowań i tuneli w SSH (DisableForwarding) | SSH | L2 | 1 | X |
| 5.1.13 | Limit czasu na zalogowanie się przez SSH (LoginGraceTime) | SSH | L1 | 1 | X |
| 5.1.16 | Limit prób uwierzytelnienia w SSH (MaxAuthTries) | SSH | L1 | 1 | ✓ |
| 5.1.17 | Limit równoczesnych nieuwierzytelnionych połączeń SSH (MaxStartups) | SSH | L1 | 1 | X |
| 5.1.20 | Zakaz logowania na konto root przez SSH | SSH | L1 | 1 | ✓ |
| 5.2.3 | Osobny plik logu dla sudo | Uprawnienia | L1 | 1 | X |
| 5.2.7 | Ograniczenie dostępu do polecenia su | Uprawnienia | L1 | 2 | X |
| 5.4.1.1 | Maksymalny okres ważności hasła | Polityka haseł | L1 | 2 | X |
| 5.4.3.2 | Automatyczne wylogowanie nieaktywnej powłoki | Konta i uwierzytelnianie | L1 | 1 | X |
| 6.3.1 | Zainstalowany AIDE do kontroli integralności plików | Audyt i logowanie | L1 | 3 | X |

Łącznie: 22 zalecenia, 29 punktów trudności.