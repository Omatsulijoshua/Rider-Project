# ✅ Backend Integration - Quick Setup Checklist

## 📱 Flutter Apps - Install Dependencies

### For both Rider and rider_driver apps:

```bash
# rider_driver app
cd rider_driver
flutter pub add device_info_plus http

# Rider app
cd ../Rider
flutter pub add device_info_plus http

# Run pub get
flutter pub get
```

---

## 🔧 Backend - Verify Endpoints

Test your backend endpoints:

```bash
# Start backend (if not running)
cd rider-backend
npm run start:dev

# Test signup
curl -X POST http://localhost:3000/api/auth/signup \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Test Driver",
    "email": "driver@test.com",
    "password": "Test@1234",
    "phone": "+234812345678",
    "role": "DRIVER",
    "deviceInfo": {
      "deviceId": "test_device_1",
      "deviceName": "Test Device"
    }
  }'

# Test login
curl -X POST http://localhost:3000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "driver@test.com",
    "password": "Test@1234",
    "deviceInfo": {
      "deviceId": "test_device_1",
      "deviceName": "Test Device"
    }
  }'
```

---

## 📲 Test Rider Driver App

1. **Run the app**:
   ```bash
   cd rider_driver
   flutter run
   ```

2. **Test Signup**:
   - Tap "Sign up"
   - Enter:
     - Name: John Driver
     - Email: driver1@test.com
     - Phone: 08012345678
     - Password: Driver@123
   - Tap "Create Account"
   - ✅ Should show success message

3. **Test Login**:
   - Enter login credentials from above
   - Tap login button
   - ✅ Should navigate to home

4. **Verify Stored Data**:
   - Check SharedPreferences contains:
     - USER ID
     - ACCESS TOKEN
     - REFRESH TOKEN

---

## 📲 Test Rider (Customer) App

1. **Run the app**:
   ```bash
   cd Rider
   flutter run
   ```

2. **Test Signup**:
   - Tap "Sign up" 
   - Enter:
     - Name: Jane Customer
     - Email: customer1@test.com
     - Password: Customer@123
   - Tap "Sign up"
   - ✅ Should show success message
   - ✅ Should redirect to login

3. **Test Login**:
   - Use credentials from signup
   - Tap login arrow
   - ✅ Should navigate to home

---

## 🔐 Token Management

The apps automatically handle:
- ✅ Token storage in SharedPreferences
- ✅ Token includes in all API requests
- ✅ Manual token refresh on 401 errors
- ✅ Clear tokens on logout

---

## 🐛 Debugging

If something doesn't work:

1. **Check Backend Running**:
   ```bash
   curl http://localhost:3000/api/auth/login
   # Should return JSON error, not connection refused
   ```

2. **Check Logs**:
   - Flutter: `flutter logs` in terminal
   - NestJS: Check console output

3. **Clear and Rebuild**:
   ```bash
   flutter clean
   flutter pub get
   flutter run
   ```

4. **Check SharedPreferences**:
   - Android: `adb shell`
   - Access preferences file in:
     `/data/data/com.example.app/shared_prefs/`

---

## 📊 What's Connected

| Feature | Status |
|---------|--------|
| Signup (Driver) | ✅ Connected |
| Signup (Customer) | ✅ Connected |
| Login | ✅ Connected |
| Token Refresh | ✅ Connected |
| Device Binding | ✅ Connected |
| User Data Storage | ✅ Connected |
| JWT Auth Headers | ✅ Connected |

---

## 🎯 Next Features to Integrate

Once basic auth is working:

1. **Order Management**
   - Fetch orders: `/orders`
   - Create order: `POST /orders`
   - Update status: `PATCH /orders/{id}/status`
   - Get order history: `/orders/history`

2. **User Profile**
   - Get profile: `GET /user/profile`
   - Update profile: `PATCH /user/profile`
   - Upload photo: `POST /user/photo`

3. **Notifications**
   - Get new orders: Real-time from backend
   - Update status: Push notifications
   - Message customer/driver

4. **Payments**
   - Connect Flutterwave
   - Process payments
   - Get transaction history

5. **KYC Verification**
   - Already UI created
   - Connect to backend endpoints
   - Document upload & verification

---

## 🚀 Production Checklist

Before deploying to stores:

- [ ] Change base URL to production domain
- [ ] Enable HTTPS only
- [ ] Use secure token storage (flutter_secure_storage)
- [ ] Setup rate limiting on auth endpoints
- [ ] Enable CORS properly
- [ ] Setup monitoring/logging
- [ ] Test on real devices
- [ ] Test with real network conditions
- [ ] Implement automatic token refresh interceptor
- [ ] Add analytics for auth events

---

## 📞 Support

### Common Errors & Fixes

**"Connection refused"**
- ✅ Backend not running: `npm run start:dev`

**"Invalid credentials"**
- ✅ Email not registered, use signup
- ✅ Wrong password

**"Email already in use"**
- ✅ Use different email
- ✅ Or reset database: `npx prisma db push --force-reset`

**"User not exists"**
- ✅ Use login after signup
- ✅ Check email is correct

---

## 📝 Notes

- Password must be at least 6 characters
- Email must be valid format
- Phone should include country code
- Device ID must be unique per device
- Access tokens expire in 15 minutes
- Refresh tokens expire in 30 days

---

Created: April 12, 2026
Status: ✅ Ready for Testing
