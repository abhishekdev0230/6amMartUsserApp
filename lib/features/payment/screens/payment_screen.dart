// import 'dart:async';
// import 'package:flutter/foundation.dart';
// import 'package:flutter/material.dart';
// import 'package:get/get.dart';
// import 'package:sixam_mart/features/splash/controllers/splash_controller.dart';
// import 'package:sixam_mart/features/order/controllers/order_controller.dart';
// import 'package:sixam_mart/features/order/domain/models/order_model.dart';
// import 'package:sixam_mart/features/location/domain/models/zone_response_model.dart';
// import 'package:sixam_mart/helper/address_helper.dart';
// import 'package:sixam_mart/util/app_constants.dart';
// import 'package:sixam_mart/util/dimensions.dart';
// import 'package:sixam_mart/common/widgets/custom_app_bar.dart';
// import 'package:flutter_inappwebview/flutter_inappwebview.dart';
// import 'package:sixam_mart/features/checkout/widgets/payment_failed_dialog.dart';
// import 'package:sixam_mart/features/wallet/widgets/fund_payment_dialog_widget.dart';
//
// class PaymentScreen extends StatefulWidget {
//   final OrderModel orderModel;
//   final bool isCashOnDelivery;
//   final String? addFundUrl;
//   final String paymentMethod;
//   final String guestId;
//   final String contactNumber;
//   final String? subscriptionUrl;
//   final int? storeId;
//   final bool createAccount;
//   final int? createUserId;
//   const PaymentScreen({super.key, required this.orderModel, required this.isCashOnDelivery, this.addFundUrl, required this.paymentMethod,
//     required this.guestId, required this.contactNumber, this.storeId, this.subscriptionUrl, this.createAccount = false, this.createUserId});
//
//   @override
//   PaymentScreenState createState() => PaymentScreenState();
// }
//
// class PaymentScreenState extends State<PaymentScreen> {
//   late String selectedUrl;
//   double value = 0.0;
//   final bool _isLoading = true;
//   PullToRefreshController? pullToRefreshController;
//   late MyInAppBrowser browser;
//   double? _maximumCodOrderAmount;
//
//   @override
//   void initState() {
//     super.initState();
//
//     if(widget.addFundUrl == '' && widget.addFundUrl!.isEmpty && widget.subscriptionUrl == '' && widget.subscriptionUrl!.isEmpty){
//       selectedUrl = '${AppConstants.baseUrl}/payment-mobile?customer_id=${widget.createAccount ? widget.createUserId : widget.orderModel.userId == 0 ? widget.guestId : widget.orderModel.userId}&order_id=${widget.orderModel.id}&payment_method=${widget.paymentMethod}';
//     } else if(widget.subscriptionUrl != '' && widget.subscriptionUrl!.isNotEmpty){
//       selectedUrl = widget.subscriptionUrl!;
//     } else{
//       selectedUrl = widget.addFundUrl!;
//     }
//
//     if (kDebugMode) {
//       print('==========url=======> $selectedUrl');
//     }
//
//     _initData();
//   }
//
//   void _initData() async {
//
//     if(widget.addFundUrl == '' && widget.addFundUrl!.isEmpty && widget.subscriptionUrl == '' && widget.subscriptionUrl!.isEmpty){
//       for(ZoneData zData in AddressHelper.getUserAddressFromSharedPref()!.zoneData!) {
//         for(Modules m in zData.modules!) {
//           if(m.id == Get.find<SplashController>().module!.id) {
//             _maximumCodOrderAmount = m.pivot!.maximumCodOrderAmount;
//             break;
//           }
//         }
//       }
//     }
//
//     browser = MyInAppBrowser(
//       orderID: widget.orderModel.id.toString(), orderType: widget.orderModel.orderType,
//       orderAmount: widget.orderModel.orderAmount, maxCodOrderAmount: _maximumCodOrderAmount,
//       isCashOnDelivery: widget.isCashOnDelivery, addFundUrl: widget.addFundUrl,
//       contactNumber: widget.contactNumber, storeId: widget.storeId,
//       subscriptionUrl: widget.subscriptionUrl, createAccount: widget.createAccount,
//       guestId: widget.guestId,
//     );
//
//     if(GetPlatform.isAndroid){
//       await InAppWebViewController.setWebContentsDebuggingEnabled(kDebugMode);
//
//       bool swAvailable = await WebViewFeature.isFeatureSupported(WebViewFeature.SERVICE_WORKER_BASIC_USAGE);
//       bool swInterceptAvailable = await WebViewFeature.isFeatureSupported(WebViewFeature.SERVICE_WORKER_SHOULD_INTERCEPT_REQUEST);
//
//       if (swAvailable && swInterceptAvailable) {
//         ServiceWorkerController serviceWorkerController = ServiceWorkerController.instance();
//         await serviceWorkerController.setServiceWorkerClient(ServiceWorkerClient(
//           shouldInterceptRequest: (request) async {
//             if (kDebugMode) {
//               print(request);
//             }
//             return null;
//           },
//         ));
//       }
//     }
//
//     await browser.openUrlRequest(
//       urlRequest: URLRequest(url: WebUri(selectedUrl)),
//       settings: InAppBrowserClassSettings(
//         webViewSettings: InAppWebViewSettings(useShouldOverrideUrlLoading: true, useOnLoadResource: true),
//         browserSettings: InAppBrowserSettings(hideUrlBar: true, hideToolbarTop: GetPlatform.isAndroid),
//       ),
//     );
//
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return PopScope(
//       canPop: false,
//       onPopInvokedWithResult: (didPop, result) {
//         _exitApp().then((value) => value!);
//       },
//       child: Scaffold(
//         backgroundColor: Theme.of(context).primaryColor,
//         appBar: CustomAppBar(title: 'payment'.tr, onBackPressed: () => _exitApp()),
//         body: Center(
//           child: SizedBox(
//             width: Dimensions.webMaxWidth,
//             child: Stack(
//               children: [
//                 _isLoading ? Center(
//                   child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).primaryColor)),
//                 ) : const SizedBox.shrink(),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
//
//   Future<bool?> _exitApp() async {
//     if((widget.addFundUrl == null || widget.addFundUrl!.isEmpty) && (widget.subscriptionUrl == '' && widget.subscriptionUrl!.isEmpty)){
//       return Get.dialog(PaymentFailedDialog(
//         orderID: widget.orderModel.id.toString(), orderAmount: widget.orderModel.orderAmount,
//         maxCodOrderAmount: _maximumCodOrderAmount, orderType: widget.orderModel.orderType,
//         isCashOnDelivery: widget.isCashOnDelivery, guestId: widget.createAccount ? widget.createUserId.toString() : widget.guestId,
//       ));
//     } else{
//       return Get.dialog(FundPaymentDialogWidget(isSubscription: widget.subscriptionUrl != null && widget.subscriptionUrl!.isNotEmpty));
//     }
//   }
//
// }
//
// class MyInAppBrowser extends InAppBrowser {
//   final String orderID;
//   final String? orderType;
//   final double? orderAmount;
//   final double? maxCodOrderAmount;
//   final bool isCashOnDelivery;
//   final String? addFundUrl;
//   final String? subscriptionUrl;
//   final String? contactNumber;
//   final int? storeId;
//   final bool createAccount;
//   final String guestId;
//
//   MyInAppBrowser({
//     super.windowId, super.initialUserScripts,
//     required this.orderID, required this.orderType, required this.orderAmount,
//     required this.maxCodOrderAmount, required this.isCashOnDelivery,
//     this.addFundUrl, this.subscriptionUrl, this.contactNumber, this.storeId,
//     required this.createAccount, required this.guestId});
//
//   final bool _canRedirect = true;
//
//   @override
//   Future onBrowserCreated() async {
//     if (kDebugMode) {
//       print("\n\nBrowser Created!\n\n");
//     }
//   }
//
//   @override
//   Future onLoadStart(url) async {
//     if (kDebugMode) {
//       print("\n\nStarted: $url\n\n");
//     }
//     Get.find<OrderController>().paymentRedirect(
//       url: url.toString(), canRedirect: _canRedirect, onClose: () => close(),
//       addFundUrl: addFundUrl, orderID: orderID, contactNumber: contactNumber, storeId: storeId,
//       subscriptionUrl: subscriptionUrl, createAccount: createAccount, guestId: guestId,
//     );
//
//   }
//
//
//   @override
//   Future onLoadStop(url) async {
//     pullToRefreshController?.endRefreshing();
//     if (kDebugMode) {
//       print("\n\nStopped: $url\n\n");
//     }
//     Get.find<OrderController>().paymentRedirect(
//       url: url.toString(), canRedirect: _canRedirect, onClose: () => close(),
//       addFundUrl: addFundUrl, orderID: orderID, contactNumber: contactNumber, storeId: storeId,
//       subscriptionUrl: subscriptionUrl, createAccount: createAccount, guestId: guestId,
//     );
//   }
//
//   // @override
//   // Future<ServerTrustAuthResponse?>? onReceivedServerTrustAuthRequest(URLAuthenticationChallenge challenge) async {
//   //   if (kDebugMode) {
//   //     print("\n\n onReceivedServerTrustAuthRequest: ${challenge.toString()}\n\n");
//   //   }
//   //   return ServerTrustAuthResponse(action: ServerTrustAuthResponseAction.PROCEED);
//   // }
//   //
//   // @override
//   // Future<ShouldAllowDeprecatedTLSAction?>? shouldAllowDeprecatedTLS(URLAuthenticationChallenge challenge) async {
//   //   if (kDebugMode) {
//   //     print("\n\n shouldAllowDeprecatedTLS: ${challenge.protectionSpace.host}\n\n");
//   //   }
//   //   return ShouldAllowDeprecatedTLSAction.ALLOW;
//   // }
//
//   @override
//   void onLoadError(url, code, message) {
//     pullToRefreshController?.endRefreshing();
//     if (kDebugMode) {
//       print("Can't load [$url] Error: $message");
//     }
//   }
//
//   @override
//   void onProgressChanged(progress) {
//     if (progress == 100) {
//       pullToRefreshController?.endRefreshing();
//     }
//     if (kDebugMode) {
//       print("Progress: $progress");
//     }
//   }
//
//   @override
//   void onExit() {
//     if (kDebugMode) {
//       print("\n\nBrowser closed!\n\n");
//     }
//   }
//
//   @override
//   Future<NavigationActionPolicy> shouldOverrideUrlLoading(navigationAction) async {
//     if (kDebugMode) {
//       print("\n\nOverride ${navigationAction.request.url}\n\n");
//     }
//     return NavigationActionPolicy.ALLOW;
//   }
//
//   @override
//   void onLoadResource(resource) {
//     if (kDebugMode) {
//       print("Started at: ${resource.startTime}ms ---> duration: ${resource.duration}ms ${resource.url ?? ''}");
//     }
//   }
//
//   @override
//   void onConsoleMessage(consoleMessage) {
//     if (kDebugMode) {
//       print("""
//     console output:
//       message: ${consoleMessage.message}
//       messageLevel: ${consoleMessage.messageLevel.toValue()}
//    """);
//     }
//   }
//
//
// }



///........newadd...Abhishek....sdk....razorPay...................

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:sixam_mart/util/app_constants.dart';
import 'package:sixam_mart/util/dimensions.dart';
import 'package:sixam_mart/common/widgets/custom_app_bar.dart';
import 'package:sixam_mart/features/checkout/widgets/payment_failed_dialog.dart';

class PaymentScreen extends StatefulWidget {
  final int orderId;
  final int userId;
  final String orderType;
  final double amount;
  final bool isCashOnDelivery;
  final String? digitalPaymentName;
  final String? guestId;
  final String? contactNumber;

  const PaymentScreen({
    Key? key,
    required this.orderId,
    required this.userId,
    required this.orderType,
    required this.amount,
    required this.isCashOnDelivery,
    this.digitalPaymentName,
    this.guestId,
    this.contactNumber,
  }) : super(key: key);

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  late Razorpay _razorpay;

  @override
  void initState() {
    super.initState();

    _razorpay = Razorpay();
    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess);
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError);
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);

    _startPayment();
  }

  void _startPayment() {
    var options = {
      'key': AppConstants.razorpayKey,
      'amount': (widget.amount * 100).toInt(),
      'name': 'SixamMart',
      'description': widget.orderType,
      'prefill': {
        'contact': widget.contactNumber ?? '',
        'email': '${widget.guestId ?? 'guest'}@example.com',
      },
      'external': {
        'wallets': ['paytm']
      }
    };

    try {
      _razorpay.open(options);
    } catch (e) {
      debugPrint('Razorpay open error: $e');
    }
  }


  void _handlePaymentSuccess(PaymentSuccessResponse response) {
    debugPrint('Payment success: ${response.paymentId}');
    // TODO: Call API to confirm order here, then redirect to success page
    Get.back();
    Get.back();
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    debugPrint('Payment failed: ${response.message}');
    Get.dialog(PaymentFailedDialog(
      orderID: widget.orderId.toString(),
      orderAmount: widget.amount,
      orderType: widget.orderType,
      maxCodOrderAmount: null,
      isCashOnDelivery: widget.isCashOnDelivery,
      guestId: widget.guestId.toString(),
    ));
  }


  void _handleExternalWallet(ExternalWalletResponse response) {
    debugPrint('External Wallet: ${response.walletName}');
    // Optional: Show a message or handle differently
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: 'payment'.tr, onBackPressed: () => Get.back()),
      body: Center(
        child: SizedBox(
          width: Dimensions.webMaxWidth,
          child: const Center(
            child: CircularProgressIndicator(),
          ),
        ),
      ),
    );
  }
}
