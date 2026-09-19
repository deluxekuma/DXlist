import 'package:flutter/material.dart';

/// 標題用字體：跟全 app 一致走 Cubic11，只把字級放大一級。
/// 不加粗——這種像素感的字加粗會糊成一團，之前試過很醜。
const TextStyle kTitleStyle = TextStyle(
  fontSize: 21,
  fontWeight: FontWeight.w400,
);

/// 標題底下那行小字。
TextStyle captionStyle(BuildContext context) => TextStyle(
      fontSize: 11.5,
      fontWeight: FontWeight.w400,
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    );
