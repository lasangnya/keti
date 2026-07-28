import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../firestore/reminder_event_repository.dart';
import '../firestore/session_repository.dart';
import 'auth_service.dart';

part 'firestore_providers.g.dart';

@Riverpod(keepAlive: true)
FirebaseFirestore firebaseFirestore(Ref ref) => FirebaseFirestore.instance;

@Riverpod(keepAlive: true)
AuthService authService(Ref ref) => AuthService();

@Riverpod(keepAlive: true)
SessionRepository sessionRepository(Ref ref) =>
    FirestoreSessionRepository(ref.watch(firebaseFirestoreProvider));

@Riverpod(keepAlive: true)
ReminderEventRepository reminderEventRepository(Ref ref) =>
    FirestoreReminderEventRepository(ref.watch(firebaseFirestoreProvider));
