// lib/packages/equalizer_flutter_custom/lib/src/custom_equalizer.dart

import 'package:equalizer_flutter/equalizer_flutter.dart';
import 'package:equalizer_flutter_custom/src/EqalizerProvider/EqualizerProvider.dart';
import 'package:equalizer_flutter_custom/src/Customeq.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class CustomEqualizer extends StatefulWidget {
  const CustomEqualizer({
    super.key,
    required this.playerSessionId,
    required this.isEqEnabled,
    this.sliderBoxHeight,
    this.sliderBoxBackgroundColor,
    this.sliderBoxBorderRadius,
    this.inactiveTrackBar,
    this.midPointBgColor,
    this.midPointColorActive,
    this.midPointColorInactive,
    this.midPointIcon,
    this.activeDisabledTrackBarColor,
    this.inactiveDisabledTrackBarColor,
    this.activeTrackBarMaxColor,
    this.activeTrackBarMinColor,
    this.dragIndicatorActiveColor,
    this.dragIndicatorInactiveColor,
    this.bandTextColor,
    this.bandTextFontSize,
    this.presetsStyle,
    this.presetsBoxDecoration,
    this.baseTextColor,
    this.customSwitch,
    this.actionsIconTheme,
    this.appBarBgColor,
    this.appBarLeading,
    this.appBarShadowColor,
    this.appBarTitle,
    this.appbarElevation,
    this.automaticallyImplyLeading,
    this.titleTextStyle,
    this.inActiveSwitchTrackColor,
    this.activeSwitchTrackColor,
    this.activeSwitchColor,
    this.bgColor,
    this.sliderBoxPadding,
    this.onPitchChanged,
    this.onBassChanged,
    this.onVolumeChanged,
    this.initialPitch,
    this.initialBass,
    this.showAudioControlsButton = true,
  });

  final int playerSessionId;
  final bool isEqEnabled;

  // Slider customization
  final double? sliderBoxHeight;
  final Color? sliderBoxBackgroundColor;
  final BorderRadius? sliderBoxBorderRadius;
  final Color? inactiveTrackBar;
  final Color? midPointBgColor;
  final Color? midPointColorActive;
  final Color? midPointColorInactive;
  final IconData? midPointIcon;
  final Color? activeDisabledTrackBarColor;
  final Color? inactiveDisabledTrackBarColor;
  final Color? activeTrackBarMaxColor;
  final Color? activeTrackBarMinColor;
  final Color? dragIndicatorActiveColor;
  final Color? dragIndicatorInactiveColor;
  final Color? bandTextColor;
  final double? bandTextFontSize;
  final double? sliderBoxPadding;

  // Preset customization
  final TextStyle? presetsStyle;
  final BoxDecoration? presetsBoxDecoration;

  // General appearance
  final Color? baseTextColor;
  final Widget? customSwitch;
  final Color? bgColor;

  // AppBar
  final Color? appBarShadowColor;
  final String? appBarTitle;
  final IconThemeData? actionsIconTheme;
  final bool? automaticallyImplyLeading;
  final Color? appBarBgColor;
  final double? appbarElevation;
  final Widget? appBarLeading;
  final TextStyle? titleTextStyle;

  // Switch colors
  final Color? inActiveSwitchTrackColor;
  final Color? activeSwitchTrackColor;
  final Color? activeSwitchColor;

  // Callbacks
  final void Function(double pitch)? onPitchChanged;
  final void Function(double bass)? onBassChanged;
  final void Function(double volume)? onVolumeChanged;

  // Initial values
  final double? initialPitch;
  final double? initialBass;

  // Controls visibility
  final bool showAudioControlsButton;

  @override
  State<CustomEqualizer> createState() => _CustomEqualizerState();
}

class _CustomEqualizerState extends State<CustomEqualizer> {
  late Future<_InitResult> _initFuture;
  bool _initStarted = false;

  @override
  void initState() {
    super.initState();
    _initFuture = _initialize();
  }

