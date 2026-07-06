import 'package:flutter/material.dart';

class ReminderColors extends ThemeExtension<ReminderColors> {
  final Color? blue;
  final Color? teal;
  final Color? sage;
  final Color? darkAmber;
  final Color? hotPink;
  final Color? darkPink;
  final Color? caribbeanBlue;

  const ReminderColors({
    this.blue,
    this.teal,
    this.sage,
    this.darkAmber,
    this.hotPink,
    this.darkPink,
    this.caribbeanBlue,
  });

  @override
  ThemeExtension<ReminderColors> copyWith({
    Color? blue,
    Color? teal,
    Color? sage,
    Color? darkAmber,
    Color? hotPink,
    Color? darkPink,
    Color? caribbeanBlue,
  }) {
    return ReminderColors(
      blue: this.blue,
      teal: this.teal,
      sage: this.sage,
      darkAmber: this.darkAmber,
      hotPink: this.hotPink,
      darkPink: this.darkPink,
      caribbeanBlue: this.caribbeanBlue,
    );
  }

  @override
  ThemeExtension<ReminderColors> lerp(
    covariant ThemeExtension<ReminderColors>? other,
    double t,
  ) {
    if (other is! ReminderColors) return this;
    return ReminderColors(
      blue: Color.lerp(blue, other.blue, t),
      teal: Color.lerp(teal, other.teal, t),
      sage: Color.lerp(sage, other.sage, t),
      darkAmber: Color.lerp(darkAmber, other.darkAmber, t),
      hotPink: Color.lerp(hotPink, other.hotPink, t),
      darkPink: Color.lerp(darkPink, other.darkPink, t),
      caribbeanBlue: Color.lerp(caribbeanBlue, other.caribbeanBlue, t),
    );
  }
}
