import 'package:equalizer_flutter/equalizer_flutter.dart';
import 'package:equalizer_flutter_custom/src/CustomSlider.dart';
import 'package:equalizer_flutter_custom/src/EqalizerProvider/EqualizerProvider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

Widget Customeq(
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
    double? sliderBoxPadding) {
  return FutureBuilder<List<int>>(
    future: EqualizerFlutter.getCenterBandFreqs(),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.done) {
        if (snapshot.hasData && snapshot.data!.isNotEmpty) {
          final freqs = snapshot.data!;

          // Use Consumer to rebuild when provider changes
          return Consumer<EqualizerProvider>(
            builder: (context, provider, child) {
              // Ensure bands array is populated with the correct length
              if (provider.bands.length < freqs.length) {
                // Initialize bands synchronously to avoid loading state
                provider.bands = List<int>.filled(freqs.length, 0);
                // Fetch actual band levels in the background
                Future.microtask(() => provider.fetchBandLevels());
              }

              return Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: List.generate(
                        freqs.length,
                        (index) => CustomSlider(
                              context,
                              index,
                              freqs[index],
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
                            )),
                  )
                ],
              );
            },
          );
        } else {
          return const Text("Audio SessionId empty");
        }
      } else {
        return const CircularProgressIndicator();
      }
    },
  );
}
