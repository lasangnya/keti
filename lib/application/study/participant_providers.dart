import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/services/local/csv_store.dart';
import '../../core/services/local/local_store.dart';
import '../../core/services/study/mock_participant_repository.dart';
import '../../core/services/study/participant_repository.dart';

part 'participant_providers.g.dart';

/// Read-side repository for participant/config/schedule documents.
///
/// M2 returns the in-memory mock; M3 overrides this with the Firestore
/// implementation.
@riverpod
ParticipantRepository participantRepository(Ref ref) =>
    MockParticipantRepository();

@Riverpod(keepAlive: true)
Future<LocalStore> localStore(Ref ref) async =>
    LocalStore(await SharedPreferences.getInstance());

@riverpod
CsvStore csvStore(Ref ref) => CsvStore();
