import 'package:flutter_test/flutter_test.dart';
import 'package:ontask/features/proof/domain/proof_path.dart';

// Widget tests for ProofPath enum — Story 7.5 (ProofPath.watchMode addition).
// Covers both the new watchMode enum value and regression checks for existing values.

void main() {
  group('ProofPath — watchMode enum value (Story 7.5)', () {
    test('1. ProofPath.watchMode is a valid enum value', () {
      expect(ProofPath.values.contains(ProofPath.watchMode), isTrue);
    });

    test('2. ProofPath.fromJson("watchMode") returns ProofPath.watchMode', () {
      expect(ProofPath.fromJson('watchMode'), equals(ProofPath.watchMode));
    });

    test('3. ProofPath.watchMode.toJson() returns "watchMode"', () {
      expect(ProofPath.watchMode.toJson(), equals('watchMode'));
    });
  });

  group('ProofPath — regression: existing values still work', () {
    test('4. ProofPath.healthKit is still a valid enum value', () {
      expect(ProofPath.values.contains(ProofPath.healthKit), isTrue);
    });

    test('5. ProofPath.fromJson("healthKit") returns ProofPath.healthKit', () {
      expect(ProofPath.fromJson('healthKit'), equals(ProofPath.healthKit));
    });

    test('6. ProofPath.healthKit.toJson() returns "healthKit"', () {
      expect(ProofPath.healthKit.toJson(), equals('healthKit'));
    });

    test('7. ProofPath.fromJson("photo") returns ProofPath.photo', () {
      expect(ProofPath.fromJson('photo'), equals(ProofPath.photo));
    });

    test('8. ProofPath.fromJson("screenshot") returns ProofPath.screenshot', () {
      expect(ProofPath.fromJson('screenshot'), equals(ProofPath.screenshot));
    });

    test('9. ProofPath.fromJson("offline") returns ProofPath.offline', () {
      expect(ProofPath.fromJson('offline'), equals(ProofPath.offline));
    });

    test('10. ProofPath.fromJson with unknown value throws ArgumentError', () {
      expect(
        () => ProofPath.fromJson('unknown'),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('11. ProofPath.fromJson with null throws ArgumentError', () {
      expect(
        () => ProofPath.fromJson(null),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('12. ProofPath has exactly 5 values', () {
      // photo, healthKit, watchMode, screenshot, offline
      expect(ProofPath.values.length, equals(5));
    });
  });
}
