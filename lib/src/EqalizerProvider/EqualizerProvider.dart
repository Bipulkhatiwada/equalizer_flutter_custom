import 'dart:collection';
import 'dart:async';
import 'package:equalizer_flutter/equalizer_flutter.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EqualizerProvider extends ChangeNotifier {
  List<int> bandLevelRange = [];
  bool isBandRangeLoading = false;

  late double eqMinVal = -15;
  late double eqMaxVal = 15;
  bool custom = true; // Default to custom until a preset is selected

  bool isEqEnabled = false;
  bool isApplyingPreset = false;

  late double bassval = 500;
  late double pitchval = 1.0;
  
  // Default values for reset
  static const double defaultBassVal = 500;
  static const double defaultPitchVal = 1.0;

  List<int> bands = [];

  bool EqInit = false;
  List<String> presets = [];
  String currentp = 'Custom'; // Default to Custom

  setBandRange(int id, int val) {
    if (bands.length <= id) {
      bands = List<int>.from(bands);
      while (bands.length <= id) {
        bands.add(0);
      }
    }
    bands[id] = val;
    notifyListeners();
  }

  setBandRangeBTN(int id, int val) {
    bands[id] = val;
    notifyListeners();
    // notifyListeners();
  }

  Future<void> changeFreq(int bandid, int lowervalue) async {
    print('EqualizerProvider: changeFreq - Band $bandid set to $lowervalue');
    EqualizerFlutter.setBandLevel(bandid, lowervalue);
    setBandRangeBTN(bandid, lowervalue);
    custom = true;
    // setMinMaxEq();
    print(
        'EqualizerProvider: changeFreq - Band $bandid updated, custom=$custom');
    notifyListeners();
  }

  void setEqEnabled(bool cond) {
    isEqEnabled = cond;
    readyEqualiser(cond);
    notifyListeners();
  }

  void readyEqualiser(bool cond) {
    EqualizerFlutter.setEnabled(cond);
    // bassBoost.setEnabled(enabled: cond);
    notifyListeners();
  }

  initEqalizer(androidAudioSessionId) async {
    if (androidAudioSessionId == null || androidAudioSessionId == 0) {
      print(
          'EqualizerProvider: audioSessionId is null/zero, cannot initialize');
      return;
    }

    try {
      print(
          'EqualizerProvider: Initializing with session ID: $androidAudioSessionId');
      await EqualizerFlutter.init(androidAudioSessionId);
      print('EqualizerProvider: EqualizerFlutter.init completed');
    } catch (e) {
      print('EqualizerProvider: init error: $e');
    }

    // Load presets and band levels
    await getPresest();
    await fetchBandLevels();

    EqInit = true;
    print('EqualizerProvider: Initialization complete, bands: ${bands.length}');
    notifyListeners();
  }

  /// Loads the min/max band level range once and sets related state
  Future<void> loadBandLevelRange() async {
    isBandRangeLoading = true;
    notifyListeners();
    try {
      print('EqualizerProvider: Loading band level range...');
      final range = await EqualizerFlutter.getBandLevelRange();
      print('EqualizerProvider: Got band range: $range');

      if (range.isEmpty || range.length < 2) {
        print(
            'EqualizerProvider: Band range empty or too short, retrying after delay...');
        await Future.delayed(const Duration(milliseconds: 200));
        final retryRange = await EqualizerFlutter.getBandLevelRange();
        print('EqualizerProvider: Retry got band range: $retryRange');

        if (retryRange.length >= 2) {
          bandLevelRange = List<int>.from(retryRange);
          setMinMaxEq();
          print(
              'EqualizerProvider: Band range loaded on retry: min=${bandLevelRange[0]}, max=${bandLevelRange[1]}');
        } else {
          print('EqualizerProvider: Band range still invalid after retry');
          bandLevelRange = [];
        }
      } else {
        bandLevelRange = List<int>.from(range);
        setMinMaxEq();
        print(
            'EqualizerProvider: Band range loaded successfully: min=${bandLevelRange[0]}, max=${bandLevelRange[1]}');
      }
    } catch (e, stackTrace) {
      print('EqualizerProvider: loadBandLevelRange error: $e');
      print('EqualizerProvider: Stack trace: $stackTrace');
      bandLevelRange = [];
    } finally {
      isBandRangeLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchBandLevels() async {
    try {
      print("EqualizerProvider: Starting fetchBandLevels");
      final centerFreqs = await EqualizerFlutter.getCenterBandFreqs();
      print("EqualizerProvider: Got center frequencies: ${centerFreqs.length}");

      if (bands.length != centerFreqs.length) {
        bands = List<int>.filled(centerFreqs.length, 0);
      }

      // Fetch all band levels concurrently for better performance
      final futures = <Future<int>>[];
      for (int i = 0; i < centerFreqs.length; i++) {
        futures.add(EqualizerFlutter.getBandLevel(i));
      }

      final results = await Future.wait(futures, eagerError: true);
      for (int i = 0; i < results.length; i++) {
        bands[i] = results[i];
      }

      print("EqualizerProvider: Fetched all band levels: $bands");
      notifyListeners();
    } catch (e) {
      print("Error fetching band levels: $e");
    }
  }

  static List<String> dedupePresets(List<String> raw) {
    // Remove duplicates while preserving order
    return LinkedHashSet<String>.from(raw).toList();
  }

  Future<List<String>> getPresest() async {
    try {
      print("EqualizerProvider: Starting getPresest");
      final raw = await EqualizerFlutter.getPresetNames();
      print("EqualizerProvider: Got preset names: $raw");
      presets = dedupePresets(raw);
      // Notify listeners so UI updates when presets arrive
      notifyListeners();
      print("EqualizerProvider: Updated presets: $presets");
      return presets;
    } catch (e) {
      print("Error getting presets: $e");
      return presets; // Return existing presets if there's an error
    }
  }

  /// Persisted settings
  static const _kPitchKey = 'eq_pitch';
  static const _kBassKey = 'eq_bass';
  static const _kPresetKey = 'eq_preset';
  static const _kCustomKey = 'eq_custom';

  Future<void> loadSavedSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedPitch = prefs.getDouble(_kPitchKey);
      final savedBass = prefs.getDouble(_kBassKey);
      final savedPreset = prefs.getString(_kPresetKey);
      final savedCustom = prefs.getBool(_kCustomKey);

      if (savedPitch != null) pitchval = savedPitch;
      if (savedBass != null) bassval = savedBass;
      if (savedPreset != null) currentp = savedPreset;
      if (savedCustom != null) custom = savedCustom;

      // If preset is saved but presets not yet loaded, validation occurs after getPresest()
      notifyListeners();
    } catch (e) {
      print('EqualizerProvider: loadSavedSettings error: $e');
    }
  }

  Future<void> _savePitch() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_kPitchKey, pitchval);
    } catch (e) {
      print('EqualizerProvider: _savePitch error: $e');
    }
  }

  Future<void> _saveBass() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble(_kBassKey, bassval);
    } catch (e) {
      print('EqualizerProvider: _saveBass error: $e');
    }
  }

  Future<void> _savePreset() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kPresetKey, currentp);
      await prefs.setBool(_kCustomKey, custom);
    } catch (e) {
      print('EqualizerProvider: _savePreset error: $e');
    }
  }

  /// Ensure that current preset is valid against available presets. If invalid, fallback to Custom.
  void validatePresetAgainstAvailable() {
    if (!presets.contains(currentp)) {
      // Only change to Custom if currentp isn't in presets
      custom = true;
      currentp = 'Custom';
      _savePreset();
      notifyListeners();
    }
  }

  Future<void> setPresets(String presetName) async {
    try {
      print('EqualizerProvider: setPresets - Setting preset to: $presetName');

      // Set applying preset flag to prevent UI flickering
      isApplyingPreset = true;
      notifyListeners();

      // Apply the preset with timeout to prevent hanging
      try {
        await EqualizerFlutter.setPreset(presetName).timeout(Duration(milliseconds: 1500));
      } catch (e) {
        if (e is TimeoutException) {
          print('EqualizerProvider: setPreset timed out after 1.5 seconds');
          // Continue execution even if timeout occurs
        } else {
          print('EqualizerProvider: setPreset failed with error: $e');
          // Continue execution even if error occurs
        }
      }

      // Update local state
      currentp = presetName;
      custom = false;
      print(
          'EqualizerProvider: setPresets - Preset $presetName applied, custom=$custom');

      // Persist the chosen preset
      await _savePreset();

      // Refresh band levels to ensure UI reflects device state
      // Use a faster approach - just get the current band levels without delays
      try {
        await fetchBandLevels().timeout(Duration(milliseconds: 1000));
      } catch (e) {
        if (e is TimeoutException) {
          print('EqualizerProvider: fetchBandLevels timed out after 1 second');
        } else {
          print('EqualizerProvider: fetchBandLevels failed with error: $e');
        }
        // Continue execution even if timeout occurs
      }

      // Validate current preset against loaded presets
      validatePresetAgainstAvailable();

      print('EqualizerProvider: setPresets - All band levels refreshed');

      // Small delay to ensure UI updates properly
      await Future.delayed(const Duration(milliseconds: 50));

    } catch (e) {
      print('EqualizerProvider: setPresets error: $e');
    } finally {
      // Always reset applying preset flag in finally block to ensure it's reset even if there are exceptions
      isApplyingPreset = false;
      notifyListeners();
    }
  }

  setbassval(val) {
    bassval = val.toDouble();
    // bassBoost.setStrength(strength: bassval.toInt());
    print("base:$bassval");
    custom = true; // user changed bass -> Custom
    _saveBass();
    _savePreset();
    notifyListeners();
  }

  void resetBass() {
    bassval = defaultBassVal;
    print('EqualizerProvider: bass reset to default');
    custom = true;
    _saveBass();
    _savePreset();
    notifyListeners();
  }

  setpitchval(val) {
    pitchval = val.toDouble();
    print('EqualizerProvider: pitch set to $pitchval');
    custom = true; // user changed pitch -> Custom
    _savePitch();
    _savePreset();
    notifyListeners();
  }

  void resetPitch() {
    pitchval = defaultPitchVal;
    print('EqualizerProvider: pitch reset to default');
    custom = true;
    _savePitch();
    _savePreset();
    notifyListeners();
  }

  setMinMaxEq() {
    eqMinVal = bandLevelRange[0].toDouble();
    eqMaxVal = bandLevelRange[1].toDouble();
    notifyListeners();
  }

}
