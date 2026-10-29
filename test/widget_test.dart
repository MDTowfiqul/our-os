import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:our_os/main.dart';

void main() {
  testWidgets('Our OS loads the systems hub', (tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const MyOsApp());
    await tester.pumpAndSettle();
    expect(find.text('💫 Our OS'), findsOneWidget);
    expect(find.text('Project'), findsOneWidget);
  });
}
