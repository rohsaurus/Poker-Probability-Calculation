class Settings {
  int simulationCount;
  Duration? lastSimulationDuration;

  Settings({
    this.simulationCount = 100000,
    this.lastSimulationDuration,
  });
}

// Global settings instance
final settings = Settings();