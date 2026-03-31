/// Energy requirement for task scheduling (FR5).
///
/// Pairs with the user's energy availability preferences configured during
/// onboarding (Story 1.9). The scheduling engine (Story 3.2) places
/// [highFocus] tasks only in the user's declared peak hours.
enum EnergyRequirement {
  highFocus,
  lowEnergy,
  flexible;

  /// JSON values use snake_case to match the API contract.
  static const _jsonMap = {
    'high_focus': EnergyRequirement.highFocus,
    'low_energy': EnergyRequirement.lowEnergy,
    'flexible': EnergyRequirement.flexible,
  };

  /// Parses a JSON string value to [EnergyRequirement].
  static EnergyRequirement? fromJson(String? value) {
    if (value == null) return null;
    return _jsonMap[value];
  }

  /// Serialises to the API/DB string representation (snake_case).
  String toJson() {
    switch (this) {
      case EnergyRequirement.highFocus:
        return 'high_focus';
      case EnergyRequirement.lowEnergy:
        return 'low_energy';
      case EnergyRequirement.flexible:
        return 'flexible';
    }
  }
}
