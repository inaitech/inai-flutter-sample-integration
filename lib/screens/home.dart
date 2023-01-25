import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sample_integration/screens/drop_in_checkout/drop_in_flows.dart';
import 'crypto/crypto_purchase_estimates.dart';
import 'headless_checkout/headless_checkout.dart';

class ThemeColors {
  static const Color bgPurple = Color(0xff7673dd);
}

// Add more flows here
const flows = {
  "HeadlessCheckout": "Headless Checkout",
  "DropInChekout": "Drop In Checkout",
  "Crypto": "Crypto"
};

class Home extends StatelessWidget {
  const Home({Key? key}) : super(key: key);

  void debugPrint(String message) {
    if (kDebugMode) {
      print(message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Home'),
          backgroundColor: ThemeColors.bgPurple,
        ),
        body: SafeArea(
            child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: SingleChildScrollView(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                      for (var key in flows.keys) FlowItem(flowItemKey: key)
                    ])))));
  }
}

class FlowItem extends StatelessWidget {
  const FlowItem({
    Key? key,
    required this.flowItemKey,
  }) : super(key: key);

  final String flowItemKey;

  void openFlow(String flowKey, BuildContext context) {
    switch (flowKey) {
      case "HeadlessCheckout":
        Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const HeadlessCheckout()));
        break;

      case "DropInChekout":
        Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const DropInFlows()));
        break;

      case "Crypto":
        Navigator.of(context).push(
          MaterialPageRoute(builder: (context) => const CryptoPurchaseEstimates()));
        break;
      //  Add more flows here
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          primary: ThemeColors.bgPurple,
          minimumSize: const Size.fromHeight(50), // NEW
        ),
        onPressed: () {
          openFlow(flowItemKey, context);
        },
        child: Text(
          flows[flowItemKey]!,
          style: const TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
