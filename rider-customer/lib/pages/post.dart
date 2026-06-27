import 'package:flutter/material.dart';
import 'package:flutterwave_standard/flutterwave.dart';
import 'package:rider/pages/track_delivery.dart';
import 'package:rider/service/api_client.dart';
import 'package:rider/service/shared_pref.dart';
import 'package:rider/service/widget_support.dart';
import 'package:rider/service/constant.dart';
import 'package:rider/pages/map_picker.dart';
import 'package:rider/pages/payment_page.dart';
import 'package:rider/service/utils.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';
import 'package:intl/intl.dart';

class PostPage extends StatefulWidget {
  const PostPage({super.key});

  @override
  State<PostPage> createState() => _PostPageState();
}

class _PostPageState extends State<PostPage> {
  TextEditingController pickupaddress = TextEditingController();
  TextEditingController pickupusername = TextEditingController();
  TextEditingController pickupphone = TextEditingController();
  TextEditingController pickupcompany = TextEditingController();
  TextEditingController dropoffaddress = TextEditingController();
  TextEditingController dropoffusername = TextEditingController();
  TextEditingController dropoffphone = TextEditingController();
  TextEditingController dropoffcompany = TextEditingController();
  TextEditingController itemType = TextEditingController();
  TextEditingController weight = TextEditingController();
  TextEditingController instructions = TextEditingController();
  String? email, id;
  final List<String> _capturedImages = [];

  double? pickupLat, pickupLng, dropLat, dropLng;
  double totalAmount = 0.0;
  DateTime? scheduledAt;

  Future<void> getthesharedpref() async {
    email = await SharedpreferenceHelper().getUserEmail();
    id = await SharedpreferenceHelper().getUserID();
    setState(() {});
  }

  Future<void> ontheload() async {
    await getthesharedpref();
    setState(() {});
  }

  @override
  void initState() {
    super.initState();
    ontheload();
  }

