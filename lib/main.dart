import 'package:flutter/material.dart';
import 'package:keti/theme/app_colors.dart';
import 'package:keti/theme/reminder_colors.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' as shadcn;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This is the start of the app
  @override
  Widget build(BuildContext context) {
    return shadcn.ShadcnApp(
      theme: shadcn.ThemeData(
        colorScheme: shadcn.ColorSchemes.lightZinc,
        radius: 0.5,
      ),
      home: Theme(
        data: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: AppColors.reminderAmber,
            surface: AppColors.background,
            onSurface: AppColors.primaryText,
            onSurfaceVariant: AppColors.secondaryText,
            outline: AppColors.border,
          ),
          extensions: [
            ReminderColors(
              blue: AppColors.reminderBlue,
              teal: AppColors.reminderTeal,
              sage: AppColors.reminderSage,
              darkAmber: AppColors.reminderDarkAmber,
              hotPink: AppColors.reminderHotPink,
              darkPink: AppColors.reminderDarkPink,
              caribbeanBlue: AppColors.reminderCaribbeanBlue,
            ),
          ],
        ),
        child: const ketiHomePage(title: 'Keti Home'),
      ),
    );
  }
}

class ketiHomePage extends StatefulWidget {
  const ketiHomePage({super.key, required this.title});

  final String title;

  @override
  State<ketiHomePage> createState() => _ketiHomePageState();
}

class _ketiHomePageState extends State<ketiHomePage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('You have pushed the button this many times:'),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }
}
