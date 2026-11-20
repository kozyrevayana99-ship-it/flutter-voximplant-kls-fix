import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_voximplant/flutter_voximplant.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const client = MethodChannel('plugins.voximplant.com/client');
  final controllers = <VIVideoViewController>[];
  var nextTexture = 40;
  Completer<Map<String, int>>? delayedAllocation;

  setUp(() {
    nextTexture = 40;
    delayedAllocation = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(client, (call) async {
      if (call.method == 'VideoStream.addVideoRenderer') {
        if (delayedAllocation != null) return delayedAllocation!.future;
        return <String, int>{'textureId': nextTexture++};
      }
      return null;
    });
    for (var id = 40; id < 46; id++) {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
              MethodChannel('plugins.voximplant.com/renderer_$id'),
              (call) async => null);
    }
  });
  tearDown(() {
    for (final controller in controllers) { controller.dispose(); }
    controllers.clear();
  });

  VIVideoViewController controller() {
    final result = VIVideoViewController();
    controllers.add(result);
    return result;
  }
  Widget view(VIVideoViewController c, {Key? key}) =>
      Directionality(textDirection: TextDirection.ltr, child: VIVideoView(c, key: key));

  testWidgets('a texture allocated before mount is displayed on first mount',
      (tester) async {
    final c = controller();
    c.streamId = 'local';
    await tester.pump();
    await tester.pump();
    expect(c.streamId, 'local');
    await tester.pumpWidget(view(c));
    expect(find.byType(Texture), findsOneWidget);
    expect(tester.widget<Texture>(find.byType(Texture)).textureId, 40);
  });

  testWidgets('remount reuses the existing texture without restarting camera',
      (tester) async {
    final c = controller();
    await tester.pumpWidget(view(c));
    c.streamId = 'local';
    await tester.pump();
    await tester.pump();
    expect(find.byType(Texture), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(view(c));
    expect(find.byType(Texture), findsOneWidget);
    expect(nextTexture, 41);
  });

  testWidgets('a reused view follows its new controller', (tester) async {
    final a = controller(); final b = controller();
    const key = ValueKey('video-view');
    await tester.pumpWidget(view(a, key: key));
    a.streamId = 'first';
    b.streamId = 'second';
    await tester.pump();
    await tester.pump();
    await tester.pumpWidget(view(b, key: key));
    expect(tester.widget<Texture>(find.byType(Texture)).textureId, 41);
  });

  testWidgets('a late texture callback does not address a disposed view',
      (tester) async {
    final c = controller();
    delayedAllocation = Completer<Map<String, int>>();
    await tester.pumpWidget(view(c));
    c.streamId = 'local';
    await tester.pump();
    await tester.pump();
    await tester.pumpWidget(const SizedBox());
    delayedAllocation!.complete({'textureId': 40});
    await tester.pump();
    await tester.pump();
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(view(c));
    expect(find.byType(Texture), findsOneWidget);
  });

  testWidgets('clearing a stream clears the cached texture before remount',
      (tester) async {
    final c = controller();
    await tester.pumpWidget(view(c));
    c.streamId = 'local';
    await tester.pump();
    await tester.pump();
    c.streamId = null;
    await tester.pump();
    await tester.pump();
    expect(find.byType(Texture), findsNothing);
    await tester.pumpWidget(const SizedBox());
    await tester.pumpWidget(view(c));
    expect(find.byType(Texture), findsNothing);
  });
}