  Future<void> _selectLocation(bool isPickup) async {
    final LatLng? result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MapPicker(
          title: isPickup ? "Select Pick-Up" : "Select Drop-Off",
        ),
      ),
    );

    if (result != null) {
      setState(() {
        if (isPickup) {
          pickupLat = result.latitude;
          pickupLng = result.longitude;
          pickupaddress.text = "Fetching address...";
        } else {
          dropLat = result.latitude;
          dropLng = result.longitude;
          dropoffaddress.text = "Fetching address...";
        }
        _calculatePrice();
      });

      // 🔍 Get Address from coordinates
      try {
        List<Placemark> placemarks = await placemarkFromCoordinates(
          result.latitude,
          result.longitude,
        );
        if (placemarks.isNotEmpty) {
          Placemark place = placemarks[0];
          String address = "${place.name}, ${place.locality}, ${place.country}";
          setState(() {
            if (isPickup) {
              pickupaddress.text = address;
            } else {
              dropoffaddress.text = address;
            }
          });
        }
      } catch (e) {
        setState(() {
          if (isPickup) {
            pickupaddress.text = "Lat: ${result.latitude.toStringAsFixed(4)}, Lng: ${result.longitude.toStringAsFixed(4)}";
          } else {
            dropoffaddress.text = "Lat: ${result.latitude.toStringAsFixed(4)}, Lng: ${result.longitude.toStringAsFixed(4)}";
          }
        });
      }
    }
  }

  void _calculatePrice() {
    if (pickupLat != null && pickupLng != null && dropLat != null && dropLng != null) {
      double distance = MapUtils.calculateDistance(pickupLat!, pickupLng!, dropLat!, dropLng!);
      setState(() {
        totalAmount = MapUtils.estimatePrice(distance);
      });
    }
  }

  Future<void> _geocodeAddress(String address, bool isPickup) async {
    if (address.isEmpty) return;
    try {
      List<Location> locations = await locationFromAddress(address);
      if (locations.isNotEmpty) {
        setState(() {
          if (isPickup) {
            pickupLat = locations[0].latitude;
            pickupLng = locations[0].longitude;
          } else {
            dropLat = locations[0].latitude;
            dropLng = locations[0].longitude;
          }
          _calculatePrice();
        });
      }
    } catch (e) {
      // Could not geocode address
    }
  }

  Future<void> _selectSchedule() async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 7)),
    );

    if (pickedDate != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );

      if (pickedTime != null) {
        setState(() {
          scheduledAt = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
        });
      }
    }
  }

  /// Flutterwave payment — NOTE: do NOT pass `context` into the constructor.
  Future<void> makePayment(
      BuildContext context, String email, String amount) async {
    if (amount.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid amount')),
      );
      return;
    }

    final Customer customer = Customer(
      email: email,
      phoneNumber:
          pickupphone.text.isNotEmpty ? pickupphone.text : "08000000000",
    );

    final Flutterwave flutterwave = Flutterwave(
      publicKey: flutterwavePublicKey, // ✅ now using constant
      txRef: DateTime.now().millisecondsSinceEpoch.toString(),
      amount: amount,
      currency: "NGN",
      customer: customer,
      paymentOptions: "card, ussd, banktransfer",
      customization: Customization(
        title: "Rider Payment",
        description: "Payment for your order",
      ),
      redirectUrl: "https://www.google.com", // ✅ test redirect
      isTestMode: true, // switch to false in production
    );

    try {
      final ChargeResponse response = await flutterwave.charge(context);

      if (response.success == true) {
        final String orderId =
            response.txRef ?? DateTime.now().millisecondsSinceEpoch.toString();
        final String tracknumber =
            "TRK${DateTime.now().millisecondsSinceEpoch}";

        Map<String, dynamic> orderData = {
          "pickupLat": 0.0, // Should be fetched from a map picker
          "pickupLng": 0.0,
          "dropLat": 0.0,
          "dropLng": 0.0,
          "price": double.tryParse(amount) ?? 0.0,
          "pickupCompanyName": pickupcompany.text,
          "dropoffCompanyName": dropoffcompany.text,
          "itemType": itemType.text,
          "weight": double.tryParse(weight.text) ?? 0.0,
          "recipientName": dropoffusername.text,
          "recipientPhone": dropoffphone.text,
          "deliveryInstructions": instructions.text,
        };

        try {
          final response = await ApiClient().post('/orders', body: orderData);
          
          if (mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => TrackDeliveryPage(order: response),
              ),
            );
          }
        } catch (apiError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: Colors.red,
              content: Text(
                "❌ Error saving order to backend: ${apiError.toString()}",
                style: AppWidget.whiteTextFieldStyle(16.0),
              ),
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                "❌ Payment failed: ${response.status ?? 'Transaction cancelled'}"),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("⚠️ Payment error: ${e.toString()}")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xff6053f8),
      body: Container(
        margin: const EdgeInsets.only(top: 40.0),
        child: Column(
          children: [
            Center(
              child: Text(
                "Add Package",
                style: AppWidget.whiteTextFieldStyle(24.0),
              ),
            ),
            const SizedBox(height: 20.0),
            Expanded(
              child: Container(
                padding: const EdgeInsets.only(left: 20.0, right: 20.0),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                ),
                width: MediaQuery.of(context).size.width,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),
                      Center(
                        child: Image.asset(
                          "images/delivery-truck.png",
                          height: 180,
                          width: 180,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text("Add Location",
                          style: AppWidget.headlineTextFieldStyle()),
                      const SizedBox(height: 20.0),
                      Text("Pick Up", style: AppWidget.normalTextFieldStyle()),
                      const SizedBox(height: 5.0),
                      Container(
                        padding: const EdgeInsets.only(left: 10.0, right: 10.0),
                        decoration: BoxDecoration(
                          color: const Color(0xFFececf8),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: TextField(
                          controller: pickupaddress,
                          onChanged: (val) => _geocodeAddress(val, true),
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            hintText: "Select or type Pick Up Location",
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.location_on, color: Color(0xff6053f8)),
                              onPressed: () => _selectLocation(true),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20.0),
                      Text("Drop-Off", style: AppWidget.normalTextFieldStyle()),
                      const SizedBox(height: 5.0),
                      Container(
                        padding: const EdgeInsets.only(left: 10.0, right: 10.0),
                        decoration: BoxDecoration(
                          color: const Color(0xFFececf8),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: TextField(
                          controller: dropoffaddress,
                          onChanged: (val) => _geocodeAddress(val, false),
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            hintText: "Select or type drop off Location",
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.location_on, color: Color(0xff6053f8)),
                              onPressed: () => _selectLocation(false),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20.0),
                      const SizedBox(height: 20.0),
                      Center(
                        child: Column(
                          children: [
                            if (scheduledAt != null)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8.0),
                                child: Text(
                                  "Scheduled for: ${DateFormat("MMM dd, yyyy • hh:mm a").format(scheduledAt!)}",
                                  style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                                ),
                              ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                GestureDetector(
                                  onTap: () {
                                    // Submit Location
                                  },
                                  child: Container(
                                    height: 60,
                                    width: MediaQuery.of(context).size.width / 2.2,
                                    decoration: BoxDecoration(
                                      color: const Color(0xff6053f8),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Center(
                                      child: Text(
                                        "Submit Location",
                                        style: AppWidget.whiteTextFieldStyle(18.0),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                GestureDetector(
                                  onTap: _selectSchedule,
                                  child: Container(
                                    height: 60,
                                    width: MediaQuery.of(context).size.width / 2.8,
                                    decoration: BoxDecoration(
                                      border: Border.all(color: const Color(0xff6053f8), width: 2),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Center(
                                      child: Icon(Icons.calendar_month, color: Color(0xff6053f8)),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 40.0),
                      // PICK-UP DETAILS (kept same)
                      Container(
                        margin: const EdgeInsets.only(right: 20.0),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.black45, width: 2.0),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Pick-Up Details",
                                style: AppWidget.normalTextFieldStyle()),
                            const SizedBox(height: 10.0),
                            Row(
                              children: [
                                const Icon(Icons.location_on,
                                    color: Color(0xff6053f8), size: 30.0),
                                const SizedBox(width: 10.0),
                                Expanded(
                                  child: TextField(
                                    controller: pickupaddress,
                                    onChanged: (val) => _geocodeAddress(val, true),
                                    decoration: const InputDecoration(
                                      hintText: "Enter pick-up Address",
                                      suffixIcon: Icon(Icons.search, size: 18),
                                      enabledBorder: UnderlineInputBorder(
                                        borderSide:
                                            BorderSide(color: Colors.black26),
                                      ),
                                    ),
                                  ),
                                )
                              ],
                            ),
                            const SizedBox(height: 10.0),
                            Row(
                              children: [
                                const Icon(Icons.person,
                                    color: Color(0xff6053f8), size: 30.0),
                                const SizedBox(width: 10.0),
                                Expanded(
                                  child: TextField(
                                    controller: pickupusername,
                                    decoration: const InputDecoration(
                                      hintText: "Enter User name",
                                      enabledBorder: UnderlineInputBorder(
                                        borderSide:
                                            BorderSide(color: Colors.black26),
                                      ),
                                    ),
                                  ),
                                )
                              ],
                            ),
                            const SizedBox(height: 10.0),
                            Row(
                              children: [
                                const Icon(Icons.phone,
                                    color: Color(0xff6053f8), size: 30.0),
                                const SizedBox(width: 10.0),
                                Expanded(
                                  child: TextField(
                                    controller: pickupphone,
                                    decoration: const InputDecoration(
                                      hintText: "Enter phone number",
                                      enabledBorder: UnderlineInputBorder(
                                        borderSide:
                                            BorderSide(color: Colors.black26),
                                      ),
                                    ),
                                  ),
                                )
                              ],
                            ),
                            const SizedBox(height: 10.0),
                            Row(
                              children: [
                                const Icon(Icons.business,
                                    color: Color(0xff6053f8), size: 30.0),
                                const SizedBox(width: 10.0),
                                Expanded(
                                  child: TextField(
                                    controller: pickupcompany,
                                    decoration: const InputDecoration(
                                      hintText: "Enter Company Name (Optional)",
                                      enabledBorder: UnderlineInputBorder(
                                        borderSide:
                                            BorderSide(color: Colors.black26),
                                      ),
                                    ),
                                  ),
                                )
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 40.0),
                      // DROP-OFF DETAILS (kept same)
                      Container(
                        margin: const EdgeInsets.only(right: 20.0),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.black45, width: 2.0),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Drop-off Details",
                                style: AppWidget.normalTextFieldStyle()),
                            const SizedBox(height: 10.0),
                            Row(
                              children: [
                                const Icon(Icons.location_on,
                                    color: Color(0xff6053f8), size: 30.0),
                                const SizedBox(width: 10.0),
                                Expanded(
                                  child: TextField(
                                    controller: dropoffaddress,
                                    decoration: const InputDecoration(
                                      hintText: "Enter drop-off Address",
                                      enabledBorder: UnderlineInputBorder(
                                        borderSide:
                                            BorderSide(color: Colors.black26),
                                      ),
                                    ),
                                  ),
                                )
                              ],
                            ),
                            const SizedBox(height: 10.0),
                            Row(
                              children: [
                                const Icon(Icons.person,
                                    color: Color(0xff6053f8), size: 30.0),
                                const SizedBox(width: 10.0),
                                Expanded(
                                  child: TextField(
                                    controller: dropoffusername,
                                    decoration: const InputDecoration(
                                      hintText: "Enter User name",
                                      enabledBorder: UnderlineInputBorder(
                                        borderSide:
                                            BorderSide(color: Colors.black26),
                                      ),
                                    ),
                                  ),
                                )
                              ],
                            ),
                            const SizedBox(height: 10.0),
                            Row(
                              children: [
                                const Icon(Icons.phone,
                                    color: Color(0xff6053f8), size: 30.0),
                                const SizedBox(width: 10.0),
                                Expanded(
                                  child: TextField(
                                    controller: dropoffphone,
                                    decoration: const InputDecoration(
                                      hintText: "Enter phone number",
                                      enabledBorder: UnderlineInputBorder(
                                        borderSide:
                                            BorderSide(color: Colors.black26),
                                      ),
                                    ),
                                  ),
                                )
                              ],
                            ),
                            const SizedBox(height: 10.0),
                            Row(
                              children: [
                                const Icon(Icons.business,
                                    color: Color(0xff6053f8), size: 30.0),
                                const SizedBox(width: 10.0),
                                Expanded(
                                  child: TextField(
                                    controller: dropoffcompany,
                                    decoration: const InputDecoration(
                                      hintText: "Enter Company Name (Optional)",
                                      enabledBorder: UnderlineInputBorder(
                                        borderSide:
                                            BorderSide(color: Colors.black26),
                                      ),
                                    ),
                                  ),
                                )
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 40.0),
                      // PACKAGE DETAILS
                      Container(
                        margin: const EdgeInsets.only(right: 20.0),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.black45, width: 2.0),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Package Details",
                                style: AppWidget.normalTextFieldStyle()),
                            const SizedBox(height: 10.0),
                            Row(
                              children: [
                                const Icon(Icons.category,
                                    color: Color(0xff6053f8), size: 30.0),
                                const SizedBox(width: 10.0),
                                Expanded(
                                  child: TextField(
                                    controller: itemType,
                                    decoration: const InputDecoration(
                                      hintText: "Item Type (e.g. Parcel, Document)",
                                      enabledBorder: UnderlineInputBorder(
                                        borderSide:
                                            BorderSide(color: Colors.black26),
                                      ),
                                    ),
                                  ),
                                )
                              ],
                            ),
                            const SizedBox(height: 10.0),
                            Row(
                              children: [
                                const Icon(Icons.line_weight,
                                    color: Color(0xff6053f8), size: 30.0),
                                const SizedBox(width: 10.0),
                                Expanded(
                                  child: TextField(
                                    controller: weight,
                                    keyboardType: TextInputType.number,
                                    decoration: const InputDecoration(
                                      hintText: "Approx. Weight (kg)",
                                      enabledBorder: UnderlineInputBorder(
                                        borderSide:
                                            BorderSide(color: Colors.black26),
                                      ),
                                    ),
                                  ),
                                )
                              ],
                            ),
                            const SizedBox(height: 10.0),
                            Row(
                              children: [
                                const Icon(Icons.note_add,
                                    color: Color(0xff6053f8), size: 30.0),
                                const SizedBox(width: 10.0),
                                Expanded(
                                  child: TextField(
                                    controller: instructions,
                                    decoration: const InputDecoration(
                                      hintText: "Delivery Instructions",
                                      enabledBorder: UnderlineInputBorder(
                                        borderSide:
                                            BorderSide(color: Colors.black26),
                                      ),
                                    ),
                                  ),
                                )
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 30.0),
                      // ITEM IMAGES SECTION
                      Text("Item Images",
                          style: AppWidget.normalTextFieldStyle()),
                      const SizedBox(height: 12.0),
                      Container(
                        margin: const EdgeInsets.only(right: 20.0),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.black45, width: 2.0),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (_capturedImages.isEmpty)
                              Center(
                                child: Column(
                                  children: [
                                    Icon(Icons.image_not_supported,
                                        size: 40, color: Colors.grey[400]),
                                    const SizedBox(height: 8),
                                    Text(
                                      "No images added",
                                      style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 14),
                                    ),
                                  ],
                                ),
                              )
                            else
                              GridView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 3,
                                  crossAxisSpacing: 8,
                                  mainAxisSpacing: 8,
                                ),
                                itemCount: _capturedImages.length,
                                itemBuilder: (context, index) {
                                  return Stack(
                                    children: [
                                      Container(
                                        decoration: BoxDecoration(
                                          color: Colors.grey[200],
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: Center(
                                          child: Icon(Icons.image,
                                              color: Colors.grey[400]),
                                        ),
                                      ),
                                      Positioned(
                                        top: 0,
                                        right: 0,
                                        child: GestureDetector(
                                          onTap: () {
                                            setState(() {
                                              _capturedImages.removeAt(index);
                                            });
                                          },
                                          child: Container(
                                            decoration: const BoxDecoration(
                                              color: Colors.red,
                                              shape: BoxShape.circle,
                                            ),
                                            padding: const EdgeInsets.all(2),
                                            child: const Icon(
                                              Icons.close,
                                              color: Colors.white,
                                              size: 14,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                            const SizedBox(height: 12),
                            Center(
                              child: GestureDetector(
                                onTap: _showImageOptions,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xff6053f8),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.add_a_photo,
                                          color: Colors.white, size: 18),
                                      const SizedBox(width: 6),
                                      Text(
                                        "Add Image",
                                        style:
                                            AppWidget.whiteTextFieldStyle(14),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 30.0),
                      // Price & checkout
                      Container(
                        padding: const EdgeInsets.only(
                            left: 30.0, top: 10.0, bottom: 10.0),
                        margin: const EdgeInsets.only(right: 20.0),
                        width: MediaQuery.of(context).size.width,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.black45, width: 2.0),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            Column(
                              children: [
                                Text("Total Price",
                                    style: AppWidget.simpleTextFieldStyle()),
                                Text("₦${totalAmount.toStringAsFixed(0)}",
                                    style: AppWidget.headlineTextFieldStyle())
                              ],
                            ),
                            const SizedBox(width: 50.0),
                             GestureDetector(
                               onTap: () {
                                 if (email == null) {
                                   ScaffoldMessenger.of(context).showSnackBar(
                                     const SnackBar(content: Text("User data not loaded yet.")),
                                   );
                                   return;
                                 }

                                 if (pickupLat != null &&
                                     pickupusername.text.isNotEmpty &&
                                     pickupphone.text.isNotEmpty &&
                                     dropLat != null) {
                                   
                                   if (_capturedImages.isEmpty) {
                                     ScaffoldMessenger.of(context).showSnackBar(
                                       SnackBar(
                                         backgroundColor: Colors.orange,
                                         content: Text(
                                           "Please add at least one item image",
                                           style: AppWidget.whiteTextFieldStyle(20.0),
                                         ),
                                       ),
                                     );
                                     return;
                                   }
                                   
                                   Map<String, dynamic> orderData = {
                                     "pickupLat": pickupLat,
                                     "pickupLng": pickupLng,
                                     "dropLat": dropLat,
                                     "dropLng": dropLng,
                                     "price": totalAmount,
                                     "pickupCompanyName": pickupcompany.text,
                                     "dropoffCompanyName": dropoffcompany.text,
                                     "itemType": itemType.text,
                                     "weight": double.tryParse(weight.text) ?? 0.0,
                                     "recipientName": dropoffusername.text,
                                     "recipientPhone": dropoffphone.text,
                                     "deliveryInstructions": instructions.text,
                                     "scheduledAt": scheduledAt?.toIso8601String(),
                                   };

                                   Navigator.push(
                                     context,
                                     MaterialPageRoute(
                                       builder: (context) => PaymentPage(
                                         orderData: orderData,
                                         amount: totalAmount,
                                       ),
                                     ),
                                   );
                                 } else {
                                   ScaffoldMessenger.of(context).showSnackBar(
                                     SnackBar(
                                       backgroundColor: Colors.red,
                                       content: Text(
                                         "Please Select Locations & Fill Details",
                                         style: AppWidget.whiteTextFieldStyle(20.0),
                                       ),
                                     ),
                                   );
                                 }
                               },
                              child: Container(
                                height: 60,
                                width: 170,
                                decoration: BoxDecoration(
                                  color: const Color(0xff6053f8),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Center(
                                  child: Text(
                                    "Place order",
                                    style: AppWidget.whiteTextFieldStyle(20.0),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 80.0),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showImageOptions() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Add Image',
              style: AppWidget.headlineTextFieldStyle(),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Color(0xff6053f8)),
              title: const Text('Take Photo'),
              subtitle: const Text('Capture image using camera'),
              onTap: () {
                Navigator.pop(context);
                _captureFromCamera();
              },
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.image, color: Color(0xff6053f8)),
              title: const Text('Choose from Gallery'),
              subtitle: const Text('Select image from your gallery'),
              onTap: () {
                Navigator.pop(context);
                _selectFromGallery();
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _captureFromCamera() {
    // TODO: Implement camera integration with image_picker package
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Camera capture starting...')),
    );

    // Mock implementation
    setState(() {
      _capturedImages.add('camera_image_${DateTime.now().millisecond}');
    });
  }

  void _selectFromGallery() {
    // TODO: Implement gallery selection with image_picker package
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Gallery access starting...')),
    );

    // Mock implementation
    setState(() {
      _capturedImages.add('gallery_image_${DateTime.now().millisecond}');
    });
  }
}
