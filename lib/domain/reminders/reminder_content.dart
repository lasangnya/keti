enum ReminderLocation { cursor, island, tray }

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

  // Animation metadata
  final int totalFrames;

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
    required this.totalFrames,
  });

  ReminderContent copyWith({
    String? message,
    String? cursorResource,
    String? notchResource,
    String? trayResource,
    double? cursorWidth,
    double? cursorHeight,
    double? cursorOffsetX,
    double? cursorOffsetY,
    double? notchWidth,
    double? notchHeight,
    double? trayWidth,
    double? trayHeight,
    int? totalFrames,
  }) {
    return ReminderContent(
      message: message ?? this.message,
      cursorResource: cursorResource ?? this.cursorResource,
      notchResource: notchResource ?? this.notchResource,
      trayResource: trayResource ?? this.trayResource,
      cursorWidth: cursorWidth ?? this.cursorWidth,
      cursorHeight: cursorHeight ?? this.cursorHeight,
      cursorOffsetX: cursorOffsetX ?? this.cursorOffsetX,
      cursorOffsetY: cursorOffsetY ?? this.cursorOffsetY,
      notchWidth: notchWidth ?? this.notchWidth,
      notchHeight: notchHeight ?? this.notchHeight,
      trayWidth: trayWidth ?? this.trayWidth,
      trayHeight: trayHeight ?? this.trayHeight,
      totalFrames: totalFrames ?? this.totalFrames,
    );
  }
}

class ReminderRequest {
  final ReminderContent content;
  final ReminderLocation location;

  ReminderRequest({
    required this.content,
    required this.location,
  });
}
