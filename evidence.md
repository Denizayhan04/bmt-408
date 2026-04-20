# BMT-408 Proje Kanıt Dosyası

## 1. Docker Compose PS Çıktısı
```bash
NAME            IMAGE                COMMAND                  SERVICE   CREATED         STATUS         PORTS
proje-api-1     proje-api            "uvicorn main:app --…"   api       3 minutes ago   Up 3 minutes   
proje-db-1      postgres:15-alpine   "docker-entrypoint.s…"   db        3 minutes ago   Up 3 minutes   5432/tcp
proje-nginx-1   nginx:alpine         "/docker-entrypoint.…"   nginx     3 minutes ago   Up 3 minutes   0.0.0.0:80->80/tcp, [::]:80->80/tcp
```

## 2. Açık Portlar (ss -tulpn)
```bash
Netid State  Recv-Q Send-Q     Local Address:Port  Peer Address:PortProcess                                                 
udp   UNCONN 0      0             127.0.0.54:53         0.0.0.0:*    users:(("systemd-resolve",pid=4434,fd=16))             
udp   UNCONN 0      0          127.0.0.53%lo:53         0.0.0.0:*    users:(("systemd-resolve",pid=4434,fd=14))             
udp   UNCONN 0      0      172.31.34.13%ens5:68         0.0.0.0:*    users:(("systemd-network",pid=4163,fd=22))             
udp   UNCONN 0      0              127.0.0.1:323        0.0.0.0:*    users:(("chronyd",pid=789,fd=5))                       
udp   UNCONN 0      0                  [::1]:323           [::]:*    users:(("chronyd",pid=789,fd=6))                       
tcp   LISTEN 0      4096           127.0.0.1:44369      0.0.0.0:*    users:(("containerd",pid=13856,fd=15))                 
tcp   LISTEN 0      4096             0.0.0.0:80         0.0.0.0:*    users:(("docker-proxy",pid=24358,fd=7))                
tcp   LISTEN 0      4096       127.0.0.53%lo:53         0.0.0.0:*    users:(("systemd-resolve",pid=4434,fd=15))             
tcp   LISTEN 0      4096             0.0.0.0:22         0.0.0.0:*    users:(("sshd",pid=13014,fd=3),("systemd",pid=1,fd=82))
tcp   LISTEN 0      4096          127.0.0.54:53         0.0.0.0:*    users:(("systemd-resolve",pid=4434,fd=17))             
tcp   LISTEN 0      4096                [::]:80            [::]:*    users:(("docker-proxy",pid=24365,fd=7))                
tcp   LISTEN 0      4096                [::]:22            [::]:*    users:(("sshd",pid=13014,fd=4),("systemd",pid=1,fd=85))
tcp   LISTEN 0      4096                   *:9090             *:*    users:(("systemd",pid=1,fd=74))                        
```

