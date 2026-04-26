# 🔧 R2 CORS Configuration Guide

## ⚠️ PENTING: Konfigurasi CORS untuk R2

Untuk mengaktifkan upload langsung dari Flutter ke R2, Anda HARUS mengkonfigurasi CORS di Cloudflare R2 bucket.

---

## 📋 Langkah-langkah Setup CORS

### 1. Login ke Cloudflare Dashboard

- Buka https://dash.cloudflare.com
- Pilih account Anda
- Klik "R2" di sidebar

### 2. Pilih Bucket

- Klik bucket "aureader" (atau nama bucket Anda)
- Klik tab "Settings"

### 3. Scroll ke "CORS Policy"

- Klik "Add CORS Policy" atau "Edit"

### 4. Masukkan Konfigurasi CORS

```json
[
  {
    "AllowedOrigins": ["*"],
    "AllowedMethods": ["GET", "PUT", "POST", "DELETE", "HEAD"],
    "AllowedHeaders": ["*"],
    "ExposeHeaders": ["ETag", "Content-Length", "Content-Type"],
    "MaxAgeSeconds": 3600
  }
]
```

### 5. Save Configuration

- Klik "Save" atau "Update"
- Tunggu beberapa detik untuk propagasi

---

## 🔐 Konfigurasi Public Access

### Option 1: Bucket-Level Public Access (Recommended)

Di Cloudflare R2 Dashboard:

1. Pilih bucket "aureader"
2. Klik tab "Settings"
3. Scroll ke "Public Access"
4. Enable "Allow Public Access"
5. Copy Public URL yang diberikan (contoh: `https://pub-xxxxx.r2.dev`)
6. Update `.env`:
   ```
   AWS_URL=https://pub-xxxxx.r2.dev
   ```

### Option 2: Custom Domain (Production)

1. Di R2 bucket settings, klik "Connect Domain"
2. Masukkan custom domain (contoh: `cdn.aureader.com`)
3. Ikuti instruksi untuk setup DNS
4. Update `.env`:
   ```
   AWS_URL=https://cdn.aureader.com
   ```

---

## 🧪 Test CORS Configuration

### Test 1: Manual CURL Test

```bash
# Test OPTIONS request (CORS preflight)
curl -X OPTIONS \
  -H "Origin: http://localhost:3000" \
  -H "Access-Control-Request-Method: PUT" \
  -H "Access-Control-Request-Headers: Content-Type" \
  -v \
  https://pub-f5ef4dcb047c458ba79723646fa83618.r2.dev/test.txt

# Expected response headers:
# Access-Control-Allow-Origin: *
# Access-Control-Allow-Methods: GET, PUT, POST, DELETE, HEAD
# Access-Control-Allow-Headers: *
```

### Test 2: Upload Test File

```bash
# Create test file
echo "Test upload" > test.txt

# Upload using presigned URL (get from backend)
curl -X PUT \
  -H "Content-Type: text/plain" \
  --data-binary @test.txt \
  "YOUR_PRESIGNED_URL_HERE"

# Expected: HTTP 200 OK
```

### Test 3: Check Public Access

```bash
# Try to access uploaded file
curl -I https://pub-f5ef4dcb047c458ba79723646fa83618.r2.dev/test/test.txt

# Expected: HTTP 200 OK
# If HTTP 403: Public access not enabled
# If HTTP 404: File not found
```

---

## 🐛 Troubleshooting

### Error: "CORS policy: No 'Access-Control-Allow-Origin' header"

**Cause**: CORS not configured in R2 bucket

**Solution**:

1. Check CORS configuration in R2 dashboard
2. Make sure `AllowedOrigins` includes `*` or your domain
3. Wait 1-2 minutes for propagation

### Error: "403 Forbidden" when accessing file

**Cause**: Public access not enabled

**Solution**:

1. Enable "Allow Public Access" in R2 bucket settings
2. OR set ACL to `public-read` when uploading
3. Verify public URL is correct in `.env`

### Error: "Network error" or "Failed to upload to R2"

**Cause**:

- CORS not configured
- Wrong endpoint URL
- Network connectivity issue

**Solution**:

1. Run test script: `php backend/test-r2-connection.php`
2. Check console logs for detailed error
3. Verify `.env` configuration:
   ```
   AWS_ENDPOINT=https://YOUR_ACCOUNT_ID.r2.cloudflarestorage.com
   AWS_URL=https://pub-xxxxx.r2.dev
   AWS_BUCKET=aureader
   ```

### Error: "Presigned URL expired"

**Cause**: Upload took longer than 5 minutes

**Solution**:

- Retry upload (new presigned URL will be generated)
- Check internet connection speed
- Consider increasing timeout in PageController.php

---

## ✅ Verification Checklist

After configuring CORS, verify:

- [ ] CORS policy added to R2 bucket
- [ ] Public access enabled on bucket
- [ ] Public URL configured in `.env` (AWS_URL)
- [ ] Test script passes: `php backend/test-r2-connection.php`
- [ ] Can upload image from Flutter app
- [ ] Can access uploaded image via public URL
- [ ] Can upload MP3 audio file
- [ ] Can access uploaded audio via public URL

---

## 📝 Current Configuration

Based on your `.env`:

```
AWS_ACCESS_KEY_ID=2d117a29a03a4ebad0130e8166afa3b8
AWS_SECRET_ACCESS_KEY=e705e0958483a80b6eb2a75c6354b61ba81bc1311f1e1f53812e15f72977ca34
AWS_DEFAULT_REGION=auto
AWS_BUCKET=aureader
AWS_URL=https://pub-f5ef4dcb047c458ba79723646fa83618.r2.dev
AWS_ENDPOINT=https://ecab3e93f1be57a31e47248ed4aa4a14.r2.cloudflarestorage.com
AWS_USE_PATH_STYLE_ENDPOINT=true
```

✅ Configuration looks correct!

---

## 🚀 Next Steps

1. **Configure CORS** in Cloudflare R2 Dashboard (MOST IMPORTANT)
2. **Enable Public Access** on bucket
3. **Test upload** from Flutter app
4. **Verify** files are accessible via public URL

---

## 📞 Support

If you still have issues after following this guide:

1. Run test script: `php backend/test-r2-connection.php`
2. Check browser console for CORS errors
3. Check Flutter logs for detailed error messages
4. Verify R2 bucket settings in Cloudflare dashboard

---

**Last Updated**: 2026-04-26
**Status**: ⚠️ CORS Configuration Required
