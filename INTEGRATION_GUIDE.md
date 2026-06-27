# Flutter App Integration Guide

## Quick Start - Implementation Steps

### Step 1: Update Dependencies
```bash
# Navigate to each project
cd Rider
flutter pub get

cd ../rider_driver
flutter pub get
```

### Step 2: Add Image Picker Package
```bash
# For Rider app (customer)
cd Rider
flutter pub add image_picker

# For rider_driver app (driver)
cd ../rider_driver
flutter pub add image_picker
```

### Step 3: Connect Screens to Navigation

#### For Rider Driver App (Bottom Navigation)
The shipment tracking is already integrated in `bottomnav.dart`. Verify it appears in the shipments tab.

#### For Rider App (Add to Main Navigation)
Add these screens to your main app navigation:

```dart
// In your main.dart or app.dart
import 'package:rider/pages/order_history_screen.dart';
import 'package:rider/pages/kyc_screen.dart';
import 'package:rider/pages/image_capture_screen.dart';

class RiderApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      routes: {
        '/order_history': (context) => const OrderHistoryScreen(),
        '/kyc': (context) => const KYCScreen(),
        '/image_capture': (context) => const ImageCaptureScreen(
          onImageCapture: (path) => print('Image: $path'),
        ),
        '/post': (context) => const PostPage(),
        // ... other routes
      },
    );
  }
}
```

### Step 4: Update Profile Screen
Add navigation buttons to the profile page:

```dart
// In profile.dart
Column(
  children: [
    ListTile(
      leading: Icon(Icons.shopping_bag),
      title: Text('Order History'),
      onTap: () => Navigator.pushNamed(context, '/order_history'),
    ),
    ListTile(
      leading: Icon(Icons.verified_user),
      title: Text('KYC Verification'),
      onTap: () => Navigator.pushNamed(context, '/kyc'),
    ),
    ListTile(
      leading: Icon(Icons.camera),
      title: Text('Add Product Images'),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ImageCaptureScreen(
            onImageCapture: (path) => print('Selected: $path'),
          ),
        ),
      ),
    ),
  ],
)
```

### Step 5: Connect Delivery Provider
Update your `main.dart` to provide the DeliveryProvider:

```dart
import 'package:provider/provider.dart';
import 'package:rider_driver/provider/delivery_provider.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => DeliveryProvider()),
        // ... other providers
      ],
      child: const RiderDriverApp(),
    ),
  );
}
```

### Step 6: Implement Backend API Integration

Create an API service to handle communication:

```dart
// lib/services/order_api_service.dart
import 'package:http/http.dart' as http;

class OrderApiService {
  static const String baseUrl = 'http://localhost:3000/api';

  Future<void> acceptOrder(String orderId, String driverId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/orders/$orderId/accept'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'driverId': driverId}),
    );
    
    if (response.statusCode != 200) {
      throw Exception('Failed to accept order');
    }
  }

  Future<void> updateOrderStatus(String orderId, String status) async {
    final response = await http.patch(
      Uri.parse('$baseUrl/orders/$orderId/status'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'status': status}),
    );
    
    if (response.statusCode != 200) {
      throw Exception('Failed to update order status');
    }
  }

  Future<List<OrderModel>> getActiveOrders(String driverId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/driver/$driverId/active-orders'),
    );
    
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => OrderModel.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load orders');
    }
  }
}
```

Then use it in your provider:

```dart
// In delivery_provider.dart
Future<void> updateMultipleOrderStatus(String orderId, String newStatus) async {
  try {
    // Call API
    await orderApiService.updateOrderStatus(orderId, newStatus);
    
    // Update local state
    final orderIndex = _activeOrders.indexWhere((o) => o.id == orderId);
    if (orderIndex != -1) {
      final updatedOrder = _activeOrders[orderIndex].copyWith(status: newStatus);
      _activeOrders[orderIndex] = updatedOrder;
      notifyListeners();
    }
  } catch (e) {
    _error = e.toString();
    notifyListeners();
  }
}
```

### Step 7: Implement Image Upload

```dart
// lib/services/image_service.dart
import 'package:http/http.dart' as http;

class ImageService {
  static const String baseUrl = 'http://localhost:3000/api';

  Future<String> uploadImage(File imageFile, String orderId) async {
    final request = http.MultipartRequest(
      'POST',
      Uri.parse('$baseUrl/orders/$orderId/images'),
    );

    request.files.add(
      await http.MultipartFile.fromPath('image', imageFile.path),
    );

    final response = await request.send();
    
    if (response.statusCode == 200) {
      final result = await response.stream.bytesToString();
      final jsonData = jsonDecode(result);
      return jsonData['imageUrl'];
    } else {
      throw Exception('Failed to upload image');
    }
  }
}
```

### Step 8: Wire Up Image Capture in post.dart

