import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

import '../models/medicine_lookup_model.dart';

/// Function used to identify a medicine from an image.
///
/// The provider does not perform network requests. Supply this function when
/// wiring an identification implementation into the app.
typedef MedicineIdentificationFunction = Future<MedicineLookupModel> Function(
  XFile image,
);

/// Holds the selected medicine image and the state of its identification.
class MedicineProvider extends ChangeNotifier {
  MedicineProvider({MedicineIdentificationFunction? identify})
    : _identify = identify ?? _identificationNotConfigured;

  final MedicineIdentificationFunction _identify;

  XFile? _selectedImage;
  MedicineLookupModel? _result;
  String? _errorMessage;
  bool _isLoading = false;
  bool _disposed = false;

  XFile? get selectedImage => _selectedImage;
  MedicineLookupModel? get result => _result;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _isLoading;
  bool get hasError => _errorMessage != null;
  bool get isSuccess => _result != null && !_isLoading;

  /// Selects an image and clears any previous lookup state.
  void selectImage(XFile? image) {
    _selectedImage = image;
    _result = null;
    _errorMessage = null;
    _notifyListeners();
  }

  /// Starts identification for the selected image.
  ///
  /// Calls made while an identification is already running are ignored.
  /// Exceptions from the injected operation are stored as user-visible state.
  Future<void> identifyMedicine() async {
    if (_isLoading) return;

    final image = _selectedImage;
    if (image == null) {
      _result = null;
      _errorMessage = 'Select a medicine image before identifying it.';
      _notifyListeners();
      return;
    }

    _isLoading = true;
    _result = null;
    _errorMessage = null;
    _notifyListeners();

    try {
      _result = await _identify(image);
    } catch (error) {
      _errorMessage = _messageFor(error);
    } finally {
      _isLoading = false;
      _notifyListeners();
    }
  }

  /// Clears a displayed error without changing the selected image or result.
  void clearError() {
    if (_errorMessage == null) return;
    _errorMessage = null;
    _notifyListeners();
  }

  /// Clears the selected image and all lookup state.
  void reset() {
    _selectedImage = null;
    _result = null;
    _errorMessage = null;
    _isLoading = false;
    _notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  void _notifyListeners() {
    if (!_disposed) notifyListeners();
  }

  static Future<MedicineLookupModel> _identificationNotConfigured(
    XFile image,
  ) => Future<MedicineLookupModel>.error(
    StateError('Medicine identification is not configured.'),
  );

  static String _messageFor(Object error) {
    if (error is StateError &&
        error.message == 'Medicine identification is not configured.') {
      return 'Medicine identification is not available yet.';
    }
    return 'Could not identify this medicine. Please try again.';
  }
}
