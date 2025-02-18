import 'package:flutter_test/flutter_test.dart';
import 'package:camera/camera.dart';

import 'package:third_eye/main.dart'; // Adjust the import if needed

void main() {
  testWidgets('Camera Preview Smoke Test', (WidgetTester tester) async {
    // Mock the available cameras list
    final cameras = <CameraDescription>[];

    // Build the app and trigger a frame
    await tester.pumpWidget(MyApp(cameras: cameras));

    // Verify that the app initializes and displays the correct widgets
    expect(find.byType(CameraScreen), findsOneWidget);
  });
}

