import 'package:flutter/material.dart';
import 'package:lamaplay/core/theme/colors.dart';

abstract class _BaseButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final Color bg;
  final Color fg;
  const _BaseButton({
    required this.label,
    required this.onPressed,
    required this.bg,
    required this.fg,
    this.loading = false,
    super.key,
  });
  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: loading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: bg,
        foregroundColor: fg,
        shape: const StadiumBorder(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      ),
      child: loading
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Text(label),
    );
  }
}

class PrimaryButton extends _BaseButton {
  const PrimaryButton({
    super.key,
    required String label,
    VoidCallback? onPressed,
    bool loading = false,
  }) : super(
         label: label,
         onPressed: onPressed,
         bg: LmColors.primary,
         fg: Colors.black,
         loading: loading,
       );
}

class SecondaryButton extends _BaseButton {
  const SecondaryButton({
    super.key,
    required String label,
    VoidCallback? onPressed,
    bool loading = false,
  }) : super(
         label: label,
         onPressed: onPressed,
         bg: LmColors.secondary,
         fg: Colors.white,
         loading: loading,
       );
}

class TertiaryGhostButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  const TertiaryGhostButton({super.key, required this.label, this.onPressed});
  @override
  Widget build(BuildContext context) {
    return TextButton(onPressed: onPressed, child: Text(label));
  }
}
