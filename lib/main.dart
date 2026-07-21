import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:keti/application/theme/theme_provider.dart';
import 'package:keti/application/user_activity/user_activity_provider.dart';
import 'package:keti/presentation/pages/home/home_page.dart';

void main() {
  runApp(const ProviderScope(child: KetiApp()));
}

class KetiApp extends ConsumerStatefulWidget {
  const KetiApp({super.key});

  @override
  ConsumerState<KetiApp> createState() => _KetiAppState();
}

class _KetiAppState extends ConsumerState<KetiApp> {
  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_handleKeyEvent);
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_handleKeyEvent);
    super.dispose();
  }

  bool _handleKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent) {
      ref.read(userActivityProvider.notifier).logKeyboardStroke(
            event.logicalKey.debugName ?? 'Unknown Key',
          );
    }
    return false; // Allow event to propagate
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(appThemeProvider);

    return Listener(
      onPointerMove: (_) => ref.read(userActivityProvider.notifier).logMouseMovement(),
      onPointerDown: (_) => ref.read(userActivityProvider.notifier).logMouseClick(),
      onPointerSignal: (signal) {
        if (signal is PointerScrollEvent) {
          ref.read(userActivityProvider.notifier).logMouseScroll();
        }
      },
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: theme,
        home: const KetiHomePage(),
      ),
    );
  }
}
