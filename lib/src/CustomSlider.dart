// lib/packages/equalizer_flutter_custom/lib/src/CustomSlider.dart

import 'package:equalizer_flutter_custom/src/EqalizerProvider/EqualizerProvider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

/// Creates a custom vertical slider for a single EQ band.
Widget CustomSlider(
  BuildContext context,
  int bandIndex,
  int frequency,
  double min,
  double max,
  double? sliderBoxHeight,
  Color? sliderBoxBackgroundColor,
  BorderRadiusGeometry? sliderBoxBorderRadius,
  Color? inactiveTrackBar,
  Color? midPointBgColor,
  Color? midPointColorActive,
  Color? midPointColorInactive,
  IconData? midPointIcon,
  Color? activeDisabledTrackBarColor,
  Color? inactiveDisabledTrackBarColor,
  Color? activeTrackBarMaxColor,
  Color? activeTrackBarMinColor,
  Color? dragIndicatorActiveColor,
  Color? dragIndicatorInactiveColor,
  Color? bandTextColor,
  double? bandTextFontSize,
  double? sliderBoxPadding,
) {
  return _CustomSliderWidget(
    bandIndex: bandIndex,
    frequency: frequency,
    min: min,
    max: max,
    sliderBoxHeight: sliderBoxHeight ?? 180,
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
    bandTextFontSize: bandTextFontSize ?? 10,
    sliderBoxPadding: sliderBoxPadding ?? 2,
  );
}

class _CustomSliderWidget extends StatefulWidget {
  final int bandIndex;
  final int frequency;
  final double min;
  final double max;
  final double sliderBoxHeight;
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
  final double bandTextFontSize;
  final double sliderBoxPadding;

  const _CustomSliderWidget({
    required this.bandIndex,
    required this.frequency,
    required this.min,
    required this.max,
    required this.sliderBoxHeight,
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
    required this.bandTextFontSize,
    required this.sliderBoxPadding,
  });

  @override
  State<_CustomSliderWidget> createState() => _CustomSliderWidgetState();
}

class _CustomSliderWidgetState extends State<_CustomSliderWidget> {
  double? _dragValue;
  bool _isDragging = false;

