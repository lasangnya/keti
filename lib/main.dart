import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:keti/application/theme/theme_provider.dart';
import 'package:keti/presentation/pages/home/home_page.dart';

void main() {
  runApp(const ProviderScope(child: KetiApp()));
}

class KetiApp extends ConsumerWidget {
  const KetiApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(appThemeProvider);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: theme,
      home: const KetiHomePage(),
    );
  }
}