```dart
// In post.dart _PostPageState
Future<void> _captureFromCamera() async {
  final ImagePicker picker = ImagePicker();
  final XFile? photo = await picker.pickImage(source: ImageSource.camera);
  
  if (photo != null) {
    setState(() {
      _capturedImages.add(photo.path);
    });
  }
}

Future<void> _selectFromGallery() async {
  final ImagePicker picker = ImagePicker();
  final XFile? image = await picker.pickImage(source: ImageSource.gallery);
  
  if (image != null) {
    setState(() {
      _capturedImages.add(image.path);
    });
  }
}
```

### Step 9: Test All Screens

Run each screen individually:

```bash
# In rider_driver directory
flutter run -t lib/pages/bottomnav.dart

# In Rider directory
flutter run -t lib/pages/post.dart
flutter run -t lib/pages/order_history_screen.dart
flutter run -t lib/pages/kyc_screen.dart
```

### Step 10: Full App Testing

```bash
# Test order flow
flutter run

# Navigate to each screen and test:
# - Shipment Tracking (accept/reject orders)
# - Order History (filter by status)
# - KYC (submit verification)
# - Image Capture (add/remove images)
```

---

## Backend Endpoint Requirements

Your NestJS backend needs these endpoints:

### Order Management
```
POST   /orders/{orderId}/accept
POST   /orders/{orderId}/reject
PATCH  /orders/{orderId}/status
GET    /driver/{driverId}/active-orders
GET    /orders/history
```

### Image Handling
```
POST   /orders/{orderId}/images
GET    /orders/{orderId}/images
DELETE /orders/{orderId}/images/{imageId}
```

### KYC
```
POST   /kyc/submit
GET    /kyc/status
PATCH  /kyc/documents
```

---

## Troubleshooting

### Issue: Screens not found
**Solution**: Make sure all imports are correct:
```dart
import 'package:rider/pages/order_history_screen.dart';
import 'package:rider_driver/screen/shipment_tracking_screen.dart';
```

### Issue: Image picker not working
**Solution**: Add permissions to platform files:

**Android** (`android/app/src/main/AndroidManifest.xml`):
```xml
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
```

**iOS** (`ios/Runner/Info.plist`):
```xml
<key>NSCameraUsageDescription</key>
<string>This app needs camera access to capture images</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>This app needs photo library access</string>
```

### Issue: API calls failing
**Solution**: 
1. Check backend is running on correct port (3000)
2. Enable CORS in backend
3. Verify API endpoint paths match backend routes
4. Check request/response JSON format matches OrderModel

### Issue: State not updating
**Solution**: Ensure DeliveryProvider is wrapped with ChangeNotifierProvider in main.dart

---

## Performance Optimization Tips

1. **Image Optimization**:
```dart
Future<File> compressImage(File imageFile) async {
  final tempDir = await getTemporaryDirectory();
  final targetPath = '${tempDir.absolute.path}/img_${DateTime.now().millisecondsSinceEpoch}.jpg';
  
  var result = await FlutterImageCompress.compressAndGetFile(
    imageFile.absolute.path,
    targetPath,
    quality: 70,
  );
  
  return result ?? imageFile;
}
```

2. **Lazy Loading Orders**:
```dart
// Load orders only when needed
@override
void didChangeAppLifecycleState(AppLifecycleState state) {
  if (state == AppLifecycleState.resumed) {
    deliveryProvider.refreshOrders();
  }
}
```

3. **Pagination for Order History**:
```dart
// Implement pagination for large lists
class OrderHistoryScreen extends StatefulWidget {
  final int pageSize = 20;
}
```

---

## Security Considerations

1. **JWT Token Management**:
   - Store auth tokens securely
   - Refresh tokens before expiry
   - Clear on logout

2. **Image Validation**:
   - Validate file types (image only)
   - Check file size limits
   - Anti-virus scan on server

3. **Data Privacy**:
   - Hash sensitive customer data
   - Encrypt images in transit (HTTPS)
   - Remove temporary image files after upload

---

## Monitoring & Analytics

Add analytics to track:
- Order acceptance/rejection rates
- Average delivery time
- User engagement with KYC
- Order completion metrics

```dart
import 'package:firebase_analytics/firebase_analytics.dart';

// Track order accepted
FirebaseAnalytics.instance.logEvent(
  name: 'order_accepted',
  parameters: {
    'order_id': orderId,
    'amount': order.price,
  },
);
```

---

## Support & Documentation

- Flutter Image Picker: https://pub.dev/packages/image_picker
- Provider Pattern: https://pub.dev/packages/provider
- Material Design: https://material.io/design
- Firebase Docs: https://firebase.flutter.dev

---

## Next Steps Checklist

- [ ] Install image_picker package
- [ ] Update app navigation
- [ ] Implement OrderApiService
- [ ] Implement ImageService
- [ ] Wire up backend endpoints
- [ ] Add platform permissions
- [ ] Test all screenshots
- [ ] Implement error handling
- [ ] Setup analytics
- [ ] Deploy to stores

---

Document Version: 1.0
Created: Flutter Enhancement Session
