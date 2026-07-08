import 'package:flutter/material.dart';

class KetiCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool isSelected;
  final ValueChanged<bool?>? onSelected;

  final Widget? image;
  final bool showImage;
  final String? buttonText;
  final VoidCallback? onButtonPressed;
  final bool showButton;

  const KetiCard({
    super.key,
    required this.title,
    required this.subtitle,
    this.isSelected = false,
    this.onSelected,
    this.image,
    this.showImage = false,
    this.buttonText,
    this.onButtonPressed,
    this.showButton = false,
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
      child: RadioGroup<bool>(
        groupValue: isSelected,
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
                  Radio<bool>(value: true, visualDensity: VisualDensity.compact),
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

              // Conditional Button
                if (showButton && buttonText != null) ...[
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.tonal(
                      onPressed: onButtonPressed,
                      child: Text(buttonText!),
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