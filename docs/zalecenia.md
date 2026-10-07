# Wybrane zalecenia

CIS Ubuntu Linux 24.04 LTS Benchmark v2.0.0, profil Server.

20 zaleceń z różnych obszarów. 
Wszystkie mają status Automated, czyli da się je sprawdzić skryptem. 
17 z nich należy do Level 1, a 3 zalecenia dotyczące auditd do Level 2.

Trudność w skali: 1 – łatwe, 2 – średnie, 3 – trudne, 5 – bardzo trudne.

| Nr CIS | Zalecenie | Kategoria | Profil | Trudność | Zaliczone |
|---|---|---|---|---|---|
| 2.3.1.1 | Działa tylko jedna usługa synchronizacji czasu | Usługi systemowe | L1 | 1 | X |
| 3.3.1.8 | Ignorowanie przekierowań ICMP | Bezpieczeństwo sieci | L1 | 1 | X |
| 3.3.1.16 | Logowanie podejrzanych pakietów (martians) | Bezpieczeństwo sieci | L1 | 1 | X |
| 3.3.1.18 | Włączone TCP SYN cookies | Bezpieczeństwo sieci | L1 | 1 | X |
| 4.1.2 | Usługa ufw jest włączona i aktywna | Firewall | L1 | 2 | X |
| 4.1.3 | Domyślne blokowanie ruchu przychodzącego w ufw | Firewall | L1 | 2 | X |
| 5.1.4 | Ograniczenie dostępu SSH do wybranych użytkowników lub grup | SSH | L1 | 2 | X |
| 5.1.7 | Rozłączanie nieaktywnych sesji SSH | SSH | L1 | 1 | X |
| 5.1.16 | Limit prób uwierzytelnienia w SSH (MaxAuthTries) | SSH | L1 | 1 | X |
| 5.1.20 | Zakaz logowania na konto root przez SSH | SSH | L1 | 1 | ✓ |
| 5.2.3 | Osobny plik logu dla sudo | Uprawnienia | L1 | 1 | X |
| 5.2.7 | Ograniczenie dostępu do polecenia su | Uprawnienia | L1 | 2 | X |
| 5.3.3.1.1 | Blokada konta po nieudanych próbach logowania | Konta i uwierzytelnianie | L1 | 3 | X |
| 5.3.3.2.2 | Minimalna długość hasła | Polityka haseł | L1 | 2 | X |
| 5.3.3.3.1 | Pamiętanie poprzednich haseł | Polityka haseł | L1 | 2 | X |
| 5.4.1.1 | Maksymalny okres ważności hasła | Polityka haseł | L1 | 2 | X |
| 5.4.3.2 | Automatyczne wylogowanie nieaktywnej powłoki | Konta i uwierzytelnianie | L1 | 1 | X |
| 6.2.1.2 | Usługa auditd jest włączona i aktywna | Audyt i logowanie | L2 | 2 | X |
| 6.2.3.13 | Rejestrowanie zmian w /etc/shadow i /etc/gshadow | Audyt i logowanie | L2 | 3 | X |
| 6.3.1 | Zainstalowany AIDE do kontroli integralności plików | Audyt i logowanie | L1 | 3 | X |

Łącznie: 20 zaleceń, 34 punkty trudności.
