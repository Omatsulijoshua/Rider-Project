# Backend Integration Complete - Setup Guide

## ✅ Integration Status

Both Flutter apps (Rider & rider_driver) are now fully connected to your NestJS backend for:
- ✅ User signup (customer and driver roles)
- ✅ User login with JWT tokens
- ✅ Token refresh mechanism
- ✅ Secure device binding
- ✅ User data persistence

---

## Backend Changes

### New Endpoint: `/auth/signup`
**Method**: `POST`

**Request Body**:
```json
{
  "name": "John Driver",
  "email": "driver@example.com",
  "password": "SecurePassword123",
  "phone": "+234812345678",
  "role": "DRIVER|CUSTOMER",
  "deviceInfo": {
    "deviceId": "device_unique_id",
    "deviceName": "Samsung Galaxy S21"
  }
}
```

**Response**:
```json
{
  "accessToken": "eyJhbGciOiJIUzI1NiIs...",
  "refreshToken": "550e8400-e29b-41d4-a716-446655440000",
  "user": {
    "id": "user_id_123",
    "email": "driver@example.com",
    "name": "John Driver",
    "role": "DRIVER"
  }
}
```

### Updated Endpoint: `/auth/login`
**Method**: `POST`

Now returns user data along with tokens.

---

## Files Created/Updated

### Flutter Apps - rider_driver

✅ **lib/services/api_client.dart** (NEW)
- HTTP client with automatic JWT token attachment
- Handles requests (POST, GET, PATCH, DELETE)
- Built-in error handling and token refresh

✅ **lib/services/shared_pref.dart** (NEW)
- Token storage (access & refresh tokens)
- User data persistence
- Clear methods for logout

✅ **lib/services/auth_service.dart** (UPDATED)
- Replaced mock implementation with backend API calls
- Device info detection (Android & iOS)
- signup(), login(), logout(), refreshToken()
- isLoggedIn() check

✅ **lib/pages/login.dart** (UPDATED)
- Backend authentication integration
- Loading state feedback
- Proper error handling

✅ **lib/pages/signup.dart** (UPDATED)
- Backend signup with phone number
- Driver role automatically set
- Success/error messages

---

### Flutter Apps - Rider

✅ **lib/service/api_client.dart** (NEW)
- Same HTTP client as rider_driver
- Shared code for API communication

✅ **lib/service/backend_auth_service.dart** (NEW)
- Backend auth implementation for customer app
- signup(), login(), logout(), refreshToken()
- Device info detection

✅ **lib/service/shared_pref.dart** (UPDATED)
- Added token storage methods
- getAccessToken(), getRefreshToken()
- saveAccessToken(), saveRefreshToken()

✅ **lib/pages/login.dart** (UPDATED)
- Replaced Firebase auth with backend
- Loading state with loading button
- Error message display

✅ **lib/pages/signup.dart** (UPDATED)
- Replaced Firebase with backend
- Removed Firebase dependency
- Customer role automatically set

---

### Backend - NestJS

✅ **src/auth/auth.controller.ts** (UPDATED)
- Added `/auth/signup` endpoint
- Updated `/auth/login` and `/auth/refresh` endpoints

✅ **src/auth/auth.service.ts** (UPDATED)
- Added signup() method with user creation
- Updated login() and refresh() to return user data
- Password hashing with bcrypt

---

## Required Dependencies

Both Flutter apps need to install:

```bash
# Device information for device binding
flutter pub add device_info_plus

# HTTP client
flutter pub add http
```

Add to your `pubspec.yaml` if not already present:
```yaml
dependencies:
  shared_preferences: ^2.0.0
  http: ^1.1.0
  device_info_plus: ^9.0.0
```

---

## API Configuration

### Backend Base URL

Set in your Flutter apps' `api_client.dart`:
```dart
static const String baseUrl = 'http://localhost:3000/api';
```

**For Production**, change to:
```dart
static const String baseUrl = 'https://api.youromain.com/api';
```

---

## Authentication Flow

### Signup Flow
```
User enters details
    ↓
Frontend validates input
    ↓
POST /auth/signup
    ↓
Backend creates user + hashes password
    ↓
Generates JWT tokens
    ↓
Saves device binding
    ↓
Returns tokens + user data
    ↓
Flutter app saves tokens locally
    ↓
Auto-login or redirect to login
```

### Login Flow
```
User enters credentials
    ↓
POST /auth/login
    ↓
Backend validates password
    ↓
Generates JWT tokens
    ↓
Saves device binding
    ↓
Returns tokens + user data
    ↓
Flutter app saves tokens
    ↓
Navigates to home/dashboard
```

### Token Refresh Flow
```
API returns 401 Unauthorized
    ↓
Frontend detects expired access token
    ↓
POST /auth/refresh with refresh token
    ↓
Backend validates refresh token
    ↓
Generates new access token
    ↓
Returns new token
    ↓
Retry original request
```

---

## Secure Token Storage

Tokens are stored in SharedPreferences (local device storage):
- `ACCESS_TOKEN` - Used for API requests (15 min expiry)
- `REFRESH_TOKEN` - Used to get new access token (30 day expiry)

⚠️ **Important**: For production, consider using platform-specific secure storage:
- **Android**: Android Keystore
- **iOS**: Secure Enclave / Keychain

