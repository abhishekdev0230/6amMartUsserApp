// import 'package:razorpay_flutter/razorpay_flutter.dart';
// import 'package:flutter/material.dart';
//
// class RazorpayService {
//   late Razorpay _razorpay;
//
//   void init({
//     required double amount,
//     required String contactNumber,
//     required String guestId,
//     required String orderType,
//     required String digitalPaymentName,
//     required Function(PaymentSuccessResponse) onSuccess,
//     required Function(PaymentFailureResponse) onFailure,
//     required Function(ExternalWalletResponse) onExternalWallet,
//   }) {
//     _razorpay = Razorpay();
//     _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, onSuccess);
//     _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, onFailure);
//     _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, onExternalWallet);
//
//     var options = {
//       'key': 'rzp_test_YourKeyHere',
//       'amount': (amount * 100).toInt(), // Razorpay expects amount in paise
//       'name': 'Your App Name',
//       'description': orderType,
//       'prefill': {
//         'contact': contactNumber,
//         'email': '$guestId@example.com',
//       },
//       'external': {
//         'wallets': ['paytm']
//       }
//     };
//
//     try {
//       _razorpay.open(options);
//     } catch (e) {
//       debugPrint('Error: $e');
//     }
//   }
//
//   void dispose() {
//     _razorpay.clear();
//   }
// }
//
//
//
