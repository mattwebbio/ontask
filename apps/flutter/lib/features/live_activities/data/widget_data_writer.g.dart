// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'widget_data_writer.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(widgetDataWriter)
final widgetDataWriterProvider = WidgetDataWriterProvider._();

final class WidgetDataWriterProvider
    extends
        $FunctionalProvider<
          WidgetDataWriter,
          WidgetDataWriter,
          WidgetDataWriter
        >
    with $Provider<WidgetDataWriter> {
  WidgetDataWriterProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'widgetDataWriterProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$widgetDataWriterHash();

  @$internal
  @override
  $ProviderElement<WidgetDataWriter> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  WidgetDataWriter create(Ref ref) {
    return widgetDataWriter(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(WidgetDataWriter value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<WidgetDataWriter>(value),
    );
  }
}

String _$widgetDataWriterHash() =>
    r'b7e2d4f1a9c6083e7d1b4f8c3a5e9d2b0f7c4e6a';
