import 'package:equalizer_flutter/equalizer_flutter.dart';
import 'package:equalizer_flutter_custom/src/EqalizerProvider/EqualizerProvider.dart';
import 'package:equalizer_flutter_custom/src/Customeq.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sleek_circular_slider/sleek_circular_slider.dart';

class CustomEqualizer extends StatefulWidget {
  const CustomEqualizer(
      {super.key,
      required this.playerSessionId,
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
      required this.isEqEnabled,
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
      this.initialPitch,
      this.initialBass});

  final int playerSessionId;

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
  final TextStyle? presetsStyle;
  final BoxDecoration? presetsBoxDecoration;
  final Color? baseTextColor;
  final Widget? customSwitch;
  final bool isEqEnabled;
  final Color? appBarShadowColor;
  final String? appBarTitle;
  final IconThemeData? actionsIconTheme;
  final bool? automaticallyImplyLeading;
  final Color? appBarBgColor;
  final double? appbarElevation;
  final Widget? appBarLeading;
  final TextStyle? titleTextStyle;
  final Color? inActiveSwitchTrackColor;
  final Color? activeSwitchTrackColor;
  final Color? activeSwitchColor;
  final Color? bgColor;

  final double? sliderBoxPadding;
  
  /// Callback when pitch value changes - use this to apply pitch to audio player
  final void Function(double pitch)? onPitchChanged;

  /// Callback when bass value changes - use this to apply bass boost
  final void Function(double bass)? onBassChanged;

  /// Initial pitch value to sync with audio player's current pitch
  final double? initialPitch;

  /// Initial bass value to sync with audio player's current bass
  final double? initialBass;

  @override
  State<CustomEqualizer> createState() => _CustomEqualizerState();
}

class _CustomEqualizerState extends State<CustomEqualizer> {
  @override
  void initState() {
    super.initState();
    _iniaudio();
    WidgetsBinding.instance.addPostFrameCallback((_) => _deffun());
  }

  Future<void> _iniaudio() async {
    try {
      await EqualizerFlutter.init(widget.playerSessionId);
      if (!mounted) return;
      final provider = context.read<EqualizerProvider>();
      provider.setEqEnabled(widget.isEqEnabled);

      // Load persisted settings if available
      await provider.loadSavedSettings();

      // Check if values were actually loaded from storage by comparing with defaults
      bool pitchLoadedFromStorage =
          provider.pitchval != EqualizerProvider.defaultPitchVal;
      bool bassLoadedFromStorage =
          provider.bassval != EqualizerProvider.defaultBassVal;

      // If widget provided initial values (from audio player), apply them only if no saved values were loaded from storage
      if (widget.initialPitch != null && !pitchLoadedFromStorage) {
        provider.pitchval = widget.initialPitch!;
      }
      if (widget.initialBass != null && !bassLoadedFromStorage) {
        provider.bassval = widget.initialBass!;
      }

      // Default to Custom unless a preset has been selected previously
      if (provider.currentp.isEmpty) {
        provider.custom = true;
        provider.currentp = 'Custom';
      }

      await provider.getPresest();

      // Ensure saved preset still exists else fall back to Custom
      provider.validatePresetAgainstAvailable();

      await provider.fetchBandLevels(); // This populates the bands array
      print(
          'CustomEqualizer: Init complete, bands: ${provider.bands.length}, pitch: ${provider.pitchval}, bass: ${provider.bassval}, preset: ${provider.currentp}');
    } catch (e) {
      print('CustomEqualizer: Init error: $e');
    }
  }

  void _deffun() {
    context.read<EqualizerProvider>().setEqEnabled(widget.isEqEnabled);
  }

  // Preset handling
  void _setPreset(BuildContext context, String presetName) async {
    try {
      print('CustomEqualizer: Setting preset to: $presetName');
      final provider = context.read<EqualizerProvider>();
      await provider.setPresets(presetName);
      print('CustomEqualizer: Preset $presetName applied successfully');
    } catch (e) {
      print('CustomEqualizer: Error setting preset $presetName: $e');
    }
  }

