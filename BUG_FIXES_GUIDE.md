# 🔧 Bug Fixes Guide - AU Reader V2

Panduan lengkap untuk memperbaiki bug yang ditemukan dalam audit.

---

## 🔴 Phase 1: Critical Fixes (PRIORITY)

### Fix 1: Add Dispose Methods to Controllers

#### Problem

Controllers tidak di-dispose, menyebabkan memory leak.

#### Files to Fix

1. `frontend/lib/features/reader/screens/search_screen.dart`
2. `frontend/lib/features/reader/screens/reading_screen.dart`
3. `frontend/lib/features/reader/screens/home_screen.dart`
4. `frontend/lib/features/author/screens/series_management_screen.dart`
5. `frontend/lib/features/author/screens/page_editor_screen.dart`
6. `frontend/lib/features/author/screens/create_series_screen.dart`
7. `frontend/lib/features/auth/screens/login_screen.dart`
8. `frontend/lib/features/auth/screens/register_screen.dart`
9. `frontend/lib/features/auth/screens/author_onboarding_screen.dart`

#### Solution Template

```dart
// Add this to each StatefulWidget that has controllers

@override
void dispose() {
  // Dispose all controllers
  _searchCtrl.dispose();
  _scrollCtrl.dispose();
  _pageController.dispose();
  _carouselTimer?.cancel(); // For timers

  super.dispose();
}
```

#### Example Fix for search_screen.dart

```dart
class _SearchScreenState extends State<SearchScreen> {
  final _searchCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  // ... existing code ...

  @override
  void dispose() {
    _searchCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }
}
```

---

### Fix 2: Add Null Safety Checks

#### Problem

Accessing map/list data without null checks dapat menyebabkan crashes.

#### Solution Pattern

```dart
// BAD ❌
final title = _data['title'];
final items = _data['items'];

// GOOD ✅
final title = _data['title'] as String? ?? 'Unknown';
final items = _data['items'] as List<dynamic>? ?? [];

// OR with explicit checks
if (_data['title'] != null) {
  final title = _data['title'] as String;
  // Use title safely
}
```

#### Common Patterns to Fix

```dart
// Pattern 1: Map access
Map<String, dynamic> _data = {};

// Fix:
final value = _data['key'] as String? ?? 'default';
final number = _data['count'] as int? ?? 0;
final list = _data['items'] as List<dynamic>? ?? [];

// Pattern 2: List access
List<dynamic> _items = [];

// Fix:
if (_items.isNotEmpty) {
  final first = _items[0];
}

// Pattern 3: Nested access
final author = series['author'];
final name = author?['name'] ?? 'Unknown';

// Better:
final name = (series['author'] as Map<String, dynamic>?)?['name'] as String? ?? 'Unknown';
```

---

## 🟡 Phase 2: Medium Fixes

### Fix 3: Implement Event Broadcasting

#### File

`backend/app/Http/Controllers/Api/V1/Author/EpisodeController.php`

#### Solution

```php
// Line 107 - Replace TODO with actual implementation

// Option 1: Implement the event
broadcast(new EpisodePublished($episode));

// Option 2: If not needed, remove the TODO comment
// (Remove the line entirely)
```

If implementing, ensure Event class exists:

```php
// app/Events/EpisodePublished.php
namespace App\Events;

use App\Models\Episode;
use Illuminate\Broadcasting\Channel;
use Illuminate\Broadcasting\InteractsWithSockets;
use Illuminate\Contracts\Broadcasting\ShouldBroadcast;
use Illuminate\Foundation\Events\Dispatchable;
use Illuminate\Queue\SerializesModels;

class EpisodePublished implements ShouldBroadcast
{
    use Dispatchable, InteractsWithSockets, SerializesModels;

    public function __construct(public Episode $episode)
    {
    }

    public function broadcastOn(): array
    {
        return [
            new Channel('episodes'),
        ];
    }
}
```

---

### Fix 4: Improve Error Handling in AuthProvider

#### File

`frontend/lib/core/services/auth_provider.dart`

#### Solution

