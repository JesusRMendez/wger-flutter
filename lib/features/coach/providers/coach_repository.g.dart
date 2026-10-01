// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'coach_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(coachRepository)
final coachRepositoryProvider = CoachRepositoryProvider._();

final class CoachRepositoryProvider
    extends $FunctionalProvider<CoachRepository, CoachRepository, CoachRepository>
    with $Provider<CoachRepository> {
  CoachRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'coachRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$coachRepositoryHash();

  @$internal
  @override
  $ProviderElement<CoachRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  CoachRepository create(Ref ref) {
    return coachRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CoachRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CoachRepository>(value),
    );
  }
}

String _$coachRepositoryHash() => r'dd93e75831f1aa72b6d142be50e086de20daca60';
