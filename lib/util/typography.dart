import 'package:flutter/material.dart';

/// 標題用字體。
///
/// 全域字體是 Cubic11 這種像素感較重的字，小字很可愛，但放到標題上
/// 會被拉得歪歪扭扭，所以標題獨立用系統的無襯線字體，而且不加粗
/// ——像素風格的字體一加粗就會糊成一團。
const TextStyle kTitleStyle = TextStyle(
  fontFamily: 'Roboto',
  fontFamilyFallback: <String>['Noto Sans', 'sans-serif'],
  fontSize: 21,
  fontWeight: FontWeight.w400,
  letterSpacing: 0.2,
);

/// 區塊標題（詳情頁的「譜面一覽」「詳細資訊」等）。
const TextStyle kSectionStyle = TextStyle(
  fontFamily: 'Roboto',
  fontFamilyFallback: <String>['Noto Sans', 'sans-serif'],
  fontSize: 15.5,
  fontWeight: FontWeight.w500,
  letterSpacing: 0.3,
);

/// 標題底下那行小字。
TextStyle captionStyle(BuildContext context) => TextStyle(
      fontSize: 11.5,
      fontWeight: FontWeight.w400,
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    );
