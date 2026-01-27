import 'package:another_xlider/another_xlider.dart';
import 'package:another_xlider/models/handler.dart';
import 'package:another_xlider/models/trackbar.dart';
import 'package:equalizer_flutter_custom/src/EqalizerProvider/EqualizerProvider.dart';
import 'package:equalizer_flutter_custom/src/Themes/GlobalThemes.dart';
import 'package:flutter/material.dart';

import 'package:provider/provider.dart';

GlobalThemes globalThemes = GlobalThemes();

Widget CustomSlider(
  context,
  int bandId,
  int freq,
  min,
  max,
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
  return Expanded(
    child: Padding(
      padding: sliderBoxPadding != null
          ? EdgeInsets.all(sliderBoxPadding)
          : const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Column(
        children: [
          Container(
            height: sliderBoxHeight ?? 240,
            decoration: BoxDecoration(
              color: sliderBoxBackgroundColor ??
                  Theme.of(context).colorScheme.surface,
              borderRadius: sliderBoxBorderRadius ?? BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context)
                      .colorScheme
                      .shadow
                      .withValues(alpha: 0.1),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Consumer<EqualizerProvider>(
              builder: (context, value, child) {
                if (value.bands.length <= bandId) {
                  return const Center(
                      child: CircularProgressIndicator(strokeWidth: 2));
                }

                // Show loading overlay when applying preset
                Widget sliderContent = Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                  child: FlutterSlider(
                    key: ValueKey(
                        'band-${bandId}-${value.bands[bandId]}-${value.isApplyingPreset}'),
                    trackBar: FlutterSliderTrackBar(
                      inactiveTrackBar: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: inactiveTrackBar ??
                            Theme.of(context)
                                .colorScheme
                                .onSurface
                                .withValues(alpha: 0.1),
                      ),
                      centralWidget: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: midPointBgColor ??
                              Theme.of(context).colorScheme.surface,
                          border: Border.all(
                            color: value.isEqEnabled
                                ? (midPointColorActive ??
                                        Theme.of(context).colorScheme.primary)
                                    .withValues(alpha: 0.4)
                                : (midPointColorInactive ??
                                        Theme.of(context)
                                            .colorScheme
                                            .onSurface
                                            .withValues(alpha: 0.3))
                                    .withValues(alpha: 0.4),
                            width: 2,
                          ),
                        ),
                        child: Icon(
                          midPointIcon ?? Icons.graphic_eq_outlined,
                          size: 16,
                          color: value.isEqEnabled
                              ? midPointColorActive ??
                                  Theme.of(context).colorScheme.primary
                              : midPointColorInactive ??
                                  Theme.of(context)
                                      .colorScheme
                                      .onSurface
                                      .withValues(alpha: 0.5),
                        ),
                      ),
                      activeDisabledTrackBarColor:
                          activeDisabledTrackBarColor ??
                              Theme.of(context).colorScheme.surfaceVariant,
                      inactiveDisabledTrackBarColor:
                          inactiveDisabledTrackBarColor ??
                              Theme.of(context).colorScheme.surfaceVariant,
                      activeTrackBar: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        gradient: LinearGradient(
                          colors: value.bands[bandId].toDouble() >
                                  (max + min) / 2
                              ? [
                                  activeTrackBarMaxColor ??
                                      Theme.of(context).colorScheme.secondary,
                                  (activeTrackBarMaxColor ??
                                          Theme.of(context)
                                              .colorScheme
                                              .secondary)
                                      .withValues(alpha: 0.8),
                                ]
                              : [
                                  activeTrackBarMinColor ??
                                      Theme.of(context).colorScheme.primary,
                                  (activeTrackBarMinColor ??
                                          Theme.of(context).colorScheme.primary)
                                      .withValues(alpha: 0.8),
                                ],
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                        ),
                      ),
                    ),
                    axis: Axis.vertical,
                    jump: true,
                    visibleTouchArea: true,
                    disabled: !value.isEqEnabled,
                    handler: FlutterSliderHandler(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: value.isEqEnabled
                            ? [
                                BoxShadow(
                                  color: (Theme.of(context).colorScheme.primary)
                                      .withValues(alpha: 0.3),
                                  blurRadius: 16,
                                  spreadRadius: 4,
                                ),
                              ]
                            : [],
                      ),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: value.isEqEnabled
                              ? RadialGradient(
                                  colors: [
                                    Theme.of(context).colorScheme.primary,
                                    Theme.of(context).colorScheme.secondary,
                                  ],
                                )
                              : null,
                          color: value.isEqEnabled
                              ? null
                              : Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withValues(alpha: 0.3),
                          border: Border.all(
                            color: value.isEqEnabled
                                ? Theme.of(context)
                                    .colorScheme
                                    .primary
                                    .withValues(alpha: 0.7)
                                : Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withValues(alpha: 0.5),
                            width: 2,
                          ),
                        ),
                        child: Center(
                          child: Icon(
                            Icons.tune_rounded,
                            size: 18,
                            color: value.isEqEnabled
                                ? dragIndicatorActiveColor ?? Colors.white
                                : dragIndicatorInactiveColor ??
                                    Theme.of(context)
                                        .colorScheme
                                        .onSurface
                                        .withValues(alpha: 0.6),
                          ),
                        ),
                      ),
                    ),
                    values: [value.bands[bandId].toDouble()],
                    rtl: true,
                    max: max,
                    min: min,
                    onDragCompleted: (handlerIndex, lowerValue, upperValue) {
                      value.changeFreq(bandId, lowerValue.toInt());
                    },
                  ),
                );

                // Wrap with loading overlay when applying preset
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    sliderContent,
                    if (value.isApplyingPreset)
                      Container(
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .surface
                              .withValues(alpha: 0.7),
                          borderRadius: sliderBoxBorderRadius ??
                              BorderRadius.circular(20),
                        ),
                        child: const Center(
                          child: SizedBox(
                            width: 28,
                            height: 28,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          // Display the current value of the slider
          Consumer<EqualizerProvider>(
            builder: (context, value, child) {
              if (value.bands.length <= bandId) {
                return const SizedBox.shrink();
              }
              return Column(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      "${value.bands[bandId].toInt()}dB",
                      style: TextStyle(
                        fontSize: bandTextFontSize != null
                            ? bandTextFontSize! - 2
                            : 11,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      "${(freq / 1000).toStringAsFixed(freq >= 10000 ? 1 : 0)}kHz",
                      style: TextStyle(
                        fontSize: bandTextFontSize != null
                            ? bandTextFontSize! - 3
                            : 10,
                        fontWeight: FontWeight.w500,
                        color:
                            Theme.of(context).colorScheme.onSecondaryContainer,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    ),
  );
}