  @override
  void didUpdateWidget(covariant CustomEqualizer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.playerSessionId != widget.playerSessionId) {
      _initStarted = false;
      _initFuture = _initialize();
    }
  }

  Future<_InitResult> _initialize() async {
    final provider = context.read<EqualizerProvider>();

    // If already initialized, skip native init and use cached values
    if (provider.EqInit && provider.bandLevelRange.length >= 2) {
      debugPrint('EQ: Already initialized, using cached values');

      // Just sync the native enabled state
      try {
        EqualizerFlutter.setEnabled(provider.isEqEnabled);
      } catch (e) {
        debugPrint('EQ: Error syncing enabled state: $e');
      }

      return _InitResult(
        minLevel: provider.bandLevelRange[0].toDouble(),
        maxLevel: provider.bandLevelRange[1].toDouble(),
      );
    }

    // First time initialization - do full native init
    debugPrint('EQ: First initialization, calling native init');

    // 1. Init native equalizer
    try {
      await EqualizerFlutter.init(widget.playerSessionId).timeout(
        const Duration(seconds: 3),
      );
    } catch (e) {
      debugPrint('EQ: Native init failed: $e');
    }

    if (!mounted) return _InitResult.failed();

    // 2. Get band range
    List<int> bandRange;
    try {
      bandRange = await EqualizerFlutter.getBandLevelRange();
      if (bandRange.length < 2) return _InitResult.failed();
    } catch (e) {
      debugPrint('EQ: getBandLevelRange failed: $e');
      return _InitResult.failed();
    }

    if (!mounted) return _InitResult.failed();

    // 3. Load provider state
    if (!_initStarted) {
      _initStarted = true;
      await _loadProviderState(provider, bandRange);
    }

    return _InitResult(
      minLevel: bandRange[0].toDouble(),
      maxLevel: bandRange[1].toDouble(),
    );
  }

  Future<void> _loadProviderState(
      EqualizerProvider provider, List<int> bandRange) async {
    // Set min/max values
    provider.bandLevelRange = bandRange;

    // Only load persisted settings on first initialization
    if (!provider.EqInit) {
      // Load persisted EQ settings
      await provider.loadSavedSettings();

      // Apply widget-provided initial values only if nothing was persisted
      if (widget.initialPitch != null &&
          provider.pitchval == EqualizerProvider.defaultPitchVal) {
        provider.pitchval = widget.initialPitch!;
      }
      if (widget.initialBass != null &&
          provider.bassval == EqualizerProvider.defaultBassVal) {
        provider.bassval = widget.initialBass!;
      }

      // Default preset
      if (provider.currentp.isEmpty) {
        provider.custom = true;
        provider.currentp = 'Custom';
      }
    }

    // Always refresh presets and bands from native EQ
    try {
      await provider.getPresest();
      provider.validatePresetAgainstAvailable();
      await provider.fetchBandLevels();

      // Store original band levels for vocal suppression
      provider.storeOriginalBandLevels();

      // Sync native EQ enabled state with provider
      try {
        EqualizerFlutter.setEnabled(provider.isEqEnabled);
      } catch (e) {
        debugPrint('EQ: Error syncing enabled state: $e');
      }

      // Apply all band levels to native EQ if enabled
      if (provider.isEqEnabled) {
        await _applyAllBands(provider);

        // Reapply vocal suppression if it was enabled
        if (provider.vocalSuppressionLevel > 0.01) {
          await provider.applyVocalSuppression(provider.vocalSuppressionLevel);
        }
      }
    } catch (e) {
      debugPrint('EQ: Preset/band load error: $e');
    }

    // Mark as initialized so subsequent opens skip settings reload
    provider.EqInit = true;
  }

  Future<void> _applyAllBands(EqualizerProvider provider) async {
    for (int i = 0; i < provider.bands.length; i++) {
      try {
        await EqualizerFlutter.setBandLevel(i, provider.bands[i]);
      } catch (e) {
        debugPrint('EQ: Error setting band $i: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bgColor = widget.bgColor ?? cs.surface;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            bgColor,
            bgColor.withOpacity(0.95),
          ],
        ),
      ),
      child: FutureBuilder<_InitResult>(
        future: _initFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const _LoadingPlaceholder();
          }

          final result = snapshot.data;
          if (result == null || !result.isValid) {
            return _ErrorPlaceholder(
              sessionId: widget.playerSessionId,
              error: snapshot.error,
            );
          }

          return _EqualizerContent(
            minLevel: result.minLevel,
            maxLevel: result.maxLevel,
            widget: widget,
          );
        },
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// INIT RESULT
// ═══════════════════════════════════════════════════════════════════════════

class _InitResult {
  final double minLevel;
  final double maxLevel;
  final bool isValid;

  _InitResult({
    this.minLevel = 0,
    this.maxLevel = 0,
    this.isValid = true,
  });

  factory _InitResult.failed() => _InitResult(isValid: false);
}

// ═══════════════════════════════════════════════════════════════════════════
// EQUALIZER CONTENT
// ═══════════════════════════════════════════════════════════════════════════

class _EqualizerContent extends StatelessWidget {
  final double minLevel;
  final double maxLevel;
  final CustomEqualizer widget;