  String _formatFrequency(int freq) {
    if (freq >= 1000) {
      final kHz = freq / 1000;
      return '${kHz.toStringAsFixed(kHz.truncateToDouble() == kHz ? 0 : 1)}k';
    }
    return '$freq';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final provider = context.watch<EqualizerProvider>();

    final isEnabled = provider.isEqEnabled;
    final currentBandValue = provider.bands.length > widget.bandIndex
        ? provider.bands[widget.bandIndex].toDouble()
        : 0.0;

    final displayValue = _dragValue ?? currentBandValue;
    final clampedValue = displayValue.clamp(widget.min, widget.max);

    // Check if this is a vocal frequency band
    final isVocalBand = provider.isVocalFrequency(widget.frequency);
    final isPrimaryVocal = provider.isPrimaryVocalFrequency(widget.frequency);
    final vocalActive = provider.vocalSuppressionLevel > 0.01;

    // Colors
    final activeTrackColor =
        _getActiveTrackColor(cs, clampedValue, isVocalBand && vocalActive);
    final inactiveTrackColor =
        widget.inactiveTrackBar ?? cs.surfaceContainerHighest.withOpacity(0.6);
    final thumbColor = isEnabled
        ? (widget.dragIndicatorActiveColor ?? cs.primary)
        : (widget.dragIndicatorInactiveColor ??
            cs.onSurfaceVariant.withOpacity(0.3));
    final textColor = widget.bandTextColor ?? cs.onSurfaceVariant;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: widget.sliderBoxPadding),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Slider container - takes full width of parent
          Container(
            width: double.infinity,
            height: widget.sliderBoxHeight,
            decoration: BoxDecoration(
              color: widget.sliderBoxBackgroundColor ??
                  cs.surfaceContainerLow.withOpacity(0.5),
              borderRadius:
                  widget.sliderBoxBorderRadius ?? BorderRadius.circular(12),
              border: isVocalBand && vocalActive
                  ? Border.all(
                      color: isPrimaryVocal
                          ? cs.tertiary.withOpacity(0.5)
                          : cs.tertiary.withOpacity(0.25),
                      width: isPrimaryVocal ? 2 : 1.5,
                    )
                  : null,
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Mid-point indicator (0 dB line)
                Positioned(
                  top: widget.sliderBoxHeight / 2 - 1,
                  left: 4,
                  right: 4,
                  child: Container(
                    height: 2,
                    decoration: BoxDecoration(
                      color: widget.midPointBgColor ??
                          cs.outlineVariant.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
                ),
                
                // Vocal indicator icon for primary vocal bands
                if (isPrimaryVocal && vocalActive)
                  Positioned(
                    top: 8,
                    child: Icon(
                      Icons.mic_off_rounded,
                      size: 12,
                      color: cs.tertiary.withOpacity(0.6),
                    ),
                  ),
                
                // Vertical slider
                RotatedBox(
                  quarterTurns: -1,
                  child: SliderTheme(
                    data: SliderThemeData(
                      trackHeight: 5,
                      thumbShape: const RoundSliderThumbShape(
                        enabledThumbRadius: 9,
                        elevation: 2,
                        pressedElevation: 4,
                      ),
                      overlayShape: const RoundSliderOverlayShape(
                        overlayRadius: 18,
                      ),
                      activeTrackColor: isEnabled
                          ? activeTrackColor
                          : (widget.activeDisabledTrackBarColor ??
                              cs.onSurfaceVariant.withOpacity(0.15)),
                      inactiveTrackColor: isEnabled
                          ? inactiveTrackColor
                          : (widget.inactiveDisabledTrackBarColor ??
                              cs.onSurfaceVariant.withOpacity(0.08)),
                      thumbColor:
                          isVocalBand && vocalActive ? cs.tertiary : thumbColor,
                      overlayColor: (isVocalBand && vocalActive
                              ? cs.tertiary
                              : thumbColor)
                          .withOpacity(0.12),
                      trackShape: const RoundedRectSliderTrackShape(),
                    ),
                    child: Slider(
                      value: clampedValue,
                      min: widget.min,
                      max: widget.max,
                      onChanged: isEnabled
                          ? (value) {
                              setState(() {
                                _dragValue = value;
                                _isDragging = true;
                              });
                              provider.updateBandLevelDuringDrag(
                                widget.bandIndex,
                                value.round(),
                              );
                            }
                          : null,
                      onChangeEnd: isEnabled
                          ? (value) {
                              setState(() {
                                _dragValue = null;
                                _isDragging = false;
                              });
                              provider.changeFreq(
                                widget.bandIndex,
                                value.round(),
                              );
                              HapticFeedback.selectionClick();
                            }
                          : null,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 6),

          // Frequency label
          Text(
            _formatFrequency(widget.frequency),
            style: TextStyle(
              fontSize: widget.bandTextFontSize,
              fontWeight: FontWeight.w600,
              color: isVocalBand && vocalActive
                  ? cs.tertiary
                  : textColor.withOpacity(isEnabled ? 0.8 : 0.4),
            ),
          ),
          
          // dB value label
          AnimatedOpacity(
            duration: const Duration(milliseconds: 150),
            opacity: _isDragging || (clampedValue.abs() > 0.5) ? 1.0 : 0.0,
            child: Text(
              '${clampedValue.round() > 0 ? '+' : ''}${clampedValue.round()} dB',
              style: TextStyle(
                fontSize: widget.bandTextFontSize - 1,
                fontWeight: FontWeight.w500,
                color: activeTrackColor.withOpacity(isEnabled ? 0.9 : 0.4),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getActiveTrackColor(
      ColorScheme cs, double value, bool isVocalSuppressed) {
    if (isVocalSuppressed) {
      return cs.tertiary;
    }

    final maxColor = widget.activeTrackBarMaxColor ?? cs.primary;
    final minColor = widget.activeTrackBarMinColor ?? cs.error;

    if (value >= 0) {
      final t = value / widget.max;
      return Color.lerp(cs.primary, maxColor, t) ?? cs.primary;
    } else {
      final t = value.abs() / widget.min.abs();
      return Color.lerp(cs.primary, minColor, t) ?? cs.primary;
    }
  }
}
