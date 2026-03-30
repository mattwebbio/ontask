import 'example.dart';

/// Repository interface (port) for the example feature.
///
/// The data layer ([ExampleRepository]) implements this interface.
/// The presentation layer depends only on this abstraction so it can be
/// swapped with a mock during tests.
abstract interface class IExampleRepository {
  /// Returns all examples.
  Future<List<Example>> fetchAll();
}
