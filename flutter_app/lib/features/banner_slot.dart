import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:kitchen_prep_board/services/monetization_service.dart';

/// Android's anchored adaptive banner. The iOS release preparation script
/// replaces this file with an ad-free implementation before dependency
/// resolution, so Google Mobile Ads is not linked into the iOS binary.
class BannerSlot extends StatefulWidget {
  const BannerSlot({required this.service, super.key});

  final MonetizationService service;

  @override
  State<BannerSlot> createState() => _BannerSlotState();
}

class _BannerSlotState extends State<BannerSlot> {
  BannerAd? ad;
  bool loaded = false;
  int lastWidth = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final width = math.min(MediaQuery.sizeOf(context).width.floor(), 1024);
    if (width != lastWidth) {
      lastWidth = width;
      _load(width);
    }
  }

  Future<void> _load(int width) async {
    final unit = widget.service.bannerAdUnitId;
    final allowed = widget.service.canRequestAds && !widget.service.removeAds;
    if (!allowed || unit == null) return;
    final size =
        await AdSize.getCurrentOrientationAnchoredAdaptiveBannerAdSize(width);
    if (!mounted || size == null) return;
    await ad?.dispose();
    final next = BannerAd(
      adUnitId: unit,
      request: const AdRequest(nonPersonalizedAds: true),
      size: size,
      listener: BannerAdListener(
        onAdLoaded: (_) {
          if (mounted) setState(() => loaded = true);
        },
        onAdFailedToLoad: (failed, _) {
          failed.dispose();
          if (mounted) setState(() => loaded = false);
        },
      ),
    );
    ad = next;
    loaded = false;
    await next.load();
  }

  @override
  void dispose() {
    ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final current = ad;
    if (!loaded || current == null) {
      final reserved = MediaQuery.sizeOf(context).width >= 600 ? 90.0 : 60.0;
      return SizedBox(height: reserved);
    }
    return SizedBox(
      width: current.size.width.toDouble(),
      height: current.size.height.toDouble(),
      child: AdWidget(ad: current),
    );
  }
}
