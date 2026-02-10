// lib/packages/equalizer_flutter_custom/lib/src/EqalizerProvider/EqualizerProvider.dart

import 'dart:collection';
import 'dart:async';
import 'package:equalizer_flutter/equalizer_flutter.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EqualizerProvider extends ChangeNotifier {
  EqualizerProvider() {
    _loadMinimalSettings();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // BAND LEVEL RANGE
  // ═══════════════════════════════════════════════════════════════════════════
  
  List<int> bandLevelRange = [];
  bool isBandRangeLoading = false;
  double eqMinVal = -15;
  double eqMaxVal = 15;

  // ═══════════════════════════════════════════════════════════════════════════
  // EQUALIZER STATE
  // ═══════════════════════════════════════════════════════════════════════════
  
  bool custom = true;
  bool isEqEnabled = false;
  bool isApplyingPreset = false;
  bool EqInit = false;

  // ═══════════════════════════════════════════════════════════════════════════
  // AUDIO CONTROL VALUES
  // ═══════════════════════════════════════════════════════════════════════════
  
  double bassval = defaultBassVal;
  double pitchval = defaultPitchVal;
  double volumeval = defaultVolumeVal;
  double _vocalSuppressionLevel = 0.0;

  static const double defaultBassVal = 500;
  static const double defaultPitchVal = 1.0;
  static const double defaultVolumeVal = 0.0;

  // ═══════════════════════════════════════════════════════════════════════════
  // BANDS & PRESETS
  // ═══════════════════════════════════════════════════════════════════════════
  
  List<int> bands = [];
  List<int> _originalBandLevels = [];
  List<int> _centerFrequencies = [];
  List<String> presets = [];
  String currentp = 'Custom';

  // ═══════════════════════════════════════════════════════════════════════════
  // VOCAL SUPPRESSION CONSTANTS
  // ═══════════════════════════════════════════════════════════════════════════

  // NOTE: getCenterBandFreqs() returns frequencies in milliHertz (mHz)
  // e.g. 1kHz = 1_000_000 mHz, 60Hz = 60_000 mHz

  // Primary vocal frequency range (where most vocal energy is concentrated)
  static const int _vocalFreqMin = 100000000; // 1kHz in mHz
  static const int _vocalFreqMax = 350000000; // 3.5kHz in mHz

  // Extended vocal range (for smoother transition)
  static const int _vocalFreqMinExtended = 50000000; // 500Hz in mHz
  static const int _vocalFreqMaxExtended = 500000000; // 5kHz in mHz

  // Bass/treble thresholds for compensation boost
  static const int _bassThreshold = 25000000; // 250Hz in mHz
  static const int _trebleThreshold = 800000000; // 8kHz in mHz

  // ═══════════════════════════════════════════════════════════════════════════
  // PERSISTENCE KEYS
  // ═══════════════════════════════════════════════════════════════════════════

  static const _kPitchKey = 'eq_pitch';
  static const _kBassKey = 'eq_bass';
  static const _kVocalSuppressionKey = 'eq_vocal_suppression';
  static const _kPresetKey = 'eq_preset';
  static const _kCustomKey = 'eq_custom';
  static const _kIsEqEnabledKey = 'eq_enabled';
  static const _kBandsKey = 'eq_bands';

  // ═══════════════════════════════════════════════════════════════════════════
  // GETTERS
  // ═══════════════════════════════════════════════════════════════════════════

  double get vocalSuppressionLevel => _vocalSuppressionLevel;
  List<int> get centerFrequencies => _centerFrequencies;

  // ═══════════════════════════════════════════════════════════════════════════
  // BAND MANAGEMENT
  // ═══════════════════════════════════════════════════════════════════════════

  void setBandRange(int id, int val) {
    if (bands.length <= id) {
      bands = List<int>.from(bands);
      while (bands.length <= id) {
        bands.add(0);
      }
    }
    bands[id] = val;
    notifyListeners();
  }

  void setBandRangeBTN(int id, int val) {
    bands[id] = val;
    notifyListeners();
  }

  void updateBandLevelDuringDrag(int bandId, int value) {
    if (bands.length > bandId) {
      bands[bandId] = value;
      try {
        EqualizerFlutter.setBandLevel(bandId, value);
      } catch (e) {
        debugPrint('EqualizerProvider: setBandLevel error during drag: $e');
      }
    }
  }

  Future<void> changeFreq(int bandid, int lowervalue) async {
    debugPrint(
        'EqualizerProvider: changeFreq - Band $bandid set to $lowervalue');
    try {
      await EqualizerFlutter.setBandLevel(bandid, lowervalue);
    } catch (e) {
      debugPrint('EqualizerProvider: setBandLevel error in changeFreq: $e');
    }

    if (bands.length > bandid && bands[bandid] != lowervalue) {
      bands[bandid] = lowervalue;
    }

    // Also update original levels when user manually changes a band
    if (_originalBandLevels.length > bandid) {
      _originalBandLevels[bandid] = lowervalue;
    }
    
    custom = true;
    _savePreset();
    _saveBands();
    notifyListeners();
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // EQUALIZER ENABLE/DISABLE
  // ═══════════════════════════════════════════════════════════════════════════

  void setEqEnabled(bool cond) {
    debugPrint(
        'EqualizerProvider: setEqEnabled called with $cond (previous=$isEqEnabled)');
    isEqEnabled = cond;
    _readyEqualiser(cond);
    _saveIsEqEnabled();
    notifyListeners();
  }

  void _readyEqualiser(bool cond) {
    try {
      EqualizerFlutter.setEnabled(cond);
    } catch (e) {
      debugPrint('EqualizerProvider: setEnabled error: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // INITIALIZATION
  // ═══════════════════════════════════════════════════════════════════════════

  Future<void> initEqalizer(int? androidAudioSessionId) async {
    if (androidAudioSessionId == null || androidAudioSessionId == 0) {
      debugPrint(
          'EqualizerProvider: audioSessionId is null/zero, cannot initialize');
      return;
    }

    try {
      debugPrint(
          'EqualizerProvider: Initializing with session ID: $androidAudioSessionId');
      await EqualizerFlutter.init(androidAudioSessionId);
      debugPrint('EqualizerProvider: EqualizerFlutter.init completed');
    } catch (e) {
      debugPrint('EqualizerProvider: init error: $e');
    }

    await getPresest();
    await fetchBandLevels();
    await _loadCenterFrequencies();

    EqInit = true;
    debugPrint(
        'EqualizerProvider: Initialization complete, bands: ${bands.length}');
    notifyListeners();
  }

  Future<void> loadBandLevelRange() async {
    isBandRangeLoading = true;
    notifyListeners();
    
    try {
      debugPrint('EqualizerProvider: Loading band level range...');
      var range = await EqualizerFlutter.getBandLevelRange();
      
      if (range.isEmpty || range.length < 2) {
        debugPrint('EqualizerProvider: Band range empty, retrying...');
        await Future.delayed(const Duration(milliseconds: 200));
        range = await EqualizerFlutter.getBandLevelRange();
      }

      if (range.length >= 2) {
        bandLevelRange = List<int>.from(range);
        _setMinMaxEq();
        debugPrint(
            'EqualizerProvider: Band range loaded: min=${bandLevelRange[0]}, max=${bandLevelRange[1]}');
      } else {
        debugPrint('EqualizerProvider: Band range still invalid after retry');
        bandLevelRange = [];
      }
    } catch (e, stackTrace) {
      debugPrint('EqualizerProvider: loadBandLevelRange error: $e');
      debugPrint('EqualizerProvider: Stack trace: $stackTrace');
      bandLevelRange = [];
    } finally {
      isBandRangeLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchBandLevels() async {
    try {
      debugPrint("EqualizerProvider: Starting fetchBandLevels");
      final centerFreqs = await EqualizerFlutter.getCenterBandFreqs();
      debugPrint(
          "EqualizerProvider: Got center frequencies: ${centerFreqs.length}");

      // Always update center frequencies for vocal suppression
      _centerFrequencies = List<int>.from(centerFreqs);

      if (bands.length != centerFreqs.length) {
        bands = List<int>.filled(centerFreqs.length, 0);
        _originalBandLevels = List<int>.filled(centerFreqs.length, 0);
      }

      final futures = <Future<int>>[];
      for (int i = 0; i < centerFreqs.length; i++) {
        futures.add(EqualizerFlutter.getBandLevel(i));
      }

      final results = await Future.wait(futures, eagerError: true);
      for (int i = 0; i < results.length; i++) {
        bands[i] = results[i];
        _originalBandLevels[i] = results[i];
      }

      debugPrint("EqualizerProvider: Fetched all band levels: $bands");
      debugPrint("EqualizerProvider: Center frequencies: $_centerFrequencies");
      notifyListeners();
    } catch (e) {
      debugPrint("Error fetching band levels: $e");
    }
  }

  Future<void> _loadCenterFrequencies() async {
    try {
      _centerFrequencies = await EqualizerFlutter.getCenterBandFreqs();
      debugPrint(
          'EqualizerProvider: Loaded center frequencies: $_centerFrequencies');
    } catch (e) {
      debugPrint('EqualizerProvider: Error loading center frequencies: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PRESETS
  // ═══════════════════════════════════════════════════════════════════════════

  static List<String> _dedupePresets(List<String> raw) {
    return LinkedHashSet<String>.from(raw).toList();
  }

  Future<List<String>> getPresest() async {
    try {
      debugPrint("EqualizerProvider: Starting getPresest");
      final raw = await EqualizerFlutter.getPresetNames();
      presets = _dedupePresets(raw);
      notifyListeners();
      debugPrint("EqualizerProvider: Updated presets: $presets");
      return presets;
    } catch (e) {
      debugPrint("Error getting presets: $e");
      return presets;
    }
  }

  void validatePresetAgainstAvailable() {
    if (!presets.contains(currentp) && currentp != 'Custom') {
      custom = true;
      currentp = 'Custom';
      _savePreset();
      notifyListeners();
    }
  }

  Future<void> setPresets(String presetName) async {
    try {
      debugPrint(
          'EqualizerProvider: setPresets - Setting preset to: $presetName');

      isApplyingPreset = true;
      notifyListeners();

      try {
        await EqualizerFlutter.setPreset(presetName).timeout(
          const Duration(milliseconds: 1500),
        );
      } catch (e) {
        debugPrint('EqualizerProvider: setPreset error: $e');
      }

      currentp = presetName;
      custom = false;

      await _savePreset();

      try {
        await fetchBandLevels().timeout(const Duration(milliseconds: 1000));
      } catch (e) {
        debugPrint('EqualizerProvider: fetchBandLevels error: $e');
      }

      validatePresetAgainstAvailable();
      await Future.delayed(const Duration(milliseconds: 50));
    } catch (e) {
      debugPrint('EqualizerProvider: setPresets error: $e');
    } finally {
      isApplyingPreset = false;
      notifyListeners();
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // BASS CONTROL
  // ═══════════════════════════════════════════════════════════════════════════

  void setbassval(double val) {
    bassval = val;
    debugPrint("EqualizerProvider: bass: $bassval");
    custom = true;
    _saveBass();
    _savePreset();
    notifyListeners();
  }

  void resetBass() {
    bassval = defaultBassVal;
    debugPrint('EqualizerProvider: bass reset to default');
    custom = true;
    _saveBass();
    _savePreset();
    notifyListeners();
  }

  void setBassDuringDrag(double val) {
    bassval = val;
    custom = true;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PITCH CONTROL
  // ═══════════════════════════════════════════════════════════════════════════

  void setpitchval(double val) {
    pitchval = val;
    debugPrint('EqualizerProvider: pitch set to $pitchval');
    custom = true;
    _savePitch();
    _savePreset();
    notifyListeners();
  }

  void resetPitch() {
    pitchval = defaultPitchVal;
    debugPrint('EqualizerProvider: pitch reset to default');
    custom = true;
    _savePitch();
    _savePreset();
    notifyListeners();
  }

  void setPitchDuringDrag(double val) {
    pitchval = val;
    custom = true;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // VOCAL SUPPRESSION - IMPROVED ALGORITHM
  // ═══════════════════════════════════════════════════════════════════════════

  /// Calculate the vocal suppression factor for a given frequency.
  /// Returns a value between 0.0 (no suppression) and 1.0 (full suppression).
  /// Uses a bell curve centered around the primary vocal range.
  double _getVocalSuppressionFactor(int frequency) {
    // Outside extended range: no suppression
    if (frequency < _vocalFreqMinExtended ||
        frequency > _vocalFreqMaxExtended) {
      return 0.0;
    }

    // Inside primary vocal range: maximum suppression
    if (frequency >= _vocalFreqMin && frequency <= _vocalFreqMax) {
      // Peak suppression in the center of vocal range (around 2kHz)
      final center = (_vocalFreqMin + _vocalFreqMax) / 2;
      final distanceFromCenter =
          (frequency - center).abs() / ((_vocalFreqMax - _vocalFreqMin) / 2);
      // Bell curve: more suppression at center, less at edges
      return 0.7 + 0.3 * (1.0 - distanceFromCenter);
    }

    // Transition zones: smooth falloff
    if (frequency < _vocalFreqMin) {
      // Lower transition (500Hz - 1000Hz)
      final ratio = (frequency - _vocalFreqMinExtended) /
          (_vocalFreqMin - _vocalFreqMinExtended);
      return ratio * 0.5; // Max 50% suppression in transition
    } else {
      // Upper transition (3500Hz - 5000Hz)
      final ratio = 1.0 -
          ((frequency - _vocalFreqMax) /
              (_vocalFreqMaxExtended - _vocalFreqMax));
      return ratio * 0.5; // Max 50% suppression in transition
    }
  }

  /// Check if a frequency is in the vocal range (for UI highlighting)
  bool isVocalFrequency(int frequency) {
    return frequency >= _vocalFreqMinExtended &&
        frequency <= _vocalFreqMaxExtended;
  }

  /// Check if a frequency is in the PRIMARY vocal range
  bool isPrimaryVocalFrequency(int frequency) {
    return frequency >= _vocalFreqMin && frequency <= _vocalFreqMax;
  }

  /// Apply vocal suppression with improved algorithm
  /// - Only suppresses vocal frequencies (1-3.5kHz primarily)
  /// - Uses bell curve for natural sound
  /// - Optionally boosts bass/treble to compensate
  Future<void> applyVocalSuppression(double level) async {
    if (bands.isEmpty || _centerFrequencies.isEmpty) {
      debugPrint('EqualizerProvider: applyVocalSuppression skipped - '
          'bands: ${bands.length}, centerFreqs: ${_centerFrequencies.length}');
      return;
    }

    // Vocal suppression requires native EQ to be enabled to take effect
    if (!isEqEnabled) {
      debugPrint('EqualizerProvider: Auto-enabling EQ for vocal suppression');
      isEqEnabled = true;
      _readyEqualiser(true);
      _saveIsEqEnabled();
      // notifyListeners will be called at the end of this method
    }

    _vocalSuppressionLevel = level.clamp(0.0, 1.0);
    volumeval = _vocalSuppressionLevel;

    final range = eqMaxVal - eqMinVal;
    // Maximum reduction is 60% of the range (less aggressive)
    final maxReduction = range * 0.6;

    for (int i = 0; i < bands.length && i < _centerFrequencies.length; i++) {
      final freq = _centerFrequencies[i];
      final suppressionFactor = _getVocalSuppressionFactor(freq);

      int targetLevel;

      if (suppressionFactor > 0.01) {
        // Apply reduction based on suppression factor and user level
        final reduction = level * suppressionFactor * maxReduction;
        targetLevel = (_originalBandLevels[i] - reduction)
            .round()
            .clamp(eqMinVal.toInt(), eqMaxVal.toInt());
      } else {
        // Keep non-vocal bands at original levels
        targetLevel = _originalBandLevels[i];

        // Optional: Slightly boost bass and treble to compensate
        if (level > 0.3) {
          if (freq < _bassThreshold) {
            // Boost low bass slightly
            final boost = level * 0.15 * range;
            targetLevel = (_originalBandLevels[i] + boost)
                .round()
                .clamp(eqMinVal.toInt(), eqMaxVal.toInt());
          } else if (freq > _trebleThreshold) {
            // Boost high treble slightly
            final boost = level * 0.1 * range;
            targetLevel = (_originalBandLevels[i] + boost)
                .round()
                .clamp(eqMinVal.toInt(), eqMaxVal.toInt());
          }
        }
      }

      if (bands[i] != targetLevel) {
        bands[i] = targetLevel;
        try {
          await EqualizerFlutter.setBandLevel(i, targetLevel);
        } catch (e) {
          debugPrint('EqualizerProvider: Error setting band $i level: $e');
        }
      }
    }

    custom = true;
    _saveVocalSuppression();
    notifyListeners();
  }

  /// Apply vocal suppression during drag (no persistence, no notification)
  void applyVocalSuppressionDuringDrag(double level) {
    if (bands.isEmpty || _centerFrequencies.isEmpty) {
      debugPrint('EqualizerProvider: applyVocalSuppressionDuringDrag skipped - '
          'bands: ${bands.length}, centerFreqs: ${_centerFrequencies.length}');
      return;
    }

    // Vocal suppression requires native EQ to be enabled
    if (!isEqEnabled) {
      isEqEnabled = true;
      _readyEqualiser(true);
      _saveIsEqEnabled();
    }

    _vocalSuppressionLevel = level.clamp(0.0, 1.0);
    volumeval = _vocalSuppressionLevel;

    final range = eqMaxVal - eqMinVal;
    final maxReduction = range * 0.6;

    for (int i = 0; i < bands.length && i < _centerFrequencies.length; i++) {
      final freq = _centerFrequencies[i];
      final suppressionFactor = _getVocalSuppressionFactor(freq);

      int targetLevel;

      if (suppressionFactor > 0.01) {
        final reduction = level * suppressionFactor * maxReduction;
        targetLevel = (_originalBandLevels[i] - reduction)
            .round()
            .clamp(eqMinVal.toInt(), eqMaxVal.toInt());
      } else {
        targetLevel = _originalBandLevels[i];

        if (level > 0.3) {
          if (freq < _bassThreshold) {
            final boost = level * 0.15 * range;
            targetLevel = (_originalBandLevels[i] + boost)
                .round()
                .clamp(eqMinVal.toInt(), eqMaxVal.toInt());
          } else if (freq > _trebleThreshold) {
            final boost = level * 0.1 * range;
            targetLevel = (_originalBandLevels[i] + boost)
                .round()
                .clamp(eqMinVal.toInt(), eqMaxVal.toInt());
          }
        }
      }

      if (bands[i] != targetLevel) {
        bands[i] = targetLevel;
        try {
          EqualizerFlutter.setBandLevel(i, targetLevel);
        } catch (e) {
          debugPrint('EqualizerProvider: Error during drag: $e');
        }
      }
    }

    custom = true;
  }

  /// Reset vocal suppression - restore all bands to original levels
  Future<void> resetVocalSuppression() async {
    if (bands.isEmpty || _originalBandLevels.isEmpty) return;

    _vocalSuppressionLevel = 0.0;
    volumeval = 0.0;

    for (int i = 0; i < bands.length && i < _originalBandLevels.length; i++) {
      if (bands[i] != _originalBandLevels[i]) {
        bands[i] = _originalBandLevels[i];
        try {
          await EqualizerFlutter.setBandLevel(i, _originalBandLevels[i]);
        } catch (e) {
          debugPrint('EqualizerProvider: Error resetting band $i: $e');
        }
      }
    }

    custom = true;
    _saveVocalSuppression();
    notifyListeners();
  }

  /// Store current band levels as original (call before applying vocal suppression)
  void storeOriginalBandLevels() {
    if (bands.isNotEmpty) {
      _originalBandLevels = List<int>.from(bands);
      debugPrint(
          'EqualizerProvider: Stored original band levels: $_originalBandLevels');
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // MIN/MAX EQ
  // ═══════════════════════════════════════════════════════════════════════════

  void _setMinMaxEq() {
    if (bandLevelRange.length >= 2) {
      eqMinVal = bandLevelRange[0].toDouble();
      eqMaxVal = bandLevelRange[1].toDouble();
      notifyListeners();
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PERSISTENCE - LOAD
  // ═══════════════════════════════════════════════════════════════════════════

  Future<void> _loadMinimalSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      final savedPitch = prefs.getDouble(_kPitchKey);
      final savedBass = prefs.getDouble(_kBassKey);
      final savedIsEqEnabled = prefs.getBool(_kIsEqEnabledKey);
      final savedVocalSuppression = prefs.getDouble(_kVocalSuppressionKey);
      
      var changed = false;
      
      if (savedPitch != null) {
        pitchval = savedPitch;
        changed = true;
      }
      if (savedBass != null) {
        bassval = savedBass;
        changed = true;
      }
      if (savedIsEqEnabled != null) {
        isEqEnabled = savedIsEqEnabled;
        changed = true;
      }
      if (savedVocalSuppression != null) {
        _vocalSuppressionLevel = savedVocalSuppression;
        volumeval = savedVocalSuppression;
        changed = true;
      }
      
      if (changed) notifyListeners();
    } catch (e) {
      debugPrint('EqualizerProvider: _loadMinimalSettings error: $e');
    }
  }

  Future<void> loadSavedSettings() async {
    try {
      debugPrint(
          'EqualizerProvider: loadSavedSettings() - fetching saved prefs');
      final prefs = await SharedPreferences.getInstance();
      
      final savedPitch = prefs.getDouble(_kPitchKey);
      final savedBass = prefs.getDouble(_kBassKey);
      final savedPreset = prefs.getString(_kPresetKey);
      final savedCustom = prefs.getBool(_kCustomKey);
      final savedIsEqEnabled = prefs.getBool(_kIsEqEnabledKey);
      final savedVocalSuppression = prefs.getDouble(_kVocalSuppressionKey);
      final savedBands = prefs.getStringList(_kBandsKey);

      if (savedPitch != null) pitchval = savedPitch;
      if (savedBass != null) bassval = savedBass;
      if (savedPreset != null) currentp = savedPreset;
      if (savedCustom != null) custom = savedCustom;
      if (savedIsEqEnabled != null) isEqEnabled = savedIsEqEnabled;
      if (savedVocalSuppression != null) {
        _vocalSuppressionLevel = savedVocalSuppression;
        volumeval = savedVocalSuppression;
      }
      if (savedBands != null && savedBands.isNotEmpty) {
        bands = savedBands.map((s) => int.tryParse(s) ?? 0).toList();
        _originalBandLevels = List<int>.from(bands);
      }

      notifyListeners();
    } catch (e) {
      debugPrint('EqualizerProvider: loadSavedSettings error: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PERSISTENCE - SAVE
  // ═══════════════════════════════════════════════════════════════════════════

  Future<void> _savePitch() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_kPitchKey, pitchval);
    } catch (e) {
      debugPrint('EqualizerProvider: _savePitch error: $e');
    }
  }

  Future<void> _saveBass() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_kBassKey, bassval);
    } catch (e) {
      debugPrint('EqualizerProvider: _saveBass error: $e');
    }
  }

  Future<void> _saveVocalSuppression() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_kVocalSuppressionKey, _vocalSuppressionLevel);
    } catch (e) {
      debugPrint('EqualizerProvider: _saveVocalSuppression error: $e');
    }
  }

  Future<void> _savePreset() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kPresetKey, currentp);
      await prefs.setBool(_kCustomKey, custom);
    } catch (e) {
      debugPrint('EqualizerProvider: _savePreset error: $e');
    }
  }

  Future<void> _saveIsEqEnabled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_kIsEqEnabledKey, isEqEnabled);
    } catch (e) {
      debugPrint('EqualizerProvider: _saveIsEqEnabled error: $e');
    }
  }

  Future<void> _saveBands() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(
          _kBandsKey, bands.map((b) => b.toString()).toList());
    } catch (e) {
      debugPrint('EqualizerProvider: _saveBands error: $e');
    }
  }
}
