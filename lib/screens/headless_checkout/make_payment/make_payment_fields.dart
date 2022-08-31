import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class ThemeColors {
  static const Color bgPurple = Color(0xff7673dd);
}

void debugPrint(String message) {
  if (kDebugMode) {
    print(message);
  }
}

void showAlert(BuildContext context, String message, {String title = "Alert"}) {
  // set up the button
  Widget okButton = TextButton(
    child: const Text("OK"),
    onPressed: () {
      Navigator.pop(context);
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
    builder: (BuildContext context) {
      return alert;
    },
  );
}

class MakePaymentFields extends StatelessWidget {
  MakePaymentFields({Key? key, this.paymentMethod}) : super(key: key);

  final dynamic paymentMethod;
  final Map<String, dynamic> formData = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title:
              Text("${sanitizeRailCode(paymentMethod["rail_code"])} Payment"),
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
                          renderFormField(formField)
                      ],
                      renderCheckoutButton(context)
                    ])))));
  }

  Container renderCheckoutButton(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 20.0),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          primary: ThemeColors.bgPurple,
          minimumSize: const Size.fromHeight(50), // NEW
        ),
        onPressed: () {
          debugPrint(formData.toString());
        },
        child: const Text(
          "Checkout",
          style: TextStyle(fontSize: 18),
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
        onChanged: (checked) {
          setState(() {
            _isChecked = checked!;
            debugPrint(checked.toString());
            widget.onChangeCallback(checked);
          });
        });
  }
}
