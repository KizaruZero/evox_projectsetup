# DNS Setup Guide untuk codeverse.id

## 📋 DNS Records yang Harus Ditambahkan

Login ke domain registrar Anda (contoh: Namecheap, GoDaddy, Cloudflare, dll) dan tambahkan DNS A records berikut:

### A Records

| Type | Name/Host   | Value/Points To | TTL              |
| ---- | ----------- | --------------- | ---------------- |
| A    | evox        | 103.123.45.67   | 3600 (atau Auto) |
| A    | account-api | 103.123.45.67   | 3600 (atau Auto) |
| A    | api         | 103.123.45.67   | 3600 (atau Auto) |
| A    | vendor-api  | 103.123.45.67   | 3600 (atau Auto) |
| A    | invoice-api | 103.123.45.67   | 3600 (atau Auto) |

### Screenshots Format berbagai Registrar

#### Namecheap

```
Type: A Record
Host: evox
Value: 103.123.45.67
TTL: Auto
```

#### Cloudflare

```
Type: A
Name: evox
IPv4 address: 103.123.45.67
Proxy status: DNS only (gray cloud)
TTL: Auto
```

#### GoDaddy

```
Type: A
Name: evox
Value: 103.123.45.67
TTL: 1 Hour
```

---

## ⏱️ DNS Propagation

Setelah menambahkan DNS records:

**Waktu Propagation:** 5 menit - 48 jam (biasanya 5-30 menit)

### Check Propagation Status

**Metode 1: nslookup (Windows/Linux)**

```bash
nslookup evox.codeverse.id
nslookup account-api.codeverse.id
nslookup api.codeverse.id
nslookup vendor-api.codeverse.id
nslookup invoice-api.codeverse.id
```

**Expected Output:**

```
Server:  dns.google
Address:  8.8.8.8

Non-authoritative answer:
Name:    evox.codeverse.id
Address:  103.123.45.67
```

**Metode 2: dig (Linux/Mac)**

```bash
dig evox.codeverse.id
dig account-api.codeverse.id +short
```

**Metode 3: Online Tools**

- https://www.whatsmydns.net/
- https://dnschecker.org/
- https://mxtoolbox.com/SuperTool.aspx

Paste: `evox.codeverse.id` dan check apakah resolve ke `103.123.45.67`

---

## ✅ Verification Commands

Run these from your local computer:

```bash
# Check all subdomains
echo "Checking DNS..."
for subdomain in evox account-api api vendor-api invoice-api; do
    echo "Checking $subdomain.codeverse.id..."
    nslookup $subdomain.codeverse.id 8.8.8.8
    echo "---"
done
```

**All should return:** 103.123.45.67

---

## 🚨 Common Issues

### Issue 1: "Not resolving"

**Cause:** DNS belum propagasi  
**Fix:** Tunggu 5-30 menit, cek lagi

### Issue 2: "Resolving to wrong IP"

**Cause:** Typo di DNS record  
**Fix:** Double check IP address di registrar

### Issue 3: "Only some subdomains work"

**Cause:** Belum semua A records ditambahkan  
**Fix:** Pastikan semua 5 A records sudah ditambahkan

---

## 📝 Checklist

Sebelum lanjut deployment:

- [ ] Login ke domain registrar
- [ ] Tambahkan 5 A records
- [ ] Tunggu DNS propagation (5-30 menit)
- [ ] Verify dengan nslookup atau whatsmydns.net
- [ ] Semua subdomain resolve ke 103.123.45.67
- [ ] Lanjut ke deployment VPS

---

## 🔄 Next Steps

Setelah DNS ready, lanjut ke: **[CODEVERSE_DEPLOYMENT.md](CODEVERSE_DEPLOYMENT.md)** Phase 2: VPS Preparation
