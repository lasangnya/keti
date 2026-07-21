import 'dart:async';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'user_activity_provider.g.dart';

class UserActivityState {
  final bool isIdle;
  final DateTime? lastActivityTime;
  final DateTime? idleStartTime;
  final Duration totalIdleDuration;

  UserActivityState({
    required this.isIdle,
    this.lastActivityTime,
    this.idleStartTime,
    required this.totalIdleDuration,
  });

  UserActivityState copyWith({
    bool? isIdle,
    DateTime? lastActivityTime,
    DateTime? idleStartTime,
    Duration? totalIdleDuration,
  }) {
    return UserActivityState(
      isIdle: isIdle ?? this.isIdle,
      lastActivityTime: lastActivityTime ?? this.lastActivityTime,
      idleStartTime: idleStartTime ?? this.idleStartTime,
      totalIdleDuration: totalIdleDuration ?? this.totalIdleDuration,
    );
  }
}

@riverpod
class UserActivity extends _$UserActivity {
  Timer? _idleTimer;
  static const _idleThreshold = Duration(seconds: 1);

  @override
  UserActivityState build() {
    ref.onDispose(() {
      _idleTimer?.cancel();
    });
    return UserActivityState(
      isIdle: false,
      lastActivityTime: DateTime.now(),
      totalIdleDuration: Duration.zero,
    );
  }

  void logMouseMovement() {
    _handleActivity();
  }

  void logMouseClick() {
    _handleActivity();
  }

  void logMouseScroll() {
    _handleActivity();
  }

  void logKeyboardStroke(String key) {
    _handleActivity();
  }

  void _handleActivity() {
    final now = DateTime.now();
    
    if (state.isIdle) {
      final idleDuration = now.difference(state.idleStartTime!);
      final newTotalIdleDuration = state.totalIdleDuration + idleDuration;
      
      print('--- Activity Resumed ---');
      print('Idle duration: ${idleDuration.inMilliseconds}ms');
      print('Total idle time: ${newTotalIdleDuration.inSeconds}s');
      
      state = state.copyWith(
        isIdle: false,
        lastActivityTime: now,
        idleStartTime: null,
        totalIdleDuration: newTotalIdleDuration,
      );
    } else {
      state = state.copyWith(lastActivityTime: now);
    }

    _resetIdleTimer();
  }

  void _resetIdleTimer() {
    _idleTimer?.cancel();
    _idleTimer = Timer(_idleThreshold, () {
      _onIdleDetected();
    });
  }

  void _onIdleDetected() {
    if (!state.isIdle) {
      print('--- Idling Detected (all inputs idle for >1s) ---');
      state = state.copyWith(
        isIdle: true,
        idleStartTime: DateTime.now(),
      );
    }
  }
}
