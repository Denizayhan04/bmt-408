# BMT-408 Proje Kanıt Dosyası

**Ad Soyad:** Veli Deniz Ayhan
**Öğrenci No:** 23181616013
**E-posta:** vdeniz.ayhan@gazi.edu.tr

---

## 1. Docker Compose PS Çıktısı

CONTAINER ID   IMAGE                COMMAND             CREATED        STATUS        PORTS                                 NAMES
c1fce2decc6c   adminer              "entrypoint.sh..."  1 min ago      Up 1 min      127.0.0.1:8080->8080/tcp              proje-adminer-1
1e8facc05418   postgres:15-alpine   "sh -c 'while..."   1 min ago      Up 1 min      5432/tcp                              proje-backup-1
6621c7100563   nginx:alpine         "/docker-entry..."   6 days ago     Up 6 days     0.0.0.0:80->80/tcp, [::]:80->80/tcp   proje-nginx-1
1cf10091c74c   proje-api            "uvicorn main..."    6 days ago     Up 6 days                                           proje-api-1
86da82b0a96b   postgres:15-alpine   "docker-entry..."    6 days ago     Up 6 days     5432/tcp                              proje-db-1

---

## 2. Açık Portlar (ss -tulpn)

tcp   LISTEN   0.0.0.0:22    -> sshd
tcp   LISTEN   0.0.0.0:80    -> docker-proxy (nginx)
tcp   LISTEN   [::]:22       -> sshd
tcp   LISTEN   [::]:80       -> docker-proxy (nginx)
tcp   LISTEN   127.0.0.1:8080 -> adminer (sadece localhost)

DB portları (5432/3306) dışarıya kapalıdır.

---

## 3. Güvenlik Duvarı (nft list ruleset)

table inet filter {
    chain input {
        type filter hook input priority filter; policy drop;
        iif "lo" accept
        ct state established,related accept
        tcp dport 22 accept
        tcp dport 80 accept
        tcp dport 443 accept
    }
    chain forward { policy accept; }
    chain output  { policy accept; }
}

INPUT policy DROP — sadece 22, 80, 443 açık.

---

## 4. Zamanlanmış Görev (crontab -l)

0 4 * * * /home/gazi/proje/backup/backup.sh

Her gün saat 04:00 Europe/Istanbul zamanında otomatik PostgreSQL yedeği alınmaktadır.

---

## 5. Yedek Dosyaları

backup/ klasöründeki .sql.gz dosyaları (7 günlük rotasyon):

db_backup_2026-04-20.sql.gz
db_backup_2026-04-21.sql.gz
db_backup_2026-04-22.sql.gz
db_backup_2026-04-23.sql.gz
db_backup_2026-04-24.sql.gz
db_backup_2026-04-25.sql.gz
db_backup_2026-04-26.sql.gz

---

## 6. Restore Testi

Komut:
  docker exec -i proje-db-1 psql -U user -d projedb -c "DROP TABLE IF EXISTS items CASCADE;"
  gunzip -c backup/db_backup_2026-04-20.sql.gz | docker exec -i proje-db-1 psql -U user -d projedb

Çıktı (restore_output.txt):
  DROP TABLE
  CREATE TABLE
  ALTER TABLE
  CREATE SEQUENCE
  ALTER TABLE
  CREATE INDEX
  CREATE INDEX

Hata yok. Restore başarılı.

---

## 7. Ekran Görüntüleri (Screenshots)

Aşağıdaki görseller klasörde mevcuttur:

- AWS Security Group kuralları (inbound: 22 sadece kendi IP, 80 herkese, 5432 kapalı)
- EC2 instance Running durumu
- FastAPI /docs Swagger UI
- Tarayıcıdan http://[SUNUCU_IP] bağlantısı
- SFTP / git pull deploy gösterimi
