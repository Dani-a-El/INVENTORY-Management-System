import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ims_app/main.dart';
import 'package:ims_app/services/api_service.dart';

void main() {
  testWidgets('IMS app loads login smoke test', (WidgetTester tester) async {
    final originalClient = ApiService.client;
    SharedPreferences.setMockInitialValues({});
    ApiService.client = MockClient((request) async {
      if (request.url.path == '/health/db') {
        return http.Response(
          jsonEncode({'status': 'ok', 'message': 'Database is online'}),
          200,
        );
      }

      if (request.url.path == '/dashboard') {
        return http.Response(
          jsonEncode({
            'total_products': 0,
            'total_stock': 0,
            'low_stock_count': 0,
          }),
          200,
        );
      }

      return http.Response('[]', 200);
    });

    addTearDown(() {
      ApiService.client = originalClient;
    });

    await tester.pumpWidget(const IMSApp());
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();

    expect(find.text('Welcome back'), findsOneWidget);
  });
}
