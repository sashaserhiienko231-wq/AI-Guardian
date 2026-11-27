import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'strings.dart';

const baseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://localhost:8000',
);
const apiToken = String.fromEnvironment('API_AUTH_TOKEN');

final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) =>
      throw StateError('SharedPreferences must be initialized at startup.'),
);

enum ApiConnectivity { unknown, connected, unavailable }

class ApiConnectivityController extends Notifier<ApiConnectivity> {
  @override
  ApiConnectivity build() => ApiConnectivity.unknown;

  void update(bool connected) {
    state = connected ? ApiConnectivity.connected : ApiConnectivity.unavailable;
  }
}

final apiConnectivityProvider =
    NotifierProvider<ApiConnectivityController, ApiConnectivity>(
      ApiConnectivityController.new,
    );

class ApiClient {
  ApiClient({required void Function(bool connected) onConnectivityChanged})
    : dio = Dio(
        BaseOptions(
          baseUrl: baseUrl,
          connectTimeout: const Duration(seconds: 8),
          receiveTimeout: const Duration(seconds: 8),
          headers: apiToken.isEmpty
              ? null
              : {'Authorization': 'Bearer $apiToken'},
        ),
      ) {
    dio.interceptors.add(
      InterceptorsWrapper(
        onResponse: (response, handler) {
          onConnectivityChanged(true);
          handler.next(response);
        },
        onError: (error, handler) {
          onConnectivityChanged(error.response != null);
          handler.next(error);
        },
      ),
    );
  }

  final Dio dio;

  Future<Map<String, dynamic>> post(
    String path,
    Map<String, dynamic> body,
  ) async {
    final data = (await dio.post<Object?>(path, data: body)).data;
    if (data is! Map) {
      throw const FormatException('Expected an object from the security API.');
    }
    return Map<String, dynamic>.from(data);
  }

  Future<List<dynamic>> getList(String path) async {
    final data = (await dio.get<Object?>(path)).data;
    if (data is! List) {
      throw const FormatException('Expected a list from the security API.');
    }
    return List<dynamic>.from(data);
  }

  Future<Map<String, dynamic>> getMap(String path) async {
    final data = (await dio.get<Object?>(path)).data;
    if (data is! Map) {
      throw const FormatException('Expected an object from the security API.');
    }
    return Map<String, dynamic>.from(data);
  }
}

final apiProvider = Provider<ApiClient>(
  (ref) => ApiClient(
    onConnectivityChanged: (connected) =>
        ref.read(apiConnectivityProvider.notifier).update(connected),
  ),
);

class LocaleController extends Notifier<bool> {
  @override
  bool build() => true;

  void setLocale(bool ukrainian) => state = ukrainian;
  void toggle() => state = !state;
}

final localeProvider = NotifierProvider<LocaleController, bool>(
  LocaleController.new,
);

class ThemeModeController extends Notifier<ThemeMode> {
  @override
  ThemeMode build() => ThemeMode.dark;

  void setDark(bool dark) => state = dark ? ThemeMode.dark : ThemeMode.light;
}

final themeModeProvider = NotifierProvider<ThemeModeController, ThemeMode>(
  ThemeModeController.new,
);

class SidebarController extends Notifier<bool> {
  @override
  bool build() =>
      ref.watch(sharedPreferencesProvider).getBool('sidebar_expanded') ?? true;

  void toggle() {
    state = !state;
    unawaited(_persist(state));
  }

  Future<void> _persist(bool expanded) async {
    try {
      await ref
          .read(sharedPreferencesProvider)
          .setBool('sidebar_expanded', expanded);
    } catch (error, stackTrace) {
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stackTrace,
          library: 'AI Guardian',
          context: ErrorDescription('while saving sidebar preference'),
        ),
      );
    }
  }
}

final sidebarExpandedProvider = NotifierProvider<SidebarController, bool>(
  SidebarController.new,
);

String friendlyApiError(Object error, {required bool ukrainian}) {
  final strings = AppStrings(ukrainian);
  if (error is DioException) {
    final status = error.response?.statusCode;
    if (status == 422) return strings.invalidInput;
    if (status == 429) return strings.serviceBusy;
    if (status == 503) return strings.serviceMisconfigured;
    return strings.apiUnavailableError;
  }
  return strings.unexpectedError;
}