```dart
import 'dart:io'; // Add this import
import 'dart:async'; // Add this import

// Replace generic catch blocks with specific error handling

try {
  // ... API call ...
} on SocketException {
  _errorMessage = 'Tidak dapat terhubung ke server. Periksa koneksi internet Anda.';
} on TimeoutException {
  _errorMessage = 'Koneksi timeout. Silakan coba lagi.';
} on FormatException {
  _errorMessage = 'Format response tidak valid.';
} catch (e) {
  _errorMessage = 'Terjadi kesalahan: ${e.toString()}';
  debugPrint('Auth error: $e');
} finally {
  _isLoading = false;
  notifyListeners();
}
```

---

### Fix 5: Add Validation in Report Dialog

#### File

`frontend/lib/features/shared/widgets/report_dialog.dart`

#### Solution

```dart
// Add validation before submitting

ElevatedButton(
  onPressed: () {
    // Add validation
    if (selectedReason == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pilih alasan laporan'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (reasonCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Deskripsi tidak boleh kosong'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Proceed with submission
    Navigator.pop(context, {
      'reason': selectedReason,
      'description': reasonCtrl.text.trim(),
    });
  },
  child: const Text('Kirim Laporan'),
)
```

---

### Fix 6: Fix Carousel Timer Disposal

#### File

`frontend/lib/features/reader/screens/home_screen.dart`

#### Solution

```dart
class _ReaderHomeScreenState extends State<ReaderHomeScreen> {
  final PageController _carouselController = PageController();
  Timer? _carouselTimer;

  @override
  void dispose() {
    _carouselTimer?.cancel(); // Cancel timer first
    _carouselController.dispose(); // Then dispose controller
    super.dispose();
  }

  void _startCarouselTimer() {
    _carouselTimer?.cancel(); // Cancel existing timer

    final featured = (_data['featured'] ?? []) as List;
    if (featured.length <= 1) return;

    _carouselTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted) {
        _carouselTimer?.cancel(); // Extra safety
        return;
      }

      final next = (_currentCarousel + 1) % featured.length;
      _carouselController.animateToPage(
        next,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    });
  }
}
```

---

### Fix 7: Improve Image Loading

#### Solution

Replace all `Image.network()` with `CachedNetworkImage`:

```dart
// Before ❌
Image.network(
  coverUrl,
  fit: BoxFit.cover,
  errorBuilder: (c, e, s) => Icon(Icons.image_not_supported_outlined),
)

// After ✅
CachedNetworkImage(
  imageUrl: coverUrl,
  fit: BoxFit.cover,
  placeholder: (context, url) => Container(
    color: theme.cardColor,
    child: Center(
      child: SizedBox(
        width: 24,
        height: 24,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(
            theme.primaryColor,
          ),
        ),
      ),
    ),
  ),
  errorWidget: (context, url, error) => Container(
    color: theme.cardColor,
    child: Center(
      child: Icon(
        Icons.broken_image_outlined,
        color: theme.textTheme.bodySmall?.color,
        size: 32,
      ),
    ),
  ),
)
```

---

### Fix 8: Refactor Raw SQL Queries

#### File

`backend/app/Http/Controllers/Api/V1/Author/AnalyticsController.php`

#### Solution

```php
// Before
->select(DB::raw('DATE(viewed_date) as date, COUNT(*) as views'))
->groupBy(DB::raw('DATE(viewed_date)'))
->orderBy(DB::raw('DATE(viewed_date)'))

// After (more secure and readable)
->selectRaw('DATE(viewed_date) as date, COUNT(*) as views')
->groupByRaw('DATE(viewed_date)')
->orderByRaw('DATE(viewed_date)')
```

---

## 🟢 Phase 3: Low Priority Fixes

### Fix 9: Add API Timeout

#### File

`frontend/lib/core/services/api_service.dart`

#### Solution

```dart
class ApiService {
  static const Duration _timeout = Duration(seconds: 30);

  static Future<ApiResponse> get(String endpoint, {Map<String, dynamic>? queryParams}) async {
    try {
      var uri = Uri.parse('$baseUrl$endpoint');
      if (queryParams != null && queryParams.isNotEmpty) {
        uri = uri.replace(queryParameters: queryParams.map((key, value) => MapEntry(key, value.toString())));
      }

      final response = await http.get(uri, headers: _headers)
          .timeout(_timeout); // Add timeout

      return _handleResponse(response);
    } on TimeoutException {
      return ApiResponse(
        success: false,
        message: 'Request timeout. Please try again.',
      );
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Network error: ${e.toString()}',
      );
    }
  }

  // Apply same pattern to post, put, patch, delete methods
}
```

