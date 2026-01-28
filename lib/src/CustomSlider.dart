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
          Consumer<EqualizerProvider>(
            builder: (context, value, child) {
              if (value.bands.length <= bandId) {
                return const SizedBox.shrink();
              }
              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withValues(alpha: 0.2),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  "${value.bands[bandId].toInt()}dB",
                  style: TextStyle(
                    fontSize:
                        bandTextFontSize != null ? bandTextFontSize - 2 : 12,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.primary,
                    letterSpacing: 0.5,
                  ),
                ),
              );
            },
          ),
          const SizedBox(
            height: 8,
          ),
          Container(
            height: sliderBoxHeight ?? 240,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  sliderBoxBackgroundColor ??
                      Theme.of(context).colorScheme.surface,
                  (sliderBoxBackgroundColor ??
                          Theme.of(context).colorScheme.surface)
                      .withValues(alpha: 0.95),
                ],
              ),
              borderRadius: sliderBoxBorderRadius ?? BorderRadius.circular(24),
              border: Border.all(
                color: Theme.of(context)
                    .colorScheme
                    .primary
                    .withValues(alpha: 0.15),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context)
                      .colorScheme
                      .primary
                      .withValues(alpha: 0.08),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                  spreadRadius: 2,
                ),
                BoxShadow(
                  color: Theme.of(context)
                      .colorScheme
                      .shadow
                      .withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Consumer<EqualizerProvider>(
              builder: (context, value, child) {
                // if (value.bands.length <= bandId) {
                //   return const Center(
                //       child: CircularProgressIndicator(strokeWidth: 2));
                // }

                // Show loading overlay when applying preset
                return Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                  child: FlutterSlider(
                      values: [value.bands[bandId].toDouble()],
                      rtl: true,
                      max: max,
                      min: min,
                      onDragCompleted: (handlerIndex, lowerValue, upperValue) {
                        value.changeFreq(bandId, lowerValue.toInt());
                      },
                    key: ValueKey(
                          'band-$bandId-${value.bands[bandId]}-${value.isApplyingPreset}'),
                    trackBar: FlutterSliderTrackBar(
                      inactiveTrackBar: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                          gradient: LinearGradient(
                            colors: [
                              (inactiveTrackBar ??
                                      Theme.of(context)
                                          .colorScheme
                                          .onSurface
                                          .withValues(alpha: 0.1))
                                  .withValues(alpha: 0.15),
                              (inactiveTrackBar ??
                                      Theme.of(context)
                                          .colorScheme
                                          .onSurface
                                          .withValues(alpha: 0.1))
                                  .withValues(alpha: 0.05),
                            ],
                          ),
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
                                            .withValues(alpha: 0.4),
                                    blurRadius: 20,
                                    spreadRadius: 6,
                                ),
                              ]
                            : [],
                      ),
                      child: Container(
                          width: 40,
                          height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: value.isEqEnabled
                                ? LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
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
                                  ? Colors.white.withValues(alpha: 0.8)
                                : Theme.of(context)
                                    .colorScheme
                                    .onSurface
                                    .withValues(alpha: 0.5),
                              width: 2.5,
                          ),
                            boxShadow: value.isEqEnabled
                                ? [
                                    BoxShadow(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .primary
                                          .withValues(alpha: 0.3),
                                      blurRadius: 8,
                                      spreadRadius: 2,
                                    ),
                                  ]
                                : [],
                        ),
                        child: Center(
                            child: Container(
                              width: 20,
                              height: 3,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(2),
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
                    
                  ),
                    ));
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
                  const SizedBox(height: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Theme.of(context).colorScheme.secondaryContainer,
                          Theme.of(context)
                              .colorScheme
                              .secondaryContainer
                              .withValues(alpha: 0.7),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(context)
                              .colorScheme
                              .secondary
                              .withValues(alpha: 0.15),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      "${(freq / 1000).toStringAsFixed(freq >= 10000 ? 1 : 0)}kHz",
                      style: TextStyle(
                        fontSize: bandTextFontSize != null
                            ? bandTextFontSize! - 2
                            : 11,
                        fontWeight: FontWeight.w600,
                        color:
                            Theme.of(context).colorScheme.onSecondaryContainer,
                        letterSpacing: 0.3,
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
