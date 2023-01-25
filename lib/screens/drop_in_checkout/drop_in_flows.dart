import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_sample_integration/screens/drop_in_checkout/add_payment_method/add_payment_method.dart';
import 'package:flutter_sample_integration/screens/drop_in_checkout/checkout/checkout.dart';
import 'package:flutter_sample_integration/screens/drop_in_checkout/pay_with_payment_method/pay_with_payment_method.dart';

class ThemeColors {
  static const Color bgPurple = Color(0xff7673dd);
}

// Add more flows here
var flows = {
  "DropInCheckout": "Checkout",
  "AddPaymentMethod": "Add Payment Method",
  "PayWithPaymentMethod": "Pay With Payment Method"
};

class DropInFlows extends StatelessWidget {
  const DropInFlows({Key? key}) : super(key: key);

  void debugPrint(String message) {
    if (kDebugMode) {
      print(message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Checkout'),
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
      case "DropInCheckout":
        Navigator.of(context).push(MaterialPageRoute(
            builder: (context) => const Checkout()));
        break;

      case "AddPaymentMethod":
        Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const AddPaymentMethod()));
        break;

      case "PayWithPaymentMethod":
        Navigator.of(context).push(MaterialPageRoute(
            builder: (context) => const PayWithPaymentMethod()));
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
