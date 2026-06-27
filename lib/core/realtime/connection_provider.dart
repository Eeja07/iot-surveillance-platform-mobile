import 'package:flutter_riverpod/flutter_riverpod.dart';

enum ConnectionStatus { connecting, connected, reconnecting, offline }

final connectionStatusProvider = StateProvider<ConnectionStatus>(
  (ref) => ConnectionStatus.offline,
);
