import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/services/admin/admin_auth_service.dart';
import '../../core/services/admin/admin_export_service.dart';
import '../../core/services/admin/admin_repository.dart';
import '../../core/services/firebase/firestore_providers.dart';

part 'admin_providers.g.dart';

@riverpod
AdminAuthService adminAuthService(Ref ref) => FirebaseAdminAuthService();

@riverpod
AdminRepository adminRepository(Ref ref) =>
    FirestoreAdminRepository(ref.watch(firebaseFirestoreProvider));

@riverpod
AdminExportService adminExportService(Ref ref) =>
    AdminExportService(ref.watch(adminRepositoryProvider));
