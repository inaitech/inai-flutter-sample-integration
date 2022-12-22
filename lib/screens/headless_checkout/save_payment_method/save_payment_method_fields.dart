import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:inai_flutter_sdk/inai_flutter_sdk.dart';

import '../../../contants.dart';

class ThemeColors {
  static const Color bgPurple = Color(0xff7673dd);
  static const Color errorRed = Colors.red;
  static const Color normal = Colors.grey;
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

class SavePaymentMethodFields extends StatelessWidget {
  SavePaymentMethodFields({Key? key, this.paymentMethod, required this.orderId})
      : super(key: key);

  final dynamic paymentMethod;
  final String orderId;

  final Map<String, dynamic> formData = {};
  final Map<String, dynamic> formValidationTracker = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(
              "Save ${sanitizeRailCode(paymentMethod["rail_code"])} Payment Method"),
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
                      renderSaveButton(context)
                    ])))));
  }

  Container renderSaveButton(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 20.0),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          primary: ThemeColors.bgPurple,
          minimumSize: const Size.fromHeight(50), // NEW
        ),
        onPressed: () {
          if (validateForm()) {
            submitPayment(context);
          } else {
            showAlert(context, "Please enter valid details");
          }
        },
        child: const Text(
          "Save",
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
          else if (fieldType == "select")
            Column(
              children: [
                const SizedBox(height: 10),
                CountrySelector(
                    formFieldMap: formFieldMap,
                    onChangeCallback: (text, fieldValidation) {
                      formData[key] = text;
                      formValidationTracker.addEntries(fieldValidation.entries);
                    })
              ],
            )
          else
            Column(
              children: [
                const SizedBox(height: 10),
                TextBoxFormField(
                  formFieldMap: formFieldMap,
                  onChangeCallback: (text, fieldValidation) {
                    formData[key] = text;
                    formValidationTracker.addEntries(fieldValidation.entries);
                  },
                )
              ],
            )
        ],
      ),
    );
  }

  void navigateBackToHome(BuildContext context) {
    Navigator.popUntil(context, (route) {
      return route.isFirst;
    });
  }

  bool validateForm() {
    var areFormInputsValid = true;
    var areRequiredInputsFilled = true;
    formValidationTracker.entries.forEach((fieldValidation) {
      if (fieldValidation.value["isNonEmpty"] == false) {
        areRequiredInputsFilled = false;
      }

      if (fieldValidation.value["isValid"] == false) {
        areFormInputsValid = false;
      }
    });

    return areRequiredInputsFilled && areFormInputsValid;
  }

  void submitPayment(BuildContext context) async {
    var result = await inaiMakePayment(context);

    String resultStr = result.data.toString();
    String resultTitle = "";
    switch (result.status) {
      case InaiStatus.success:
        resultTitle = "Save Payment Method Success! ";
        break;
      case InaiStatus.failed:
        resultTitle = "Save Payment Method Failed!";
        break;

      case InaiStatus.canceled:
        resultTitle = "Save Payment Method Canceled!";
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
        if (paymentFieldName != "save_card") {
          paymentDetailFormFields.add(
              {"name": paymentFieldName, "value": formData[paymentFieldName]});
        }
      }

      //  For save
      paymentDetailFormFields.add({"name": "save_card", "value": true});

      Map<String, dynamic> paymentDetails = {"fields": paymentDetailFormFields};

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

typedef TextboxOnChangeCallback = void Function(
    String text, Map<String, dynamic> fieldValidation);

class CountrySelector extends StatefulWidget {
  const CountrySelector(
      {Key? key, required this.formFieldMap, required this.onChangeCallback})
      : super(key: key);

  final Map<String, dynamic> formFieldMap;
  final TextboxOnChangeCallback onChangeCallback;

  @override
  State<CountrySelector> createState() => _CountrySelectorState();
}

class _CountrySelectorState extends State<CountrySelector> {
  late String key;
  late bool required;
  late List<dynamic> countries;
  late String dropDownValue;
  late Map<String, dynamic>? fieldValidationTracker;

  @override
  void initState() {
    super.initState();
    key = widget.formFieldMap["name"];
    countries = [];
    countries.addAll(widget.formFieldMap["data"]["values"]);
    dropDownValue = countries.first["label"];
    fieldValidationTracker = {
      key: {"isNonEmpty": false, "isValid": false}
    };
  }

  @override
  Widget build(BuildContext context) {
    return DropdownButton(
      value: dropDownValue,
      items: countries
          .map((countryData) => DropdownMenuItem(
                value: countryData["label"],
                child: Text(countryData["label"]),
              ))
          .toList(),
      onChanged: (country) {
        setState(() {
          dropDownValue = country as String;
          fieldValidationTracker![key]["isNonEmpty"] = true;
          fieldValidationTracker![key]["isValid"] = true;
        });
        var countryValue = countries.firstWhere(
            (countryData) => countryData["label"] == country)["value"];
        widget.onChangeCallback(countryValue, fieldValidationTracker!);
      },
    );
  }
}

class TextBoxFormField extends StatefulWidget {
  const TextBoxFormField(
      {Key? key, required this.formFieldMap, required this.onChangeCallback})
      : super(key: key);
  final Map<String, dynamic> formFieldMap;
  final TextboxOnChangeCallback onChangeCallback;

  @override
  State<TextBoxFormField> createState() => _TextBoxFormFieldState();
}

class _TextBoxFormFieldState extends State<TextBoxFormField> {
  late String key;
  late String hint;
  late int maxLength;
  late int minLength;
  late String inputRegex;
  late bool required;
  late Color _borderColor;
  late Map<String, dynamic> validations;
  late Map<String, dynamic>? fieldValidationTracker;

  final _controller = TextEditingController();
  String cardExpiry = "";

  @override
  void initState() {
    super.initState();
    _borderColor = ThemeColors.normal;
    key = widget.formFieldMap["name"];

    if (widget.formFieldMap.containsKey("placeholder")) {
      if (widget.formFieldMap["placeholder"] != null) {
        hint = widget.formFieldMap["placeholder"];
      }
    }

    validations =
        widget.formFieldMap["validations"] as Map<String, dynamic>? ?? {};
    minLength = validations["min_length"] as int? ?? 0;
    maxLength = validations["max_length"] as int? ?? 0;
    inputRegex = validations["input_mask_regex"] as String? ?? '.*';
    required = validations["required"] as bool? ?? false;
    fieldValidationTracker = {
      key: {"isNonEmpty": false, "isValid": false}
    };
  }

  Color getBorderColor() {
    // at any time, we can get the text from _controller.value.text
    final text = _controller.value.text;

    if (validate(text)) {
      // return null if the text is valid
      return ThemeColors.normal;
    } else {
      return ThemeColors.errorRed;
    }
  }

  bool validate(String text) {
    //  Check for empty text
    if (required && text.isEmpty) {
      fieldValidationTracker![key]["isNonEmpty"] = false;
      return false;
    }

    //  Check if length constraints are satisfied
    if (minLength != 0 && maxLength != 0) {
      if (text.length < minLength || text.length > maxLength) {
        fieldValidationTracker![key]["isValid"] = false;
        return false;
      }
    }

    //  Match input text with pattern
    RegExp regex = RegExp(inputRegex);
    Iterable matches = regex.allMatches(text);
    if (matches.isEmpty) {
      fieldValidationTracker![key]["isValid"] = false;
      return false;
    }

    // Valid Input
    fieldValidationTracker![key]["isNonEmpty"] = true;
    fieldValidationTracker![key]["isValid"] = true;
    return true;
  }

  String formattedCardExpiry(String expiryDate) {
    var formattedExpiryDate = "";
    // Check necessary so that we format fresh inputs and not the same string.
    //  because once we set the  TextInput with formatted string onChangeText will be
    //  triggered again for the formatted string.
    if (expiryDate != cardExpiry) {
      //  Append a slash if length is 2 and slash is not yet added.
      if (expiryDate.length == 2 && !cardExpiry.endsWith('/')) {
        formattedExpiryDate = "$expiryDate/";
      }
      //  This case handles a delete operation.
      //  For Ex. InputText = 12 and formattedExpiryDate = 12/ then a delete
      //  operation deletes the 2 along with the slash.
      else if (expiryDate.length == 2 && cardExpiry.endsWith('/')) {
        //  Valid month check
        if (int.parse(expiryDate) <= 12) {
          formattedExpiryDate = expiryDate.substring(0, 1);
        } else {
          formattedExpiryDate = '';
        }
      }
      //  If input is the first character and its above 1 (for ex: 5)
      //  then we assume its the 5th month and format it as 05
      else if (expiryDate.length == 1) {
        if (int.parse(expiryDate) > 1) {
          formattedExpiryDate = "0$expiryDate/";
        } else {
          formattedExpiryDate = expiryDate;
        }
      } else {
        formattedExpiryDate = expiryDate;
      }
    }

    cardExpiry = formattedExpiryDate;
    return formattedExpiryDate;
  }

  @override
  Widget build(BuildContext context) {
    return TextFormField(
        autocorrect: false,
        style: const TextStyle(fontSize: 16.0),
        minLines: 1,
        maxLines: 1,
        controller: _controller,
        decoration: InputDecoration(
            focusedBorder:
                OutlineInputBorder(borderSide: BorderSide(color: _borderColor)),
            enabledBorder:
                OutlineInputBorder(borderSide: BorderSide(color: _borderColor)),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 10.0, vertical: 0),
            hintText: hint),
        onChanged: (text) {
          setState(() {
            if (key == "expiry") {
              _controller.text = formattedCardExpiry(text);
              _controller.selection =
                  TextSelection.collapsed(offset: _controller.text.length);
            }
            _borderColor = getBorderColor();
          });
          widget.onChangeCallback(text, fieldValidationTracker!);
        });
  }
}
