import 'package:flutter/widgets.dart';
import 'package:kitchen_prep_board/services/monetization_service.dart';

/// The paid iOS app has no advertising surface or reserved ad space.
class BannerSlot extends StatelessWidget {
  const BannerSlot({required this.service, super.key});

  final MonetizationService service;

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
