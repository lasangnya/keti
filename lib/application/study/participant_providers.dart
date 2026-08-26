import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/services/firebase/firestore_providers.dart';
import '../../core/services/firestore/firestore_participant_repository.dart';
import '../../core/services/local/local_store.dart';
import '../../core/services/study/participant_repository.dart';

part 'participant_providers.g.dart';

/// Read-side repository for participant/config/schedule documents.
///
/// Defaults to Firestore (real project or emulator, depending on
/// `USE_FIRESTORE_EMULATOR`); tests override with the in-memory mock.
@riverpod
ParticipantRepository participantRepository(Ref ref) =>
    FirestoreParticipantRepository(ref.watch(firebaseFirestoreProvider));

@Riverpod(keepAlive: true)
Future<LocalStore> localStore(Ref ref) async =>
    LocalStore(await SharedPreferences.getInstance());
