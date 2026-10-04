import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// The brand-blue photo panel heading onboarding and login. The photos are
/// cut-outs; the blue is drawn here so it matches the theme exactly.
class AuthHero extends StatelessWidget {
  const AuthHero({required this.asset, required this.height, super.key});

  final String asset;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      color: AppColors.primary,
      child: Image.asset(
        asset,
        fit: BoxFit.cover,
        alignment: Alignment.topCenter,
        excludeFromSemantics: true,
      ),
    );
  }
}
