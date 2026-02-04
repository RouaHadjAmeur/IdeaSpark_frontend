import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ideaspark/view_models/locale_view_model.dart';

/// Rebuilds when [LocaleViewModel] notifies (e.g. language change) and rebuilds [builder]'s result.
/// Wrap each route's content with this so the UI updates immediately without restart.
class LocaleRebuilder extends StatelessWidget {
  const LocaleRebuilder({super.key, required this.builder});

  final Widget Function(BuildContext context) builder;

  @override
  Widget build(BuildContext context) {
    context.watch<LocaleViewModel>();
    return builder(context);
  }
}
