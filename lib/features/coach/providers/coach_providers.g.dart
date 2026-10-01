// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'coach_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(coachAccess)
final coachAccessProvider = CoachAccessProvider._();

final class CoachAccessProvider
    extends $FunctionalProvider<AsyncValue<CoachAccess?>, CoachAccess?, FutureOr<CoachAccess?>>
    with $FutureModifier<CoachAccess?>, $FutureProvider<CoachAccess?> {
  CoachAccessProvider._()
    : super(
        from: null,
        argument: null,
        retry: coachNoRetry,
        name: r'coachAccessProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$coachAccessHash();

  @$internal
  @override
  $FutureProviderElement<CoachAccess?> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<CoachAccess?> create(Ref ref) {
    return coachAccess(ref);
  }
}

String _$coachAccessHash() => r'ac237faf514febe8cb11705bfe81091c6e70a3d0';

@ProviderFor(coachUsage)
final coachUsageProvider = CoachUsageProvider._();

final class CoachUsageProvider
    extends $FunctionalProvider<AsyncValue<CoachUsage>, CoachUsage, FutureOr<CoachUsage>>
    with $FutureModifier<CoachUsage>, $FutureProvider<CoachUsage> {
  CoachUsageProvider._()
    : super(
        from: null,
        argument: null,
        retry: coachNoRetry,
        name: r'coachUsageProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$coachUsageHash();

  @$internal
  @override
  $FutureProviderElement<CoachUsage> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<CoachUsage> create(Ref ref) {
    return coachUsage(ref);
  }
}

String _$coachUsageHash() => r'2a68292e89df034735d61b5b853b0b7c0ce7c36d';

/// The effective AI mode. Unknown (loading, or the server does not offer the
/// coach) counts as [CoachMode.none].

@ProviderFor(coachMode)
final coachModeProvider = CoachModeProvider._();

/// The effective AI mode. Unknown (loading, or the server does not offer the
/// coach) counts as [CoachMode.none].

final class CoachModeProvider
    extends $FunctionalProvider<AsyncValue<CoachMode>, CoachMode, FutureOr<CoachMode>>
    with $FutureModifier<CoachMode>, $FutureProvider<CoachMode> {
  /// The effective AI mode. Unknown (loading, or the server does not offer the
  /// coach) counts as [CoachMode.none].
  CoachModeProvider._()
    : super(
        from: null,
        argument: null,
        retry: coachNoRetry,
        name: r'coachModeProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$coachModeHash();

  @$internal
  @override
  $FutureProviderElement<CoachMode> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<CoachMode> create(Ref ref) {
    return coachMode(ref);
  }
}

String _$coachModeHash() => r'97b0ca0ed248ffe25041ac3ea471e25776ca99f6';

@ProviderFor(coachLocations)
final coachLocationsProvider = CoachLocationsProvider._();

final class CoachLocationsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<CoachLocation>>,
          List<CoachLocation>,
          FutureOr<List<CoachLocation>>
        >
    with $FutureModifier<List<CoachLocation>>, $FutureProvider<List<CoachLocation>> {
  CoachLocationsProvider._()
    : super(
        from: null,
        argument: null,
        retry: coachNoRetry,
        name: r'coachLocationsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$coachLocationsHash();

  @$internal
  @override
  $FutureProviderElement<List<CoachLocation>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<CoachLocation>> create(Ref ref) {
    return coachLocations(ref);
  }
}

String _$coachLocationsHash() => r'391f1a37e1e326a1fe4cb33d4a9e79e8042280c5';

/// The user's own AI provider settings

@ProviderFor(AiProviderSettings)
final aiProviderSettingsProvider = AiProviderSettingsProvider._();

/// The user's own AI provider settings
final class AiProviderSettingsProvider
    extends $AsyncNotifierProvider<AiProviderSettings, AiProviderConfig> {
  /// The user's own AI provider settings
  AiProviderSettingsProvider._()
    : super(
        from: null,
        argument: null,
        retry: coachNoRetry,
        name: r'aiProviderSettingsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$aiProviderSettingsHash();

  @$internal
  @override
  AiProviderSettings create() => AiProviderSettings();
}

String _$aiProviderSettingsHash() => r'2819eea3135dd97603c6d724b2f24a06d8f51960';

/// The user's own AI provider settings

abstract class _$AiProviderSettings extends $AsyncNotifier<AiProviderConfig> {
  FutureOr<AiProviderConfig> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<AiProviderConfig>, AiProviderConfig>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<AiProviderConfig>, AiProviderConfig>,
              AsyncValue<AiProviderConfig>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

@ProviderFor(CoachChat)
final coachChatProvider = CoachChatProvider._();

final class CoachChatProvider extends $NotifierProvider<CoachChat, ChatState> {
  CoachChatProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'coachChatProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$coachChatHash();

  @$internal
  @override
  CoachChat create() => CoachChat();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ChatState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ChatState>(value),
    );
  }
}

String _$coachChatHash() => r'68e86eea07d5eff9974d510c5401b628f696c291';

abstract class _$CoachChat extends $Notifier<ChatState> {
  ChatState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<ChatState, ChatState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<ChatState, ChatState>,
              ChatState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

@ProviderFor(WorkoutPlanGenerator)
final workoutPlanGeneratorProvider = WorkoutPlanGeneratorProvider._();

final class WorkoutPlanGeneratorProvider
    extends $NotifierProvider<WorkoutPlanGenerator, AsyncValue<WorkoutProposal?>> {
  WorkoutPlanGeneratorProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'workoutPlanGeneratorProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$workoutPlanGeneratorHash();

  @$internal
  @override
  WorkoutPlanGenerator create() => WorkoutPlanGenerator();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AsyncValue<WorkoutProposal?> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AsyncValue<WorkoutProposal?>>(value),
    );
  }
}

String _$workoutPlanGeneratorHash() => r'4daea8bf6bcb16ed2920accc0e0aca8eb01a9211';

abstract class _$WorkoutPlanGenerator extends $Notifier<AsyncValue<WorkoutProposal?>> {
  AsyncValue<WorkoutProposal?> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<WorkoutProposal?>, AsyncValue<WorkoutProposal?>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<WorkoutProposal?>, AsyncValue<WorkoutProposal?>>,
              AsyncValue<WorkoutProposal?>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

@ProviderFor(MealPlanGenerator)
final mealPlanGeneratorProvider = MealPlanGeneratorProvider._();

final class MealPlanGeneratorProvider
    extends $NotifierProvider<MealPlanGenerator, AsyncValue<MealProposal?>> {
  MealPlanGeneratorProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'mealPlanGeneratorProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$mealPlanGeneratorHash();

  @$internal
  @override
  MealPlanGenerator create() => MealPlanGenerator();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AsyncValue<MealProposal?> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AsyncValue<MealProposal?>>(value),
    );
  }
}

String _$mealPlanGeneratorHash() => r'f94b3f77db994ce0323f98b38fabc093d6799d5f';

abstract class _$MealPlanGenerator extends $Notifier<AsyncValue<MealProposal?>> {
  AsyncValue<MealProposal?> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<MealProposal?>, AsyncValue<MealProposal?>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<MealProposal?>, AsyncValue<MealProposal?>>,
              AsyncValue<MealProposal?>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

@ProviderFor(CoachGoals)
final coachGoalsProvider = CoachGoalsProvider._();

final class CoachGoalsProvider extends $AsyncNotifierProvider<CoachGoals, List<CoachGoal>> {
  CoachGoalsProvider._()
    : super(
        from: null,
        argument: null,
        retry: coachNoRetry,
        name: r'coachGoalsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$coachGoalsHash();

  @$internal
  @override
  CoachGoals create() => CoachGoals();
}

String _$coachGoalsHash() => r'835cf2ed35e6a7558e56e0f678e4f1cfbe1f2e17';

abstract class _$CoachGoals extends $AsyncNotifier<List<CoachGoal>> {
  FutureOr<List<CoachGoal>> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<List<CoachGoal>>, List<CoachGoal>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<CoachGoal>>, List<CoachGoal>>,
              AsyncValue<List<CoachGoal>>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

@ProviderFor(coachIndicators)
final coachIndicatorsProvider = CoachIndicatorsFamily._();

final class CoachIndicatorsProvider
    extends
        $FunctionalProvider<
          AsyncValue<IndicatorsResponse>,
          IndicatorsResponse,
          FutureOr<IndicatorsResponse>
        >
    with $FutureModifier<IndicatorsResponse>, $FutureProvider<IndicatorsResponse> {
  CoachIndicatorsProvider._({
    required CoachIndicatorsFamily super.from,
    required int super.argument,
  }) : super(
         retry: coachNoRetry,
         name: r'coachIndicatorsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$coachIndicatorsHash();

  @override
  String toString() {
    return r'coachIndicatorsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<IndicatorsResponse> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<IndicatorsResponse> create(Ref ref) {
    final argument = this.argument as int;
    return coachIndicators(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is CoachIndicatorsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$coachIndicatorsHash() => r'73bce7027fcfc47ec85f830ebfb6156285890e43';

final class CoachIndicatorsFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<IndicatorsResponse>, int> {
  CoachIndicatorsFamily._()
    : super(
        retry: coachNoRetry,
        name: r'coachIndicatorsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  CoachIndicatorsProvider call(int window) =>
      CoachIndicatorsProvider._(argument: window, from: this);

  @override
  String toString() => r'coachIndicatorsProvider';
}

@ProviderFor(planRecommendations)
final planRecommendationsProvider = PlanRecommendationsProvider._();

final class PlanRecommendationsProvider
    extends
        $FunctionalProvider<
          AsyncValue<PlanRecommendations>,
          PlanRecommendations,
          FutureOr<PlanRecommendations>
        >
    with $FutureModifier<PlanRecommendations>, $FutureProvider<PlanRecommendations> {
  PlanRecommendationsProvider._()
    : super(
        from: null,
        argument: null,
        retry: coachNoRetry,
        name: r'planRecommendationsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$planRecommendationsHash();

  @$internal
  @override
  $FutureProviderElement<PlanRecommendations> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<PlanRecommendations> create(Ref ref) {
    return planRecommendations(ref);
  }
}

String _$planRecommendationsHash() => r'019f2c208a479c7cfd54208d991b13e8c670b5b6';

@ProviderFor(CoachMemoryList)
final coachMemoryListProvider = CoachMemoryListProvider._();

final class CoachMemoryListProvider
    extends $AsyncNotifierProvider<CoachMemoryList, List<CoachMemory>> {
  CoachMemoryListProvider._()
    : super(
        from: null,
        argument: null,
        retry: coachNoRetry,
        name: r'coachMemoryListProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$coachMemoryListHash();

  @$internal
  @override
  CoachMemoryList create() => CoachMemoryList();
}

String _$coachMemoryListHash() => r'0bd867bd1ca168ffffc3c372c0a5240edcceaa9f';

abstract class _$CoachMemoryList extends $AsyncNotifier<List<CoachMemory>> {
  FutureOr<List<CoachMemory>> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<List<CoachMemory>>, List<CoachMemory>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<CoachMemory>>, List<CoachMemory>>,
              AsyncValue<List<CoachMemory>>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
