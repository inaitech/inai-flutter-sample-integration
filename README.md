# inai-flutter-sample-integration

## Overview

This repository demonstrates how to use the Inai SDK in your Flutter Project.
  
## Features

### Headless Checkout

- Make a payment with variety of payment methods
File : [make_payment.dart]()

- Save a payment method
   File : [SavePaymentMethod.js]()

- Pay with Saved Payment Method
File : [pay_with_saved_payment_method.dart]()

- Validate Fields
File : [validate_fields.dart]()

- Get Card Info
File : [get_card_info.dart ]()

### Drop In Checkout
- Make a payment using Inai's Checkout Interface
File: [drop_in_checkout.dart]()

## Prerequisites

- To begin, you will require the client username and client password values. Instructions to get this can be found [here](https://docs.inai.io/docs/getting-started)

- Make sure the following steps are completed in the merchant dashboard,

- [Adding a Provider](https://docs.inai.io/docs/adding-a-payment-processor)

- [Adding Payment Methods](https://docs.inai.io/docs/adding-a-payment-method)

- [Customizing Checkout](https://docs.inai.io/docs/customizing-your-checkout)


### Minimum Requirements

Flutter SDK: 2.15.1
Flutter: 1.17.0"


## Setup
  
To start the backend NodeJS server:

1. Navigate to the ./server folder at the root level.

2. Run command `npm install` to install the dependency packages.

3. Add a new .env file the following variables:

1. client_username

2. client_password

4. Run command `npm start` to start the nodejs backend server


To setup the inai sample app for Flutter, follow the steps below:

1.  `git clone https://github.com/inaitech/inai-flutter-sample-integration`

2. Navigate to ./constants.dart file and update the following values :

- Client Username

- Client Password

- Country

- Amount // for order creation

- Currency // for order creation

- Base URL // backend api server url eg: http://localhost:5009

3. Run command `flutter doctor` to make sure your dev environment is setup correctly.

4. At the root level of the repo run command `flutter run` and select the configured Android / IOS Device/Simulator 
Note: It is a good practice to start the emulator beforehand or a device connected.

## FAQs

<TBA>

## Support

If you found a bug or want to suggest a new [feature/use case/sample], please contact **[customer support](mailto:support@inai.io)**.