---

### Fix 10: Create Localization System

#### Create new file

`frontend/lib/core/constants/app_strings.dart`

```dart
class AppStrings {
  // Common
  static const appName = 'AU Reader';
  static const loading = 'Loading...';
  static const error = 'Error';
  static const success = 'Success';
  static const cancel = 'Cancel';
  static const confirm = 'Confirm';
  static const save = 'Save';
  static const delete = 'Delete';

  // Home
  static const discover = 'Discover';
  static const findStory = 'Find your next favorite story';
  static const continueReading = 'Continue Reading';
  static const trending = 'Trending Now';
  static const forYou = 'For You';
  static const newReleases = 'New Releases';
  static const latestUpdates = 'Latest Updates';

  // Auth
  static const login = 'Login';
  static const register = 'Register';
  static const logout = 'Logout';
  static const email = 'Email';
  static const password = 'Password';
  static const forgotPassword = 'Forgot Password?';

  // Errors
  static const emailRequired = 'Email is required';
  static const passwordRequired = 'Password is required';
  static const invalidEmail = 'Invalid email format';
  static const loginFailed = 'Login failed';
  static const networkError = 'Network error. Please check your connection.';

  // Add more as needed...
}
```

Usage:

```dart
// Before
Text('Discover')

// After
Text(AppStrings.discover)
```

---

### Fix 11: Add Loading States

#### Pattern to Apply

```dart
class _MyScreenState extends State<MyScreen> {
  bool _isLoading = true;

  @override
  Widget build(BuildContext context) {
    // Always check loading state first
    if (_isLoading) {
      return Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // Then show content
    return Scaffold(
      body: // ... content
    );
  }
}
```

---

### Fix 12: Standardize Error Messages

#### Backend

Ensure all validation messages are in Indonesian:

```php
// In FormRequest classes
public function messages(): array
{
    return [
        'title.required' => 'Judul wajib diisi.',
        'title.max' => 'Judul maksimal 255 karakter.',
        'email.required' => 'Email wajib diisi.',
        'email.email' => 'Format email tidak valid.',
        // etc...
    ];
}
```

---

## 🧪 Testing After Fixes

### Backend Testing

```bash
cd backend

# Test API endpoints
php artisan test

# Check for errors
php artisan route:list
php artisan migrate:status
```

### Frontend Testing

```bash
cd frontend

# Analyze code
flutter analyze

# Run tests
flutter test

# Build to check for errors
flutter build web --release
```

---

## ✅ Verification Checklist

After applying fixes, verify:

- [ ] All controllers have dispose methods
- [ ] No null pointer exceptions in logs
- [ ] Images load with loading indicators
- [ ] Error messages are user-friendly
- [ ] No memory leaks (check with DevTools)
- [ ] API requests timeout properly
- [ ] All timers are cancelled on dispose
- [ ] Validation works on all forms
- [ ] No TODO comments remain
- [ ] Code passes `flutter analyze`
- [ ] Backend passes `php artisan test`

---

## 📊 Impact Assessment

### Before Fixes

- Memory leaks: Yes
- Null pointer risks: High
- Error handling: Basic
- User experience: Good
- Code quality: 7/10

### After Fixes

- Memory leaks: No
- Null pointer risks: Low
- Error handling: Excellent
- User experience: Excellent
- Code quality: 9/10

---

## 🎯 Conclusion

Dengan menerapkan fixes ini, project akan:

1. ✅ Lebih stabil (no crashes)
2. ✅ Lebih performant (no memory leaks)
3. ✅ Lebih maintainable (clean code)
4. ✅ Lebih user-friendly (better errors)
5. ✅ Production-ready

**Estimated Time to Fix All**: 4-6 hours

---

**Last Updated**: 2026-04-25
**Priority**: High
**Status**: Ready to implement
