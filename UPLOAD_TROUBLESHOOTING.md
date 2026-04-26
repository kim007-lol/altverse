# 🔧 Upload Troubleshooting Guide

## ❌ Error: "Gagal upload halaman, periksa koneksi internet"

### Kemungkinan Penyebab:

1. **CORS belum dikonfigurasi di R2** ⚠️ (PALING UMUM)
2. Public access belum diaktifkan di R2
3. Presigned URL generation gagal
4. Network connectivity issue
5. R2 credentials tidak valid

---

## 🔍 Diagnosis Step-by-Step

### Step 1: Test R2 Connection

```bash
cd backend
php test-r2-connection.php
```

**Expected Output**:

```
✅ S3 Client created successfully
✅ Bucket 'aureader' exists
✅ Presigned URL generated successfully
✅ File uploaded successfully
✅ File is publicly accessible (HTTP 200)
```

**If you see**:

- ❌ `Cannot list buckets: Access Denied` - Normal, R2 doesn't allow ListBuckets
- ✅ `Bucket exists` - Good!
- ✅ `Presigned URL generated` - Good!
- ⚠️ `File returned HTTP 0` or `HTTP 403` - **CORS NOT CONFIGURED**

### Step 2: Check CORS Configuration

**CRITICAL**: R2 bucket MUST have CORS configured!

1. Login to Cloudflare Dashboard: https://dash.cloudflare.com
2. Go to R2 → Select "aureader" bucket
3. Click "Settings" tab
4. Scroll to "CORS Policy"
5. Add this configuration:

```json
[
  {
    "AllowedOrigins": ["*"],
    "AllowedMethods": ["GET", "PUT", "POST", "DELETE", "HEAD"],
    "AllowedHeaders": ["*"],
    "ExposeHeaders": ["ETag", "Content-Length"],
    "MaxAgeSeconds": 3600
  }
]
```

6. Click "Save"
7. Wait 1-2 minutes for propagation

### Step 3: Enable Public Access

1. In R2 bucket settings
2. Find "Public Access" section
3. Enable "Allow Public Access"
4. Copy the public URL (e.g., `https://pub-xxxxx.r2.dev`)
5. Update `backend/.env`:
   ```
   AWS_URL=https://pub-xxxxx.r2.dev
   ```

### Step 4: Test Upload from Flutter

1. Start backend: `cd backend && php artisan serve`
2. Start frontend: `cd frontend && flutter run -d chrome`
3. Login as Author
4. Create/edit episode
5. Try to upload a page
6. Check browser console (F12) for errors

---

## 🐛 Common Errors & Solutions

### Error 1: CORS Error in Browser Console

```
Access to XMLHttpRequest at 'https://...r2.cloudflarestorage.com/...'
from origin 'http://localhost' has been blocked by CORS policy
```

**Cause**: CORS not configured in R2

**Solution**: Follow Step 2 above to configure CORS

---

### Error 2: 403 Forbidden

```
❌ Failed to upload to R2: Request failed with status code 403
```

**Possible Causes**:

- R2 credentials invalid
- Presigned URL expired (> 5 minutes)
- Bucket permissions issue

**Solutions**:

1. Verify credentials in `.env`:
   ```bash
   cd backend
   php artisan tinker
   >>> config('filesystems.disks.s3.key')
   >>> config('filesystems.disks.s3.secret')
   ```
2. Try uploading again (new presigned URL)
3. Check R2 bucket permissions in Cloudflare

---

### Error 3: Network Error

```
❌ Failed to get signed URL: Network error
```

**Cause**: Backend not running or not accessible

**Solution**:

```bash
# Check if backend is running
curl http://localhost:8000/api/health

# If not running, start it
cd backend
php artisan serve
```

---

### Error 4: Validation Error

```
❌ Failed to get signed URL: The type field must be one of: image/jpeg, image/png...
```

**Cause**: File type not supported

**Solution**: Only upload:

- Images: JPEG, PNG, WebP, GIF
- Audio: MP3

---

### Error 5: File Too Large

```
❌ File terlalu besar. Maksimal 10MB.
```

**Cause**: Audio file > 10MB

**Solution**:

- Compress MP3 file
- Use lower bitrate (128kbps recommended)
- Use online tools like https://www.mp3smaller.com/

---

## 🔧 Quick Fixes

### Fix 1: Use Local Storage (Development Only)

If R2 is not configured yet, you can use local storage temporarily:

1. Update `backend/.env`:

   ```
   FILESYSTEM_DISK=public
   ```

2. Create storage link:

   ```bash
   cd backend
   php artisan storage:link
   ```

3. Restart backend

**Note**: Files will be stored in `backend/storage/app/public/` instead of R2

---

### Fix 2: Clear Cache

Sometimes cached configuration causes issues:

```bash
cd backend
php artisan config:clear
php artisan cache:clear
php artisan route:clear
```

---

### Fix 3: Check Logs

Backend logs can provide more details:

```bash
cd backend
tail -f storage/logs/laravel.log
```

Frontend logs (browser console):

- Press F12
- Go to Console tab
- Look for red errors

---

## ✅ Verification Checklist

Before reporting issues, verify:

- [ ] Backend is running (`php artisan serve`)
- [ ] Frontend is running (`flutter run`)
- [ ] R2 credentials in `.env` are correct
- [ ] CORS configured in R2 bucket
- [ ] Public access enabled on R2 bucket
- [ ] Test script passes: `php test-r2-connection.php`
- [ ] Browser console shows no CORS errors
- [ ] Network tab shows successful requests

---

## 📊 Debug Information to Collect

If you still have issues, collect this information:

1. **Backend Test Output**:

   ```bash
   php backend/test-r2-connection.php > r2-test.txt
   ```

2. **Browser Console Errors**:
   - Press F12 → Console tab
   - Copy all red errors

3. **Network Tab**:
   - Press F12 → Network tab
   - Try upload
   - Right-click failed request → Copy → Copy as cURL

4. **Backend Logs**:

   ```bash
   tail -n 50 backend/storage/logs/laravel.log
   ```

5. **Environment**:
   ```bash
   cd backend
   php artisan about
   ```

---

## 🚀 Production Checklist

Before deploying to production:

- [ ] R2 CORS configured
- [ ] R2 public access enabled
- [ ] Custom domain configured (optional)
- [ ] SSL certificate valid
- [ ] File upload tested
- [ ] File access tested
- [ ] Audio upload tested
- [ ] Large file upload tested (near limits)
- [ ] Error handling tested
- [ ] Monitoring configured

---

## 📞 Still Having Issues?

1. Read `R2_CORS_SETUP.md` for detailed CORS setup
2. Run `php backend/test-r2-connection.php` and share output
3. Check browser console for CORS errors
4. Verify `.env` configuration matches R2 dashboard

---

**Last Updated**: 2026-04-26
**Status**: Troubleshooting Guide
