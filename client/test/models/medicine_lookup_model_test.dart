import 'package:flutter_test/flutter_test.dart';

import 'package:arogyavani/models/medicine_lookup_model.dart';

void main() {
  group('MedicineLookupModel.fromJson', () {
    test('parses valid JSON and preserves the open medicineInfo object', () {
      final model = MedicineLookupModel.fromJson({
        'identifiedMedicine': 'Example medicine',
        'confidence': 95.5,
        'medicineInfo': {'customField': 'value', 'nested': {'key': 1}},
        'disclaimer': 'For identification only.',
      });

      expect(model.identifiedMedicine, 'Example medicine');
      expect(model.confidence, 95.5);
      expect(model.medicineInfo['customField'], 'value');
      expect(model.medicineInfo['nested'], {'key': 1});
      expect(model.disclaimer, 'For identification only.');
    });

    test('converts integer and decimal confidence values to double', () {
      final integerConfidence = MedicineLookupModel.fromJson(_validJson(95));
      final decimalConfidence =
          MedicineLookupModel.fromJson(_validJson(95.5));

      expect(integerConfidence.confidence, 95.0);
      expect(integerConfidence.confidence, isA<double>());
      expect(decimalConfidence.confidence, 95.5);
      expect(decimalConfidence.confidence, isA<double>());
    });

    test('serializes all documented response fields', () {
      final input = _validJson(95.5)
        ..['medicineInfo'] = {'nested': {'key': 'value'}};
      final model = MedicineLookupModel.fromJson(input);

      expect(model.toJson(), {
        'identifiedMedicine': 'Example medicine',
        'confidence': 95.5,
        'medicineInfo': {'nested': {'key': 'value'}},
        'disclaimer': 'For identification only.',
      });
    });

    test('throws a clear FormatException for each missing required field', () {
      for (final field in [
        'identifiedMedicine',
        'confidence',
        'medicineInfo',
        'disclaimer',
      ]) {
        final json = _validJson(95.5)..remove(field);

        expect(
          () => MedicineLookupModel.fromJson(json),
          throwsA(
            isA<FormatException>().having(
              (error) => error.message,
              'message',
              contains('"$field"'),
            ),
          ),
          reason: 'Missing $field should identify the invalid field.',
        );
      }
    });

    test('rejects invalid and non-finite confidence values', () {
      for (final value in ['high', null, double.nan, double.infinity]) {
        final json = _validJson(value);

        expect(
          () => MedicineLookupModel.fromJson(json),
          throwsA(
            isA<FormatException>().having(
              (error) => error.message,
              'message',
              contains('"confidence"'),
            ),
          ),
        );
      }
    });

    test('rejects medicineInfo values that are not JSON objects', () {
      for (final value in ['details', 42, null, ['item']]) {
        final json = _validJson(95.5)..['medicineInfo'] = value;

        expect(
          () => MedicineLookupModel.fromJson(json),
          throwsA(
            isA<FormatException>().having(
              (error) => error.message,
              'message',
              contains('"medicineInfo"'),
            ),
          ),
        );
      }
    });
  });
}

Map<String, dynamic> _validJson(Object? confidence) => {
      'identifiedMedicine': 'Example medicine',
      'confidence': confidence,
      'medicineInfo': <String, dynamic>{},
      'disclaimer': 'For identification only.',
    };