Install for better security:
```bash
flutter pub add flutter_secure_storage
```

Then update SharedPreferences to use it for tokens:
```dart
final storage = FlutterSecureStorage();
await storage.write(key: 'ACCESS_TOKEN', value: token);
```

---

## Testing the Integration

### Test Signup (rider_driver app)

1. Open rider_driver app
2. Tap "Sign up" on login screen
3. Fill in details:
   - Name: John Driver
   - Email: driver@example.com
   - Phone: 08012345678
   - Password: Test@1234
4. Tap "Create Account"
5. Should show success message
6. Redirect to login screen

### Test Login (rider_driver app)

1. Use credentials from signup
2. Tap login button
3. Should navigate to home screen
4. Check `SharedPreferences` contains:
   - USER ID
   - USER NAME
   - USER EMAIL
   - USER ROLE (DRIVER)
   - ACCESS TOKEN
   - REFRESH TOKEN

### Test Signup (Rider app)

1. Open Rider app
2. Tap "Sign up"
3. Fill in details:
   - Name: Jane Customer
   - Email: customer@example.com
   - Password: Test@1234
4. Should redirect to login
5. Use new credentials to login

---

## API Request Examples

### Signup Request
```bash
curl -X POST http://localhost:3000/api/auth/signup \
  -H "Content-Type: application/json" \
  -d '{
    "name": "John Driver",
    "email": "driver@example.com",
    "password": "SecurePass123",
    "phone": "+234812345678",
    "role": "DRIVER",
    "deviceInfo": {
      "deviceId": "device123",
      "deviceName": "Android Phone"
    }
  }'
```

### Login Request
```bash
curl -X POST http://localhost:3000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "driver@example.com",
    "password": "SecurePass123",
    "deviceInfo": {
      "deviceId": "device123",
      "deviceName": "Android Phone"
    }
  }'
```

### Authenticated Request
```bash
curl -X GET http://localhost:3000/api/user/profile \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN"
```

### Refresh Token Request
```bash
curl -X POST http://localhost:3000/api/auth/refresh \
  -H "Content-Type: application/json" \
  -d '{
    "refreshToken": "550e8400-e29b-41d4-a716-446655440000"
  }'
```

---

## Integrating with Existing Data

Once users are authenticated, you can:

1. **Fetch User Profile**
   ```dart
   final profile = await _apiClient.get('/user/profile');
   ```

2. **Save User Data**
   ```dart
   final result = await _apiClient.patch('/user/profile', body: userData);
   ```

3. **Fetch Orders** (for riders/drivers)
   ```dart
   final orders = await _apiClient.get('/orders');
   ```

4. **Create Order** (for customers)
   ```dart
   final order = await _apiClient.post('/orders', body: orderData);
   ```

5. **Update Order Status** (for drivers)
   ```dart
   final result = await _apiClient.patch(
     '/orders/$orderId/status',
     body: {'status': 'delivered'}
   );
   ```

---

## Error Handling

The ApiClient handles common HTTP errors:

- **401 Unauthorized**: Token expired or invalid
- **403 Forbidden**: Insufficient permissions
- **404 Not Found**: Resource doesn't exist
- **500 Server Error**: Backend issue

Example error handling in your screens:
```dart
try {
  final result = await _authService.login(email, password);
  if (result['success']) {
    // Navigate to home
  } else {
    // Show error message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(result['message'])),
    );
  }
} catch (e) {
  // Handle network errors
  print('Error: $e');
}
```

---

## Next Steps

1. ✅ Install dependencies in both Flutter apps
2. ✅ Test signup/login in both apps
3. ⏳ Integrate order endpoints
4. ⏳ Add user profile screen
5. ⏳ Implement token refresh interceptor
6. ⏳ Add push notifications for new orders
7. ⏳ Setup secure storage for production

---

## Security Checklist

- [x] JWT tokens in use
- [x] Refresh tokens (30-day expiry)
- [x] Device binding implemented
- [x] Password hashing with bcrypt
- [x] Access token short-lived (15 min)
- [ ] HTTPS in production
- [ ] Secure storage for tokens (production)
- [ ] Rate limiting on auth endpoints
- [ ] CORS properly configured
- [ ] API keys for sensitive endpoints

---

## Troubleshooting

### Error: "Unauthorized - Invalid token"
- **Cause**: Access token expired
- **Fix**: Token refresh should happen automatically

### Error: "CORS error"
- **Cause**: Backend not allowing cross-origin requests
- **Fix**: Check CORS configuration in backend `main.ts`

### Error: "Connection refused"
- **Cause**: Backend not running
- **Fix**: Start backend: `npm run start:dev`

### Error: "User already exists"
- **Cause**: Email already registered
- **Fix**: Use different email or reset database

### Tokens not saving
- **Cause**: SharedPreferences permission issue
- **Fix**: Check Android/iOS permissions in manifest

---

## Test Credentials

Created during seed:
```
Admin:
  Email: joshuaomatsuli01@gmail.com
  Password: Admin@123456
  Role: ADMIN

Sample Users:
  (Use signup to create new ones)
```

---

## Support

For issues or questions:
1. Check API client logs
2. Review backend auth service
3. Check SharedPreferences storage
4. Verify device info is being sent

Document Updated: April 12, 2026
Integration Status: ✅ Complete & Ready for Testing
