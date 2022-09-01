import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:inai_flutter_sdk/main.dart';

import '../../../contants.dart';

class ThemeColors {
  static const Color bgPurple = Color(0xff7673dd);
}

void debugPrint(String message) {
  if (kDebugMode) {
    print(message);
  }
}

typedef AlertFinishCallback = void Function();

void showAlert(BuildContext context, String message,
    {String title = "Alert", AlertFinishCallback? callback}) {
  // set up the button
  Widget okButton = TextButton(
    child: const Text("OK"),
    onPressed: () {
      Navigator.pop(context);
      if (callback != null) {
        callback();
      }
    },
  );

  // set up the AlertDialog
  AlertDialog alert = AlertDialog(
    title: Text(title),
    content: SingleChildScrollView(child: Text(message)),
    actions: [
      okButton,
    ],
  );

  // show the dialog
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return alert;
    },
  );
}

class PayWithSavedPaymentMethodFields extends StatelessWidget {
  PayWithSavedPaymentMethodFields(
      {Key? key, this.paymentMethod, required this.orderId})
      : super(key: key);

  final dynamic paymentMethod;
  final String orderId;

  final Map<String, dynamic> formData = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text("Payment"),
          backgroundColor: ThemeColors.bgPurple,
        ),
        body: SafeArea(
            child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: SingleChildScrollView(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                      ...<Widget>[
                        for (var formField
                            in paymentMethod["form_fields"] as List<dynamic>)
                          if (formField["name"] != "save_card")
                            renderFormField(formField)
                      ],
                      renderSubmitButton(context)
                    ])))));
  }

  Container renderSubmitButton(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 20.0),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          primary: ThemeColors.bgPurple,
          minimumSize: const Size.fromHeight(50), // NEW
        ),
        onPressed: () {
          submitPayment(context);
        },
        child: Text(
          "Pay with ${sanitizeRailCode(paymentMethod["rail_code"])}",
          style: const TextStyle(fontSize: 18),
        ),
      ),
    );
  }

  Container renderFormField(dynamic formField) {
    Map<String, dynamic> formFieldMap = formField as Map<String, dynamic>;
    String label = formField["label"];
    String key = formField["name"];
    String hint = "";

    if (formFieldMap.containsKey("placeholder")) {
      if (formFieldMap["placeholder"] != null) {
        hint = formField["placeholder"];
      }
    }

    String fieldType = formField["field_type"];

    int lines = 1;
    return Container(
      margin: const EdgeInsets.only(top: 15.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 16.0),
          ),
          if (fieldType == "checkbox")
            CheckboxFormField(onChangeCallback: (checked) {
              formData[key] = checked;
            })
          else
            Column(
              children: [
                const SizedBox(height: 10),
                TextFormField(
                    autocorrect: false,
                    initialValue: formData[key],
                    style: const TextStyle(fontSize: 16.0),
                    minLines: lines,
                    maxLines: lines,
                    decoration: InputDecoration(
                        border: const OutlineInputBorder(),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 10.0, vertical: 0),
                        hintText: hint),
                    onChanged: (text) {
                      formData[key] = text;
                    }),
              ],
            )
        ],
      ),
    );
  }

  void navigateBackToHome(BuildContext context) {
    Navigator.popUntil(context, (route) {
      if (route.isFirst) {
        return true;
      }
      return false;
    });
  }

  void submitPayment(BuildContext context) async {
    var result = await inaiMakePayment(context);

    String resultStr = result.data.toString();
    String resultTitle = "";
    switch (result.status) {
      case InaiStatus.success:
        resultTitle = "Pay with Saved Payment Method Success! ";
        break;
      case InaiStatus.failed:
        resultTitle = "Pay with Saved Payment Method Failed!";
        break;

      case InaiStatus.canceled:
        resultTitle = "Pay with Saved Payment Method Canceled!";
        break;
    }

    // ignore: use_build_context_synchronously
    showAlert(context, resultStr, title: resultTitle, callback: () {
      navigateBackToHome(context);
    });
  }

  Future<dynamic> inaiMakePayment(BuildContext context) async {
    try {
      InaiConfig config = InaiConfig(
          token: Constants.token,
          orderId: orderId,
          countryCode: Constants.country);

      InaiCheckout checkout = InaiCheckout(config);

      String railCode = paymentMethod["rail_code"];

      List<Map<String, dynamic>> paymentDetailFormFields = [];
      List<dynamic> paymentFields = paymentMethod["form_fields"];

      for (var paymentField in paymentFields) {
        String paymentFieldName = paymentField["name"];
        paymentDetailFormFields.add(
            {"name": paymentFieldName, "value": formData[paymentFieldName]});
      }

      Map<String, dynamic> paymentDetails = {
        "fields": paymentDetailFormFields,
        "paymentMethodId": paymentMethod["paymentMethodId"]
      };

      final result = await checkout.makePayment(
          paymentMethodOption: railCode,
          context: context,
          paymentDetails: paymentDetails);

      return result;
    } catch (ex) {
      //  Handle configuration errors here
    }
    return null;
  }

  String sanitizeRailCode(String railCode) {
    String cleanStr = railCode.replaceAll("_", " ");
    String capitalizedStr =
        "${cleanStr[0].toUpperCase()}${cleanStr.substring(1).toLowerCase()}";

    return capitalizedStr;
  }
}

typedef CheckboxOnChangeCallback = void Function(bool checked);

class CheckboxFormField extends StatefulWidget {
  const CheckboxFormField({Key? key, required this.onChangeCallback})
      : super(key: key);
  final CheckboxOnChangeCallback onChangeCallback;
  @override
  State<CheckboxFormField> createState() => CheckboxFormFieldState();
}

class CheckboxFormFieldState extends State<CheckboxFormField> {
  bool _isChecked = false;
  @override
  Widget build(BuildContext context) {
    return Checkbox(
        value: _isChecked,
        activeColor: ThemeColors.bgPurple,
        onChanged: (checked) {
          setState(() {
            _isChecked = checked!;
            widget.onChangeCallback(checked);
          });
        });
  }
}
