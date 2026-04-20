# BMT-408 Dersi Dönem Projesi

**Ad Soyad:** Veli Deniz Ayhan
**Öğrenci No:** 23181616013
**E-posta:** vdeniz.ayhan@gazi.edu.tr

## Kurulum Adımları
1. Sunucu üzerinde gerekli paketler (Docker, nftables vb.) kuruldu.
2. Proje dizininde `docker compose up -d` komutu çalıştırılarak Nginx, FastAPI ve PostgreSQL servisleri ayağa kaldırıldı.
3. FastAPI uygulaması, PostgreSQL'e bağlanarak tabloları otomatik oluşturdu.

## Test Adımları
1. Tarayıcı üzerinden `http://[SUNUCU_IP]/docs` adresine gidilerek Swagger arayüzüne erişildi.
2. `POST /items` endpoint'i üzerinden veritabanına yeni bir kayıt eklendi (Create).
3. `GET /items` endpoint'i üzerinden eklenen kayıt başarıyla listelendi (Read).
4. `backup.sh` betiği ile PostgreSQL yedeği alındı ve `.sql.gz` olarak arşivlendi. Restore testi başarılı oldu.

## Endpoint Listesi
* `GET /health` : Sistemin ayakta olup olmadığını kontrol eder.
* `POST /items` : Veritabanına yeni bir kayıt ekler.
* `GET /items` : Veritabanındaki tüm kayıtları listeler.
* `GET /items/{id}` : Belirtilen ID'ye sahip kaydı getirir.
* `DELETE /items/{id}` : Belirtilen ID'ye sahip kaydı siler.