  const _EqualizerContent({
    required this.minLevel,
    required this.maxLevel,
    required this.widget,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _PresetsSection(),
              ],
            ),
          ),
          RepaintBoundary(
            child: Customeq(
              minLevel,
              maxLevel,
              widget.sliderBoxHeight,
              widget.sliderBoxBackgroundColor,
              widget.sliderBoxBorderRadius,
              widget.inactiveTrackBar,
              widget.midPointBgColor,
              widget.midPointColorActive,
              widget.midPointColorInactive,
              widget.midPointIcon,
              widget.activeDisabledTrackBarColor,
              widget.inactiveDisabledTrackBarColor,
              widget.activeTrackBarMaxColor,
              widget.activeTrackBarMinColor,
              widget.dragIndicatorActiveColor,
              widget.dragIndicatorInactiveColor,
              widget.bandTextColor,
              widget.bandTextFontSize,
              widget.sliderBoxPadding,
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// PRESETS SECTION
// ═══════════════════════════════════════════════════════════════════════════

class _PresetData {
  final List<String> presets;
  final String currentp;
  final bool custom;
  final bool isEqEnabled;
  final bool isApplyingPreset;

  const _PresetData({
    required this.presets,
    required this.currentp,
    required this.custom,
    required this.isEqEnabled,
    required this.isApplyingPreset,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! _PresetData) return false;
    if (other.currentp != currentp) return false;
    if (other.custom != custom) return false;
    if (other.isEqEnabled != isEqEnabled) return false;
    if (other.isApplyingPreset != isApplyingPreset) return false;
    if (other.presets.length != presets.length) return false;
    for (int i = 0; i < presets.length; i++) {
      if (other.presets[i] != presets[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(
        Object.hashAll(presets),
        currentp,
        custom,
        isEqEnabled,
        isApplyingPreset,
      );
}

class _PresetsSection extends StatelessWidget {
  const _PresetsSection();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Selector<EqualizerProvider, _PresetData>(
      selector: (_, p) => _PresetData(
        presets: p.presets,
        currentp: p.currentp,
        custom: p.custom,
        isEqEnabled: p.isEqEnabled,
        isApplyingPreset: p.isApplyingPreset,
      ),
      shouldRebuild: (prev, next) => prev != next,
      builder: (context, data, _) {
        if (data.presets.isEmpty) {
          return const SizedBox.shrink();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.library_music_rounded,
                  size: 20,
                  color: cs.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Presets',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurfaceVariant,
                  ),
                ),
                const Spacer(),
                _PresetDropdown(
                  presets: data.presets,
                  currentPreset: data.currentp,
                  isCustom: data.custom,
                  enabled: data.isEqEnabled,
                ),
              ],
            ),
            if (data.isApplyingPreset) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: LinearProgressIndicator(
                  minHeight: 4,
                  valueColor: AlwaysStoppedAnimation<Color>(cs.primary),
                  backgroundColor: cs.surfaceContainerHighest,
                ),
              ),
            ],
            const SizedBox(height: 20),
          ],
        );
      },
    );
  }
}

class _PresetDropdown extends StatelessWidget {
  final List<String> presets;
  final String currentPreset;
  final bool isCustom;
  final bool enabled;

  const _PresetDropdown({
    required this.presets,
    required this.currentPreset,
    required this.isCustom,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final String? dropdownValue;
    if (presets.contains(currentPreset)) {
      dropdownValue = currentPreset;
    } else if (isCustom) {
      dropdownValue = null;
    } else if (presets.isNotEmpty) {
      dropdownValue = presets.first;
    } else {
      dropdownValue = null;
    }

    return DropdownButton<String>(
      value: dropdownValue,
      hint: Text(
        'Custom',
        style: TextStyle(color: cs.onSurfaceVariant),
      ),
      isExpanded: false,
      underline: const SizedBox.shrink(),
      dropdownColor: cs.surface,
      icon: Icon(
        Icons.arrow_drop_down_rounded,
        color: cs.primary,
        size: 28,
      ),
      items: presets
          .map(
            (p) => DropdownMenuItem<String>(
              value: p,
              child: Text(
                p,
                style: TextStyle(
                  color: cs.onSurface,
                  fontSize: 14,
                ),
              ),
            ),
          )
          .toList(),
      onChanged: enabled
          ? (v) {
              if (v == null) return;
              final provider = context.read<EqualizerProvider>();
              // Store original before changing preset
              provider.storeOriginalBandLevels();
              provider.setPresets(v);
            }
          : null,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      borderRadius: BorderRadius.circular(12),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// LOADING PLACEHOLDER
// ═══════════════════════════════════════════════════════════════════════════

class _LoadingPlaceholder extends StatelessWidget {
  const _LoadingPlaceholder();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return SizedBox(
      height: 300,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 36,
              height: 36,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: cs.primary,
                strokeCap: StrokeCap.round,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Loading equalizer…',
              style: TextStyle(
                color: cs.onSurfaceVariant,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// ERROR PLACEHOLDER
// ═══════════════════════════════════════════════════════════════════════════

class _ErrorPlaceholder extends StatelessWidget {
  final int sessionId;
  final Object? error;

  const _ErrorPlaceholder({
    required this.sessionId,
    this.error,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cs.errorContainer.withOpacity(0.3),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: cs.error.withOpacity(0.2),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.equalizer_rounded,
              size: 40,
              color: cs.error.withOpacity(0.6),
            ),
            const SizedBox(height: 12),
            Text(
              'Equalizer unavailable',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Make sure audio is playing and try reopening.\n'
              'Session: $sessionId',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: cs.onSurface.withOpacity(0.6),
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
