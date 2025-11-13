import 'package:flutter/material.dart';

Future<T?> showLmBottomSheet<T>(BuildContext context, {required Widget child}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).cardColor,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(ctx).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 12,
      ),
      child: child,
    ),
  );
}
