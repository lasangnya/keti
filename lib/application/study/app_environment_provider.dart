import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/constants/app_config.dart';

part 'app_environment_provider.g.dart';

/// The active build environment (`dev` | `pilot` | `study`). Wrapped in a
/// provider so tests can override the `--dart-define` constant.
@Riverpod(keepAlive: true)
String appEnvironment(Ref ref) => AppConfig.environment;
