
class SummarySample {
  
  int batteryLevel;
  int heartRate;
  float respirationRate;
  float coreTemperature;
  float breathingWaveAmplitude;
  int breathingRateConfidence;
  int heartRateRateConfidence;
  float ecgNoise;
  int hearRateVariability;
  float peakAcceleration;
  int time;
  int id;
  
  SummarySample(int batteryLevel, int heartRate, float respirationRate, float coreTemperature,
      float breathingWaveAmplitude, int breathingRateConfidence, int heartRateRateConfidence,
      float ecgNoise, int hearRateVariability, float peakAcceleration, int id, int time)
  {
    this.batteryLevel = batteryLevel;
    this.heartRate = heartRate;
    this.respirationRate = respirationRate;
    this.coreTemperature = coreTemperature;
    this.breathingWaveAmplitude = breathingWaveAmplitude;
    this.breathingRateConfidence = breathingRateConfidence;
    this.heartRateRateConfidence = heartRateRateConfidence;
    this.ecgNoise = ecgNoise;
    this.hearRateVariability = hearRateVariability;
    this.peakAcceleration = peakAcceleration;
    this.id = id;
    this.time = time;
  }
  
}