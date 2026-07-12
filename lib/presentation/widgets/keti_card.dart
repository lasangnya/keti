import 'package:flutter/material.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart' as shadcn;

class KetiCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool isSelected;
  final ValueChanged<bool?>? onSelected;

  final Widget? image;
  final bool showImage;
  final String? button1Text;
  final VoidCallback? onButton1Pressed;
  final String? button2Text;
  final VoidCallback? onButton2Pressed;
  final bool showButtons;

  const KetiCard({
    super.key,
    required this.title,
    required this.subtitle,
    this.isSelected = false,
    this.onSelected,
    this.image,
    this.showImage = false,
    this.button1Text,
    this.onButton1Pressed,
    this.button2Text,
    this.onButton2Pressed,
    this.showButtons = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      elevation: isSelected ? 4 : 0,
      // Highlight the border when selected (Material 3 style)
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isSelected ? colorScheme.primary : colorScheme.outlineVariant,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: shadcn.RadioGroup<bool>(
        value: isSelected,
        onChanged: (value) => onSelected?.call(value),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => onSelected?.call(!isSelected),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
              // Header: Radio + Title/Subtitle
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const shadcn.Radio(value: true),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                        Text(subtitle, style: theme.textTheme.bodySmall),
                      ],
                    ),
                  ),
                ],
              ),

              // Conditional Image
                if (showImage && image != null) ...[
                  const SizedBox(height: 16),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      width: double.infinity,
                      constraints: const BoxConstraints(maxHeight: 150),
                      child: image,
                    ),
                  ),
                ],

              // Conditional Buttons
                if (showButtons) ...[
                  const SizedBox(height: 16),
                  if (button1Text != null)
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.tonal(
                        onPressed: onButton1Pressed,
                        child: Text(button1Text!),
                      ),
                    ),
                  if (button1Text != null && button2Text != null)
                    const SizedBox(height: 8),
                  if (button2Text != null)
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.tonal(
                        onPressed: onButton2Pressed,
                        child: Text(button2Text!),
                      ),
                    ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}