import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onthi_community/shared/widgets/milky_mint_scaffold.dart';

void main() {
  testWidgets('MilkyMintScaffold renders cloudv2_tall texture inside RepaintBoundary', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: MilkyMintScaffold(
          showCloudTexture: true,
          body: Text('Content'),
        ),
      ),
    );

    final imageFinder = find.byWidgetPredicate(
      (widget) =>
          widget is Image &&
          widget.image is AssetImage &&
          (widget.image as AssetImage).assetName == 'assets/images/cloudv2_tall.jpg',
    );
    expect(imageFinder, findsOneWidget);
  });
}
