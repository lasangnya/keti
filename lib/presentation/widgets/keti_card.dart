import 'package:flutter/material.dart';

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
  final bool showRadio;
  final bool enabled;

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
    this.showRadio = true,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Opacity(
      opacity: enabled ? 1.0 : 0.5,
      child: Card(
        elevation: isSelected ? 4 : 0,
        // Highlight the border when selected (Material 3 style)
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: isSelected ? colorScheme.primary : colorScheme.outlineVariant,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: enabled ? () => onSelected?.call(!isSelected) : null,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header: Radio (Optional) + Title/Subtitle
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (showRadio) ...[
                      RadioGroup<bool>(
                        groupValue: isSelected,
                        onChanged: (val) {
                          if (enabled) onSelected?.call(val);
                        },
                        child: const Radio<bool>(
                          value: true,
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
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
                        onPressed: enabled ? onButton1Pressed : null,
                        child: Text(button1Text!),
                      ),
                    ),
                  if (button1Text != null && button2Text != null)
                    const SizedBox(height: 8),
                  if (button2Text != null)
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.tonal(
                        onPressed: enabled ? onButton2Pressed : null,
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
