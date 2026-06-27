import 'environment.dart';

class AppConfig {
  final AppEnvironment environment;
  final String apiBaseUrl;
  final int connectTimeoutMs;
  final int receiveTimeoutMs;
  final String reverbHost;
  final int reverbPort;
  final String reverbAppKey;
  final String reverbScheme;
  final String minioBaseUrl;

  AppConfig({
    required this.environment,
    required this.apiBaseUrl,
    required this.connectTimeoutMs,
    required this.receiveTimeoutMs,
    required this.reverbHost,
    required this.reverbPort,
    required this.reverbAppKey,
    required this.reverbScheme,
    required this.minioBaseUrl,
  });

  static AppConfig get dev => AppConfig(
    environment: AppEnvironment.development,
    apiBaseUrl: 'https://cctv.miot-its.org/api',
    connectTimeoutMs: 10000,
    receiveTimeoutMs: 15000,
    reverbHost: 'cctv.miot-its.org',
    reverbPort: 443,
    reverbAppKey: 'j42ddfft9pcvefpkb2jl',
    reverbScheme: 'https',
    minioBaseUrl: 'https://cctv.miot-its.org',
  );

  static AppConfig get prod => AppConfig(
    environment: AppEnvironment.production,
    apiBaseUrl: 'https://cctv.miot-its.org/api',
    connectTimeoutMs: 10000,
    receiveTimeoutMs: 20000,
    reverbHost: 'cctv.miot-its.org',
    reverbPort: 443,
    reverbAppKey: 'j42ddfft9pcvefpkb2jl',
    reverbScheme: 'https',
    minioBaseUrl: 'https://cctv.miot-its.org',
  );
}
