# Error Handling Documentation

## Overview
Standardized API error response system for AU Reader V2 with consistent format and Indonesian error messages.

## ApiResponse Class

Location: `backend/app/Http/Responses/ApiResponse.php`

### Success Responses

#### `success()`
```php
ApiResponse::success($data, 'Success message', 200);
```

**Response Format**:
```json
{
  "success": true,
  "message": "Success message",
  "data": {...}
}
```

#### `created()`
```php
ApiResponse::created($data, 'Resource berhasil dibuat');
```

**Response Format** (201):
```json
{
  "success": true,
  "message": "Resource berhasil dibuat",
  "data": {...}
}
```

#### `paginated()`
```php
ApiResponse::paginated($paginator, 'Success');
```

**Response Format**:
```json
{
  "success": true,
  "message": "Success",
  "data": [...],
  "pagination": {
    "current_page": 1,
    "last_page": 5,
    "per_page": 20,
    "total": 100,
    "from": 1,
    "to": 20
  }
}
```

### Error Responses

#### `error()`
```php
ApiResponse::error('Error message', 400, $errors, $data);
```

**Response Format**:
```json
{
  "success": false,
  "message": "Error message",
  "errors": {...},
  "data": {...}
}
```

#### `validationError()`
```php
ApiResponse::validationError($errors, 'Validasi gagal');
```

**Response Format** (422):
```json
{
  "success": false,
  "message": "Validasi gagal",
  "errors": {
    "field_name": ["Error message 1", "Error message 2"]
  }
}
```

#### `notFound()`
```php
ApiResponse::notFound('Resource tidak ditemukan');
```

**Response Format** (404):
```json
{
  "success": false,
  "message": "Resource tidak ditemukan"
}
```

#### `unauthorized()`
```php
ApiResponse::unauthorized('Unauthorized');
```

**Response Format** (401):
```json
{
  "success": false,
  "message": "Unauthorized"
}
```

#### `forbidden()`
```php
ApiResponse::forbidden('Forbidden');
```

**Response Format** (403):
```json
{
  "success": false,
  "message": "Forbidden"
}
```

#### `serverError()`
```php
ApiResponse::serverError('Internal server error', $data);
```

**Response Format** (500):
```json
{
  "success": false,
  "message": "Internal server error",
  "data": {...}
}
```

## Helper Functions

Location: `backend/app/Helpers/helpers.php`

### Available Helpers

```php
// Success response
api_success($data, 'Success message', 200);

// Error response
api_error('Error message', 400, $errors, $data);

// Validation error
api_validation_error($errors, 'Validasi gagal');

// Not found
api_not_found('Resource tidak ditemukan');

// Created
api_created($data, 'Resource berhasil dibuat');

// Paginated
api_paginated($paginator, 'Success');
```

## Global Exception Handler

Location: `backend/bootstrap/app.php`

### Handled Exceptions

1. **ValidationException** (422)
   - Automatically formats validation errors
   - Returns Indonesian error messages

2. **ModelNotFoundException** (404)
   - Returns "Resource tidak ditemukan"

3. **AuthenticationException** (401)
   - Returns "Unauthenticated"

4. **AuthorizationException** (403)
   - Returns "Forbidden"

5. **HttpException** (varies)
   - Returns exception message with appropriate status code

6. **General Exceptions** (500)
   - Returns "Terjadi kesalahan pada server" in production
   - Shows detailed error in debug mode

## Usage Examples

### In Controllers

#### Using ApiResponse Class
```php
use App\Http\Responses\ApiResponse;

public function index()
{
    $data = Model::all();
    return ApiResponse::success($data, 'Data berhasil diambil');
}

public function store(Request $request)
{
    $model = Model::create($request->validated());
    return ApiResponse::created($model, 'Data berhasil dibuat');
}

public function show($id)
{
    $model = Model::find($id);
    
    if (!$model) {
        return ApiResponse::notFound('Data tidak ditemukan');
    }
    
    return ApiResponse::success($model);
}
```

#### Using Helper Functions
```php
public function index()
{
    $data = Model::paginate(20);
    return api_paginated($data, 'Data berhasil diambil');
}

public function store(Request $request)
{
    $model = Model::create($request->validated());
    return api_created($model, 'Data berhasil dibuat');
}

public function destroy($id)
{
    $model = Model::find($id);
    
    if (!$model) {
        return api_not_found('Data tidak ditemukan');
    }
    
    $model->delete();
    return api_success(null, 'Data berhasil dihapus');
}
```

### Custom Error Handling

```php
try {
    // Some operation
    $result = $this->service->process($data);
    return api_success($result, 'Operasi berhasil');
} catch (\Exception $e) {
    return api_error(
        'Operasi gagal: ' . $e->getMessage(),
        500
    );
}
```

## HTTP Status Codes

| Code | Meaning | Usage |
|------|---------|-------|
| 200 | OK | Successful GET, PUT, PATCH |
| 201 | Created | Successful POST |
| 204 | No Content | Successful DELETE |
| 400 | Bad Request | Invalid request |
| 401 | Unauthorized | Authentication required |
| 403 | Forbidden | Insufficient permissions |
| 404 | Not Found | Resource not found |
| 422 | Unprocessable Entity | Validation failed |
| 429 | Too Many Requests | Rate limit exceeded |
| 500 | Internal Server Error | Server error |

## Best Practices

1. **Always use ApiResponse or helpers** for consistent formatting
2. **Use Indonesian messages** for user-facing errors
3. **Include relevant data** in error responses when helpful
4. **Log errors** before returning error responses
5. **Don't expose sensitive information** in production errors
6. **Use appropriate HTTP status codes**
7. **Provide actionable error messages**

## Testing Error Responses

```bash
# Test validation error
curl -X POST http://localhost:8000/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"invalid"}'

# Expected response (422):
{
  "success": false,
  "message": "Validasi gagal",
  "errors": {
    "email": ["Format email tidak valid."],
    "password": ["Password wajib diisi."]
  }
}

# Test not found
curl http://localhost:8000/api/v1/reader/series/99999 \
  -H "Authorization: Bearer {token}"

# Expected response (404):
{
  "success": false,
  "message": "Resource tidak ditemukan"
}

# Test unauthorized
curl http://localhost:8000/api/v1/missions

# Expected response (401):
{
  "success": false,
  "message": "Unauthenticated"
}
```

## Migration Guide

### Before (Inconsistent)
```php
// Various formats used
return response()->json(['message' => 'Success'], 200);
return response()->json(['error' => 'Failed'], 400);
return response()->json($data);
```

### After (Standardized)
```php
// Consistent format
return api_success($data, 'Success');
return api_error('Failed', 400);
return api_created($data, 'Created');
```

---

**Last Updated**: 2026-04-24  
**Status**: ✅ Implemented
