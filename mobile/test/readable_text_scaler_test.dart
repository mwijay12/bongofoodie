import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bongo_foodie/core/theme/app_type.dart';
import 'package:bongo_foodie/core/theme/readable_text_scaler.dart';

void main() {
  const readable = ReadableTextScaler(
    systemScaler: TextScaler.noScaling,
    userScaleFactor: AppType.normalTextScale,
    minimumFontSize: AppType.minReadableFontSize,
    maxScaleFactor: AppType.maxTextScale,
  );

  test('tiny labels are lifted to the readable floor', () {
    expect(readable.scale(9), AppType.minReadableFontSize);
    expect(readable.scale(11), AppType.minReadableFontSize);
    expect(readable.scale(13.5), AppType.minReadableFontSize);
    expect(readable.scale(16), 16);
  });

  test('the larger preference scales ordinary copy but keeps hierarchy', () {
    const larger = ReadableTextScaler(
      systemScaler: TextScaler.noScaling,
      userScaleFactor: AppType.largerTextScale,
      minimumFontSize: AppType.minReadableFontSize,
      maxScaleFactor: AppType.maxTextScale,
    );
    expect(larger.scale(9), 17.5);
    expect(larger.scale(20), 25);
    expect(larger.scale(20), greaterThan(larger.scale(9)));
  });

  test('extreme system scaling is capped for tested layouts', () {
    final scaler = ReadableTextScaler(
      systemScaler: TextScaler.linear(2),
      userScaleFactor: AppType.normalTextScale,
      minimumFontSize: AppType.minReadableFontSize,
      maxScaleFactor: AppType.maxTextScale,
    );
    expect(scaler.scale(20), closeTo(32, 0.001));
    expect(scaler.scale(9), greaterThanOrEqualTo(AppType.minReadableFontSize));
  });

  test('equal scalers do not cause needless text rebuilds', () {
    const other = ReadableTextScaler(
      systemScaler: TextScaler.noScaling,
      userScaleFactor: AppType.normalTextScale,
      minimumFontSize: AppType.minReadableFontSize,
      maxScaleFactor: AppType.maxTextScale,
    );
    expect(readable, other);
    expect(readable.hashCode, other.hashCode);
  });
}
