class ReminderContent {
  final String message;
  final String cursorResource;
  final String notchResource;
  final String trayResource;

  // Dimensions for Cursor
  final double cursorWidth;
  final double cursorHeight;
  final double cursorOffsetX;
  final double cursorOffsetY;

  // Dimensions for Notch (Dynamic Island)
  final double notchWidth;
  final double notchHeight;

  // Dimensions for Tray
  final double trayWidth;
  final double trayHeight;

  const ReminderContent({
    required this.message,
    required this.cursorResource,
    required this.notchResource,
    required this.trayResource,
    required this.cursorWidth,
    required this.cursorHeight,
    required this.cursorOffsetX,
    required this.cursorOffsetY,
    required this.notchWidth,
    required this.notchHeight,
    required this.trayWidth,
    required this.trayHeight,
  });
}
