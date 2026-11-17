import 'package:flutter/foundation.dart';

/// Base class for screen-level ViewModels.
///
/// A ViewModel exposes one immutable `uiState` and methods for the
/// actions the screen can take. It never holds a `BuildContext`.
abstract class ViewModel extends ChangeNotifier {
  bool _disposed = false;

  bool get isDisposed => _disposed;

  /// Notifies listeners unless the ViewModel was disposed while an
  /// asynchronous action was still running.
  @protected
  void notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
