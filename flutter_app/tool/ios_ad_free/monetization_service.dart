import 'package:flutter/foundation.dart';

class StoreProduct {
  const StoreProduct({required this.price});

  final String price;
}

/// Paid-upfront iOS implementation. It intentionally has no dependency on
/// StoreKit or Google Mobile Ads.
class MonetizationService extends ChangeNotifier {
  StoreProduct? get product => null;
  bool removeAds = true;
  bool canRequestAds = false;
  bool privacyOptionsRequired = false;
  bool storeAvailable = false;
  bool initialized = false;

  String get productId => '';
  String? get bannerAdUnitId => null;

  Future<void> initialize() async {
    if (initialized) return;
    initialized = true;
    notifyListeners();
  }

  Future<void> refreshConsent() async {}
  Future<void> showPrivacyOptions() async {}
  Future<void> buyRemoveAds() async {}
  Future<void> restorePurchases() async {}
}
