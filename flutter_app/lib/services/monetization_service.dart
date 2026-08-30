import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

class MonetizationService extends ChangeNotifier {
  static const _configuredProductId = String.fromEnvironment('REMOVE_ADS_PRODUCT_ID');
  static const _configuredBannerId = String.fromEnvironment('BANNER_AD_UNIT_ID');
  static const _useTestAds = bool.fromEnvironment('USE_TEST_ADS', defaultValue: true);

  InAppPurchase? _iap;
  StreamSubscription<List<PurchaseDetails>>? _purchaseSubscription;
  ProductDetails? product;
  bool removeAds = false;
  bool canRequestAds = false;
  bool privacyOptionsRequired = false;
  bool storeAvailable = false;
  bool initialized = false;

  InAppPurchase get _store => _iap ??= InAppPurchase.instance;

  String get productId => _configuredProductId;

  String? get bannerAdUnitId {
    if (_useTestAds) {
      if (Platform.isAndroid) return 'ca-app-pub-3940256099942544/9214589741';
      if (Platform.isIOS) return 'ca-app-pub-3940256099942544/2435281174';
    }
    return _configuredBannerId.isEmpty ? null : _configuredBannerId;
  }

  Future<void> initialize() async {
    if (initialized) return;
    _purchaseSubscription = _store.purchaseStream.listen(
      _handlePurchases,
      onError: (_) {},
    );
    storeAvailable = await _store.isAvailable();
    if (storeAvailable && productId.isNotEmpty) {
      final response = await _store.queryProductDetails({productId});
      if (response.productDetails.isNotEmpty) {
        product = response.productDetails.first;
      }
      // Reconcile from the store every launch. Entitlement is deliberately not
      // trusted from local storage, so an expired subscription cannot suppress ads.
      await _store.restorePurchases();
    }
    await refreshConsent();
    initialized = true;
    notifyListeners();
  }

  Future<void> refreshConsent() async {
    final completer = Completer<void>();
    ConsentInformation.instance.requestConsentInfoUpdate(
      ConsentRequestParameters(),
      () {
        ConsentForm.loadAndShowConsentFormIfRequired((_) async {
          canRequestAds = await ConsentInformation.instance.canRequestAds();
          privacyOptionsRequired = await ConsentInformation.instance
                  .getPrivacyOptionsRequirementStatus() ==
              PrivacyOptionsRequirementStatus.required;
          if (canRequestAds && !removeAds) {
            await MobileAds.instance.initialize();
          }
          if (!completer.isCompleted) completer.complete();
          notifyListeners();
        });
      },
      (_) async {
        canRequestAds = await ConsentInformation.instance.canRequestAds();
        if (canRequestAds && !removeAds) await MobileAds.instance.initialize();
        if (!completer.isCompleted) completer.complete();
        notifyListeners();
      },
    );
    await completer.future.timeout(
      const Duration(seconds: 12),
      onTimeout: () {},
    );
  }

  Future<void> showPrivacyOptions() async {
    final completer = Completer<void>();
    ConsentForm.showPrivacyOptionsForm((_) {
      if (!completer.isCompleted) completer.complete();
    });
    await completer.future;
    canRequestAds = await ConsentInformation.instance.canRequestAds();
    notifyListeners();
  }

  Future<void> buyRemoveAds() async {
    final details = product;
    if (!storeAvailable || details == null) return;
    await _store.buyNonConsumable(
      purchaseParam: PurchaseParam(productDetails: details),
    );
  }

  Future<void> restorePurchases() async {
    if (storeAvailable) await _store.restorePurchases();
  }

  Future<void> _handlePurchases(List<PurchaseDetails> purchases) async {
    var sawConfiguredProduct = false;
    var entitlement = removeAds;
    for (final purchase in purchases) {
      if (purchase.productID == productId) {
        sawConfiguredProduct = true;
        entitlement = purchase.status == PurchaseStatus.purchased ||
            purchase.status == PurchaseStatus.restored;
      }
      if (purchase.pendingCompletePurchase) {
        await _store.completePurchase(purchase);
      }
    }
    if (sawConfiguredProduct && entitlement != removeAds) {
      removeAds = entitlement;
      notifyListeners();
    }
  }

  Future<BannerAd?> createBanner({required int width}) async {
    final unit = bannerAdUnitId;
    if (removeAds || !canRequestAds || unit == null) return null;
    final size = await AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(width);
    if (size == null) return null;
    return BannerAd(
      adUnitId: unit,
      request: const AdRequest(nonPersonalizedAds: true),
      size: size,
      listener: BannerAdListener(),
    );
  }

  @override
  void dispose() {
    _purchaseSubscription?.cancel();
    super.dispose();
  }
}
