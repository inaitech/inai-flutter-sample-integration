import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_sample_integration/screens/headless_checkout/make_payment/make_payment.dart';

class ThemeColors {
  static const Color bgPurple = Color(0xff7673dd);
}

class Product extends StatelessWidget {
  const Product({Key? key}) : super(key: key);

  void debugPrint(String message) {
    if (kDebugMode) {
      print(message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Product'),
        backgroundColor: ThemeColors.bgPurple,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
            child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 15.0),
              child: const Image(
                image: AssetImage('assets/inai-white.png'),
                height: 50,
              ),
            ),
            Container(
              margin: const EdgeInsets.only(top: 15.0),
              height: 200,
              child: const Image(
                image: AssetImage('assets/tshirt.jpeg'),
              ),
            ),
            Container(
                margin: const EdgeInsets.only(top: 15.0),
                height: 20,
                child: const Text("MANCHESTER UNITED 21/22 HOME JERSEY")),
            Expanded(
              child: Container(
                margin: const EdgeInsets.only(top: 15.0),
                child: const SingleChildScrollView(
                  scrollDirection: Axis.vertical,
                  child: Text('''A FAN JERSEY INSPIRED BY A LEGENDARY HOME KIT.
Youth. Courage. Success. The thee pillars of Manchester United's motto have brought the club more than a century of triumphs. With its clean red design and white ribbed crewneck, this juniors' adidas football jersey takes inspiration from the iconic kit that carried them to some of their most memorable moments. Made for fans, its soft fabric and moisture-absorbing AEROREADY keep you comfortable. A devil signoff on the back shows your pride.
This product is made with Primegreen, a series of high-performance recycled materials.'''),
                ),
              ),
            ),
            Container(
              height: 40,
              margin: const EdgeInsets.only(top: 15.0, bottom: 20),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  primary: ThemeColors.bgPurple,
                  minimumSize: const Size.fromHeight(50), // NEW
                ),
                onPressed: () {
                  Navigator.of(context).push(MaterialPageRoute(
                      builder: (context) => const MakePayment()));
                },
                child: const Text('Buy Now'),
              ),
            )
          ],
        )),
      ),
    );
  }
}
