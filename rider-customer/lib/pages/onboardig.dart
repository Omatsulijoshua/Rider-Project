import 'package:flutter/material.dart';
import 'package:rider/service/widget_support.dart';

class Onboarding extends StatefulWidget {
  const Onboarding({super.key});

  @override
  State<Onboarding> createState() => _OnboardingState();
}

class _OnboardingState extends State<Onboarding> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        margin: const EdgeInsets.only(top: 20.0),
        width: double.infinity,
        height: double.infinity,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset("images/fast-delivery.png"),
            const SizedBox(height: 50.0),
            Text(
              'Welcome to Rider',
              style: AppWidget.headlineTextFieldStyle(),
            ),
            const SizedBox(height: 15.0),
            Text(
              'Schedule a pickup and drop off,\nTrack your parcel from anywhere\nand check the progress of your deliveries.',
              textAlign: TextAlign.center,
              style: AppWidget.simpleTextFieldStyle(),
            ),
            const SizedBox(height: 30.0),
            Material(
              elevation: 3.0,
              borderRadius: BorderRadius.circular(40),
              child: Container(
                width: MediaQuery.of(context).size.width / 1.7,
                height: 70,
                decoration: BoxDecoration(
                  color: const Color(0xfff8ae39),
                  borderRadius: BorderRadius.circular(40),
                ),
                alignment: Alignment.center,
                child: Text(
                  'Track Now',
                  style: AppWidget.whiteTextFieldStyle(18.0),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }
}