## 3. Güvenlik Duvarı Kuralları (nft list ruleset)
```bash
table inet filter {
	chain input {
		type filter hook input priority filter; policy drop;
		iif "lo" accept
		ct state established,related accept
		tcp dport 22 accept
		tcp dport 80 accept
		tcp dport 443 accept
		iif "lo" accept
		ct state established,related accept
		tcp dport 22 accept
		tcp dport 80 accept
		tcp dport 443 accept
	}

	chain forward {
		type filter hook forward priority filter; policy accept;
	}

	chain output {
		type filter hook output priority filter; policy accept;
	}
}
table ip raw {
	chain PREROUTING {
		type filter hook prerouting priority raw; policy accept;
		ip daddr 172.18.0.2 iifname != "br-fb39843c0bb5" counter packets 0 bytes 0 drop
		ip daddr 172.18.0.4 iifname != "br-fb39843c0bb5" counter packets 0 bytes 0 drop
		ip daddr 172.18.0.3 iifname != "br-fb39843c0bb5" counter packets 0 bytes 0 drop
	}
}
table ip nat {
	chain DOCKER {
		iifname != "br-fb39843c0bb5" tcp dport 80 counter packets 2 bytes 128 dnat to 172.18.0.4:80
	}

	chain PREROUTING {
		type nat hook prerouting priority dstnat; policy accept;
		fib daddr type local counter packets 3 bytes 188 jump DOCKER
	}

	chain OUTPUT {
		type nat hook output priority dstnat; policy accept;
		ip daddr != 127.0.0.0/8 fib daddr type local counter packets 0 bytes 0 jump DOCKER
	}

	chain POSTROUTING {
		type nat hook postrouting priority srcnat; policy accept;
		ip saddr 172.18.0.0/16 oifname != "br-fb39843c0bb5" counter packets 0 bytes 0 masquerade
		ip saddr 172.17.0.0/16 oifname != "docker0" counter packets 8 bytes 484 masquerade
	}
}
table ip filter {
	chain DOCKER {
		ip daddr 172.18.0.4 iifname != "br-fb39843c0bb5" oifname "br-fb39843c0bb5" tcp dport 80 counter packets 2 bytes 128 accept
		iifname != "docker0" oifname "docker0" counter packets 0 bytes 0 drop
		iifname != "br-fb39843c0bb5" oifname "br-fb39843c0bb5" counter packets 0 bytes 0 drop
	}

	chain DOCKER-FORWARD {
		counter packets 7352 bytes 92197313 jump DOCKER-CT
		counter packets 2625 bytes 180724 jump DOCKER-INTERNAL
		counter packets 2625 bytes 180724 jump DOCKER-BRIDGE
		iifname "docker0" counter packets 2611 bytes 175954 accept
		iifname "br-fb39843c0bb5" counter packets 12 bytes 4642 accept
	}

	chain DOCKER-BRIDGE {
		oifname "docker0" counter packets 0 bytes 0 jump DOCKER
		oifname "br-fb39843c0bb5" counter packets 2 bytes 128 jump DOCKER
	}

	chain DOCKER-CT {
		oifname "docker0" ct state related,established counter packets 4713 bytes 92014585 accept
		oifname "br-fb39843c0bb5" ct state related,established counter packets 14 bytes 2004 accept
	}

	chain DOCKER-INTERNAL {
	}

	chain FORWARD {
		type filter hook forward priority filter; policy accept;
		counter packets 7352 bytes 92197313 jump DOCKER-USER
		counter packets 7352 bytes 92197313 jump DOCKER-FORWARD
	}

	chain DOCKER-USER {
	}
}
table ip6 nat {
	chain DOCKER {
	}

	chain PREROUTING {
		type nat hook prerouting priority dstnat; policy accept;
		fib daddr type local counter packets 0 bytes 0 jump DOCKER
	}

	chain OUTPUT {
		type nat hook output priority dstnat; policy accept;
		ip6 daddr != ::1 fib daddr type local counter packets 0 bytes 0 jump DOCKER
	}
}
table ip6 filter {
	chain DOCKER {
	}

	chain DOCKER-FORWARD {
		counter packets 0 bytes 0 jump DOCKER-CT
		counter packets 0 bytes 0 jump DOCKER-INTERNAL
		counter packets 0 bytes 0 jump DOCKER-BRIDGE
	}

	chain DOCKER-BRIDGE {
	}

	chain DOCKER-CT {
	}

	chain DOCKER-INTERNAL {
	}

	chain FORWARD {
		type filter hook forward priority filter; policy accept;
		counter packets 0 bytes 0 jump DOCKER-USER
		counter packets 0 bytes 0 jump DOCKER-FORWARD
	}

	chain DOCKER-USER {
	}
}
```

## 4. Yedek Dosyaları ve Restore Kanıtı
### Alınan Yedek Dosyası:
```bash
-rw-rw-r-- 1 gazi gazi 862 Apr 20 11:10 /home/gazi/proje/backup/db_backup_2026-04-20.sql.gz
```
### Restore Komutu ve Çıktısı:
```bash
gunzip -c /home/gazi/proje/backup/db_backup_2026-04-20.sql.gz | docker exec -i proje-db-1 psql -U user -d projedb
SET
SET
SET
SET
SET
 set_config 
------------
 
(1 row)

SET
SET
SET
SET
SET
SET
ERROR:  relation "items" already exists
ALTER TABLE
ERROR:  relation "items_id_seq" already exists
ALTER TABLE
ALTER SEQUENCE
ALTER TABLE
COPY 0
 setval 
--------
      1
(1 row)

ERROR:  multiple primary keys for table "items" are not allowed
ERROR:  relation "ix_items_id" already exists
ERROR:  relation "ix_items_title" already exists
```