  String dropdownValue = 'Dog';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.appBarTitle ?? "Equalizer"),
        shadowColor: widget.appBarShadowColor,
        actionsIconTheme: widget.actionsIconTheme,
        automaticallyImplyLeading: widget.automaticallyImplyLeading ?? true,
        backgroundColor: widget.appBarBgColor ??
            Theme.of(context).appBarTheme.backgroundColor ??
            Theme.of(context).colorScheme.surface,
        elevation: widget.appbarElevation,
        leading: widget.appBarLeading,
        titleTextStyle: widget.titleTextStyle,
        actions: [
          Consumer<EqualizerProvider>(
            builder: (context, value, child) {
              return widget.customSwitch ??
                  Switch(
                    value: value.isEqEnabled,
                    onChanged: (data) {
                      value.isEqEnabled
                          ? value.setEqEnabled(false)
                          : value.setEqEnabled(true);
                    },
                    inactiveTrackColor: widget.inActiveSwitchTrackColor ??
                        Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.12),
                    activeColor: widget.activeSwitchColor ??
                        Theme.of(context).colorScheme.onPrimary,
                    activeTrackColor: widget.activeSwitchTrackColor ??
                        Theme.of(context)
                            .colorScheme
                            .primary
                            .withValues(alpha: 0.5),
                    trackOutlineColor: WidgetStateProperty.resolveWith<Color?>(
                      (Set<WidgetState> states) {
                        if (states.contains(WidgetState.selected)) {
                          return Theme.of(context).colorScheme.primary;
                        }
                        return null;
                      },
                    ),
                  );
            },
          )
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              widget.bgColor ?? Theme.of(context).colorScheme.surface,
              (widget.bgColor ?? Theme.of(context).colorScheme.surface)
                  .withValues(alpha: 0.95),
            ],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Content
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  // Presets dropdown - use Consumer to always get latest state
                  Consumer<EqualizerProvider>(
                    builder: (context, provider, child) {
                      if (provider.presets.isEmpty) {
                        // Load presets if not yet loaded
                        provider.getPresest();
                        return const SizedBox();
                      }
                      final presets = provider.presets;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.library_music_rounded,
                                    size: 20,
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                  ),
                                  const SizedBox(width: 8),
                                  Text('Presets',
                                      style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurfaceVariant)),
                                ],
                              ),
                          const SizedBox(height: 12),
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Theme.of(context)
                                          .colorScheme
                                          .primaryContainer
                                          .withValues(alpha: 0.4),
                                      Theme.of(context)
                                          .colorScheme
                                          .surfaceContainerHighest,
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: Theme.of(context)
                                    .colorScheme
                                        .primary
                                        .withValues(alpha: 0.3),
                                    width: 1.5,
                              ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .primary
                                          .withValues(alpha: 0.1),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                            ),
                            child: DropdownButton<String>(
                              value: presets.contains(provider.currentp)
                                  ? provider.currentp
                                  : (provider.custom ? null : presets.first),
                              hint: Text('Custom',
                                  style: TextStyle(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant)),
                              isExpanded: true,
                              underline: const SizedBox(),
                              dropdownColor:
                                  Theme.of(context).colorScheme.surface,
                              icon: Icon(
                                Icons.arrow_drop_down_rounded,
                                color: Theme.of(context).colorScheme.primary,
                                size: 28,
                              ),
                              items: presets
                                  .map((p) => DropdownMenuItem<String>(
                                        value: p,
                                        child: Container(
                                          decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(12),
                                          ),
                                          child: Text(p,
                                              style: TextStyle(
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .onSurface,
                                                  fontSize: 14)),
                                        ),
                                      ))
                                  .toList(),
                              onChanged: provider.isEqEnabled
                                  ? (v) {
                                      if (v != null) {
                                        print(
                                            'CustomEqualizer: dropdown selected => $v');
                                        _setPreset(context, v);
                                      }
                                    }
                                  : null,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          if (provider.isApplyingPreset) ...[
                            const SizedBox(height: 12),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: LinearProgressIndicator(
                                minHeight: 4,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Theme.of(context).colorScheme.primary,
                                ),
                                backgroundColor: Theme.of(context)
                                    .colorScheme
                                    .surfaceContainerHighest,
                              ),
                            ),
                          ],
                          const SizedBox(height: 20),
                        ],
                      );
                    },
                  ),

                      // Bass and pitch controls section
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          children: [
                            Icon(
                              Icons.tune_rounded,
                              size: 20,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Audio Controls',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        // Bass
                        Expanded(
                          child: Consumer<EqualizerProvider>(
                            builder: (context, value, child) {
                              final bool enabled = value.isEqEnabled;
                              final Color activeColor =
                                  Theme.of(context).colorScheme.primary;
                              final Color inactiveColor = Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withValues(alpha: 0.2);

                              return Column(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .surfaceContainerLow,
                                      borderRadius: BorderRadius.circular(20),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .shadow
                                              .withValues(alpha: 0.05),
                                          blurRadius: 8,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: AnimatedOpacity(
                                      duration:
                                          const Duration(milliseconds: 250),
                                      opacity: enabled ? 1.0 : 0.4,
                                      child: SleekCircularSlider(
                                        min: 0,
                                        max: 1000,
                                        initialValue: value.bassval,
                                        key: ValueKey('bass-${value.bassval}'),
                                        appearance: CircularSliderAppearance(
                                              size: 140,
                                          customWidths: CustomSliderWidths(
                                                progressBarWidth: 10,
                                                trackWidth: 5,
                                                handlerSize: 12,
                                          ),
                                          customColors: CustomSliderColors(
                                            dotColor: enabled
                                                ? activeColor
                                                : Theme.of(context)
                                                    .colorScheme
                                                    .onSurface
                                                    .withValues(alpha: 0.3),
                                                progressBarColors: enabled
                                                    ? [
                                                        activeColor,
                                                        activeColor.withValues(
                                                            alpha: 0.7),
                                                      ]
                                                    : [Colors.transparent],
                                            trackColor: inactiveColor,
                                            trackColors: [
                                              Theme.of(context)
                                                  .colorScheme
                                                  .primary
                                                  .withValues(alpha: 0.2),
                                              Theme.of(context)
                                                  .colorScheme
                                                  .secondary
                                                  .withValues(alpha: 0.2),
                                            ],
                                                hideShadow: false,
                                          ),
                                          infoProperties: InfoProperties(
                                            mainLabelStyle: TextStyle(
                                                  fontSize: 24,
                                                  fontWeight: FontWeight.bold,
                                              color: enabled
                                                      ? activeColor
                                                  : Theme.of(context)
                                                      .colorScheme
                                                      .onSurface
                                                          .withValues(
                                                              alpha: 0.4),
                                            ),
                                            topLabelStyle: TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w600,
                                                  letterSpacing: 1.2,
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .onSurfaceVariant,
                                            ),
                                            topLabelText: 'BASS',
                                            modifier: (double val) =>
                                                '${(val / 10).round()}%',
                                          ),
                                        ),
                                            onChange: enabled
                                            ? (val) {
                                                value.setbassval(val);
                                                  }
                                                : null,
                                            onChangeEnd: enabled
                                                ? (val) {
                                                widget.onBassChanged?.call(val);
                                              }
                                            : null,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                      SizedBox(
                                        height: 44,
                                        child: Center(
                                          child: AnimatedOpacity(
                                            opacity: (enabled &&
                                                    value.bassval !=
                                                        EqualizerProvider
                                                            .defaultBassVal)
                                                ? 1.0
                                                : 0.0,
                                            duration: const Duration(
                                                milliseconds: 200),
                                            child: AnimatedScale(
                                              scale: (enabled &&
                                                      value.bassval !=
                                                          EqualizerProvider
                                                              .defaultBassVal)
                                                  ? 1.0
                                                  : 0.8,
                                              duration: const Duration(
                                                  milliseconds: 200),
                                              child: Material(
                                                color: Colors.transparent,
                                                child: InkWell(
                                                  borderRadius:
                                                      BorderRadius.circular(20),
                                                  onTap: () {
                                                    value.resetBass();
                                                    widget.onBassChanged?.call(
                                                        EqualizerProvider
                                                            .defaultBassVal);
                                                  },
                                                  child: Container(
                                                    padding:
                                                        const EdgeInsets.all(
                                                            10),
                                                    decoration: BoxDecoration(
                                                      gradient: LinearGradient(
                                                        colors: [
                                                          Theme.of(context)
                                                              .colorScheme
                                                              .primaryContainer,
                                                          Theme.of(context)
                                                              .colorScheme
                                                              .primaryContainer
                                                              .withValues(
                                                                  alpha: 0.7),
                                                        ],
                                                      ),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              20),
                                                      boxShadow: [
                                                        BoxShadow(
                                                          color:
                                                              Theme.of(context)
                                                                  .colorScheme
                                                                  .primary
                                                                  .withValues(
                                                                      alpha:
                                                                          0.2),
                                                          blurRadius: 8,
                                                          offset: const Offset(
                                                              0, 2),
                                                        ),
                                                      ],
                                                    ),
                                                    child: Icon(
                                                      Icons.restart_alt_rounded,
                                                      size: 20,
                                                      color: Theme.of(context)
                                                          .colorScheme
                                                          .primary,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                ],
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 24),

                        // Pitch
                        Expanded(
                          child: Consumer<EqualizerProvider>(
                            builder: (context, value, child) {
                              final bool enabled = value.isEqEnabled;
                              final Color activeColor =
                                  Theme.of(context).colorScheme.secondary;
                              final Color inactiveColor = Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withValues(alpha: 0.2);

                              return Column(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .surfaceContainerLow,
                                      borderRadius: BorderRadius.circular(20),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Theme.of(context)
                                              .colorScheme
                                              .shadow
                                              .withValues(alpha: 0.05),
                                          blurRadius: 8,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: AnimatedOpacity(
                                      duration:
                                          const Duration(milliseconds: 250),
                                      opacity: enabled ? 1.0 : 0.4,
                                      child: SleekCircularSlider(
                                        min: 0.5,
                                        max: 2.0,
                                        initialValue: value.pitchval,
                                        key:
                                            ValueKey('pitch-${value.pitchval}'),
                                        appearance: CircularSliderAppearance(
                                              size: 140,
                                          customWidths: CustomSliderWidths(
                                                progressBarWidth: 10,
                                                trackWidth: 5,
                                                handlerSize: 12,
                                          ),
                                          customColors: CustomSliderColors(
                                            dotColor: enabled
                                                ? activeColor
                                                : Theme.of(context)
                                                    .colorScheme
                                                    .onSurface
                                                    .withValues(alpha: 0.3),
                                                progressBarColors: enabled
                                                    ? [
                                                        activeColor,
                                                        activeColor.withValues(
                                                            alpha: 0.7),
                                                      ]
                                                    : [Colors.transparent],
                                            trackColor: inactiveColor,
                                            trackColors: [
                                              Theme.of(context)
                                                  .colorScheme
                                                  .primary
                                                  .withValues(alpha: 0.2),
                                              Theme.of(context)
                                                  .colorScheme
                                                  .secondary
                                                  .withValues(alpha: 0.2),
                                            ],
                                                hideShadow: false,
                                          ),
                                          infoProperties: InfoProperties(
                                            mainLabelStyle: TextStyle(
                                                  fontSize: 24,
                                                  fontWeight: FontWeight.bold,
                                              color: enabled
                                                      ? activeColor
                                                  : Theme.of(context)
                                                      .colorScheme
                                                      .onSurface
                                                          .withValues(
                                                              alpha: 0.4),
                                            ),
                                            topLabelStyle: TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w600,
                                                  letterSpacing: 1.2,
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .onSurfaceVariant,
                                            ),
                                            topLabelText: 'PITCH',
                                            modifier: (double val) =>
                                                '${val.toStringAsFixed(2)}x',
                                          ),
                                        ),
                                            onChange: enabled
                                            ? (val) {
                                                value.setpitchval(val);
                                                  }
                                                : null,
                                            onChangeEnd: enabled
                                                ? (val) {
                                                widget.onPitchChanged
                                                    ?.call(val);
                                              }
                                            : null,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                      SizedBox(
                                        height: 44,
                                        child: Center(
                                          child: AnimatedOpacity(
                                            opacity: (enabled &&
                                                    value.pitchval !=
                                                        EqualizerProvider
                                                            .defaultPitchVal)
                                                ? 1.0
                                                : 0.0,
                                            duration: const Duration(
                                                milliseconds: 200),
                                            child: AnimatedScale(
                                              scale: (enabled &&
                                                      value.pitchval !=
                                                          EqualizerProvider
                                                              .defaultPitchVal)
                                                  ? 1.0
                                                  : 0.8,
                                              duration: const Duration(
                                                  milliseconds: 200),
                                              child: Material(
                                                color: Colors.transparent,
                                                child: InkWell(
                                                  borderRadius:
                                                      BorderRadius.circular(20),
                                                  onTap: () {
                                                    value.resetPitch();
                                                    widget.onPitchChanged?.call(
                                                        EqualizerProvider
                                                            .defaultPitchVal);
                                                  },
                                                  child: Container(
                                                    padding:
                                                        const EdgeInsets.all(
                                                            10),
                                                    decoration: BoxDecoration(
                                                      gradient: LinearGradient(
                                                        colors: [
                                                          Theme.of(context)
                                                              .colorScheme
                                                              .secondaryContainer,
                                                          Theme.of(context)
                                                              .colorScheme
                                                              .secondaryContainer
                                                              .withValues(
                                                                  alpha: 0.7),
                                                        ],
                                                      ),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              20),
                                                      boxShadow: [
                                                        BoxShadow(
                                                          color:
                                                              Theme.of(context)
                                                                  .colorScheme
                                                                  .secondary
                                                                  .withValues(
                                                                      alpha:
                                                                          0.2),
                                                          blurRadius: 8,
                                                          offset: const Offset(
                                                              0, 2),
                                                        ),
                                                      ],
                                                    ),
                                                    child: Icon(
                                                      Icons.restart_alt_rounded,
                                                      size: 20,
                                                      color: Theme.of(context)
                                                          .colorScheme
                                                          .secondary,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                ],
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
              
                  const SizedBox(height: 16),
              
                  // Bands section - direct FutureBuilder like original package
                  FutureBuilder<List<int>>(
                    future: EqualizerFlutter.getBandLevelRange(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
              
                      if (!snapshot.hasData || snapshot.data!.length < 2) {
                        return Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surfaceVariant,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text('Equalizer unavailable',
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface)),
                              const SizedBox(height: 8),
                              Text(
                                  'Session ID: ${widget.playerSessionId}\n'
                                  'Data: ${snapshot.data}\n'
                                  'Error: ${snapshot.error}\n'
                                  'Make sure audio is playing and try reopening.',
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface
                                          .withValues(alpha: 0.7))),
                            ],
                          ),
                        );
                      }
              
                      // We have valid band range data
                      return Customeq(
                        snapshot.data![0].toDouble(),
                        snapshot.data![1].toDouble(),
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
                      );
                    },
                  ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
