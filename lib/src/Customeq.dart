// lib/packages/equalizer_flutter_custom/lib/src/Customeq.dart

import 'package:equalizer_flutter/equalizer_flutter.dart';
import 'package:equalizer_flutter_custom/src/CustomSlider.dart';
import 'package:equalizer_flutter_custom/src/EqalizerProvider/EqualizerProvider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Main equalizer widget that displays frequency band sliders.
class Customeq extends StatefulWidget {
  final double min;
  final double max;
  final double? sliderBoxHeight;
  final Color? sliderBoxBackgroundColor;
  final BorderRadiusGeometry? sliderBoxBorderRadius;
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

  const Customeq(
    this.min,
    this.max,
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
    this.sliderBoxPadding, {
    super.key,
  });

  @override
  State<Customeq> createState() => _CustomeqState();
}

class _CustomeqState extends State<Customeq> {
  late Future<List<int>> _centerFreqsFuture;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _centerFreqsFuture = _fetchCenterFrequencies();
  }

  Future<List<int>> _fetchCenterFrequencies() async {
    try {
      final freqs = await EqualizerFlutter.getCenterBandFreqs();
      debugPrint('Customeq: Fetched ${freqs.length} center frequencies: $freqs');
      return freqs;
    } catch (e) {
      debugPrint('Customeq: Error fetching center frequencies: $e');
      return [];
    }
  }

  void _initializeBands(EqualizerProvider provider, List<int> freqs) {
    if (_isInitialized) return;
    _isInitialized = true;

    if (provider.bands.length != freqs.length) {
      provider.bands = List<int>.filled(freqs.length, 0);
      
      if (provider.eqMinVal == -15 && provider.eqMaxVal == 15) {
        provider.eqMinVal = widget.min;
        provider.eqMaxVal = widget.max;
      }
      
      Future.microtask(() async {
        await provider.fetchBandLevels();
        provider.storeOriginalBandLevels();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<int>>(
      future: _centerFreqsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _LoadingIndicator();
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return _ErrorWidget(
            message: snapshot.hasError 
                ? 'Error loading frequencies' 
                : 'No frequency bands available',
          );
        }

        final freqs = snapshot.data!;

        return Selector<EqualizerProvider, _BandData>(
          selector: (_, p) => _BandData(
            bands: p.bands,
            isEqEnabled: p.isEqEnabled,
            bandsLength: p.bands.length,
          ),
          shouldRebuild: (prev, next) => prev != next,
          builder: (context, data, _) {
            final provider = context.read<EqualizerProvider>();
            
            _initializeBands(provider, freqs);

            if (data.bands.length < freqs.length) {
              return const _LoadingIndicator();
            }

            return _BandSlidersRow(
              freqs: freqs,
              min: widget.min,
              max: widget.max,
              sliderBoxHeight: widget.sliderBoxHeight,
              sliderBoxBackgroundColor: widget.sliderBoxBackgroundColor,
              sliderBoxBorderRadius: widget.sliderBoxBorderRadius,
              inactiveTrackBar: widget.inactiveTrackBar,
              midPointBgColor: widget.midPointBgColor,
              midPointColorActive: widget.midPointColorActive,
              midPointColorInactive: widget.midPointColorInactive,
              midPointIcon: widget.midPointIcon,
              activeDisabledTrackBarColor: widget.activeDisabledTrackBarColor,
              inactiveDisabledTrackBarColor: widget.inactiveDisabledTrackBarColor,
              activeTrackBarMaxColor: widget.activeTrackBarMaxColor,
              activeTrackBarMinColor: widget.activeTrackBarMinColor,
              dragIndicatorActiveColor: widget.dragIndicatorActiveColor,
              dragIndicatorInactiveColor: widget.dragIndicatorInactiveColor,
              bandTextColor: widget.bandTextColor,
              bandTextFontSize: widget.bandTextFontSize,
              sliderBoxPadding: widget.sliderBoxPadding,
            );
          },
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// DATA CLASS FOR SELECTOR
// ═══════════════════════════════════════════════════════════════════════════

class _BandData {
  final List<int> bands;
  final bool isEqEnabled;
  final int bandsLength;

  const _BandData({
    required this.bands,
    required this.isEqEnabled,
    required this.bandsLength,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! _BandData) return false;
    if (other.isEqEnabled != isEqEnabled) return false;
    if (other.bandsLength != bandsLength) return false;
    if (other.bands.length != bands.length) return false;
    for (int i = 0; i < bands.length; i++) {
      if (other.bands[i] != bands[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hash(
        Object.hashAll(bands),
        isEqEnabled,
        bandsLength,
      );
}

// ═══════════════════════════════════════════════════════════════════════════
// BAND SLIDERS ROW - FULL WIDTH
// ═══════════════════════════════════════════════════════════════════════════

class _BandSlidersRow extends StatelessWidget {
  final List<int> freqs;
  final double min;
  final double max;
  final double? sliderBoxHeight;
  final Color? sliderBoxBackgroundColor;
  final BorderRadiusGeometry? sliderBoxBorderRadius;
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

  const _BandSlidersRow({
    required this.freqs,
    required this.min,
    required this.max,
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
    this.sliderBoxPadding,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculate the width for each slider to fill the available space
        final availableWidth = constraints.maxWidth;
        final padding = sliderBoxPadding ?? 4.0;
        final totalPadding = padding * (freqs.length + 1);
        final sliderWidth = (availableWidth - totalPadding) / freqs.length;

        return SizedBox(
          width: availableWidth,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: List.generate(
              freqs.length,
              (index) => SizedBox(
                width: sliderWidth,
                child: RepaintBoundary(
                  child: _BandSliderWrapper(
                    index: index,
                    freq: freqs[index],
                    min: min,
                    max: max,
                    sliderBoxHeight: sliderBoxHeight,
                    sliderBoxBackgroundColor: sliderBoxBackgroundColor,
                    sliderBoxBorderRadius: sliderBoxBorderRadius,
                    inactiveTrackBar: inactiveTrackBar,
                    midPointBgColor: midPointBgColor,
                    midPointColorActive: midPointColorActive,
                    midPointColorInactive: midPointColorInactive,
                    midPointIcon: midPointIcon,
                    activeDisabledTrackBarColor: activeDisabledTrackBarColor,
                    inactiveDisabledTrackBarColor: inactiveDisabledTrackBarColor,
                    activeTrackBarMaxColor: activeTrackBarMaxColor,
                    activeTrackBarMinColor: activeTrackBarMinColor,
                    dragIndicatorActiveColor: dragIndicatorActiveColor,
                    dragIndicatorInactiveColor: dragIndicatorInactiveColor,
                    bandTextColor: bandTextColor,
                    bandTextFontSize: bandTextFontSize,
                    sliderBoxPadding: sliderBoxPadding,
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// SLIDER DATA - Used by individual slider wrapper selector
// ═══════════════════════════════════════════════════════════════════════════

class _SliderData {
  final int bandValue;
  final bool isEnabled;
  final double vocalLevel;

  const _SliderData({
    required this.bandValue,
    required this.isEnabled,
    required this.vocalLevel,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! _SliderData) return false;
    return other.bandValue == bandValue &&
        other.isEnabled == isEnabled &&
        other.vocalLevel == vocalLevel;
  }

  @override
  int get hashCode => Object.hash(bandValue, isEnabled, vocalLevel);
}

// ═══════════════════════════════════════════════════════════════════════════
// INDIVIDUAL BAND SLIDER WRAPPER
// ═══════════════════════════════════════════════════════════════════════════

class _BandSliderWrapper extends StatelessWidget {
  final int index;
  final int freq;
  final double min;
  final double max;
  final double? sliderBoxHeight;
  final Color? sliderBoxBackgroundColor;
  final BorderRadiusGeometry? sliderBoxBorderRadius;
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

  const _BandSliderWrapper({
    required this.index,
    required this.freq,
    required this.min,
    required this.max,
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
    this.sliderBoxPadding,
  });

  @override
  Widget build(BuildContext context) {
    return Selector<EqualizerProvider, _SliderData>(
      selector: (_, p) => _SliderData(
        bandValue: p.bands.length > index ? p.bands[index] : 0,
        isEnabled: p.isEqEnabled,
        vocalLevel: p.vocalSuppressionLevel,
      ),
      shouldRebuild: (prev, next) => prev != next,
      builder: (context, data, _) {
        return CustomSlider(
          context,
          index,
          freq,
          min,
          max,
          sliderBoxHeight,
          sliderBoxBackgroundColor,
          sliderBoxBorderRadius,
          inactiveTrackBar,
          midPointBgColor,
          midPointColorActive,
          midPointColorInactive,
          midPointIcon,
          activeDisabledTrackBarColor,
          inactiveDisabledTrackBarColor,
          activeTrackBarMaxColor,
          activeTrackBarMinColor,
          dragIndicatorActiveColor,
          dragIndicatorInactiveColor,
          bandTextColor,
          bandTextFontSize,
          sliderBoxPadding,
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// LOADING INDICATOR
// ═══════════════════════════════════════════════════════════════════════════

class _LoadingIndicator extends StatelessWidget {
  const _LoadingIndicator();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    
    return SizedBox(
      height: 200,
      child: Center(
        child: SizedBox(
          width: 32,
          height: 32,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            color: cs.primary,
            strokeCap: StrokeCap.round,
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// ERROR WIDGET
// ═══════════════════════════════════════════════════════════════════════════

class _ErrorWidget extends StatelessWidget {
  final String message;

  const _ErrorWidget({required this.message});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.error_outline_rounded,
            size: 40,
            color: cs.error.withOpacity(0.6),
          ),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: cs.onSurfaceVariant,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}