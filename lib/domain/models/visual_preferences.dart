class VisualPreferences {
  final String topBarStyle;
  final String bottomBarStyle;
  final String bubbleStyle;
  final String appIconStyle;
  final String notificationIconStyle;
  final String typographyStyle;
  final String entryAnimation;
  final String exitAnimation;

  const VisualPreferences({
    this.topBarStyle = 'Classic',
    this.bottomBarStyle = 'Floating Pill',
    this.bubbleStyle = 'Soft Rounded',
    this.appIconStyle = 'Chaty Original',
    this.notificationIconStyle = 'Rounded Bell',
    this.typographyStyle = 'System',
    this.entryAnimation = 'Fade Through',
    this.exitAnimation = 'Fade Through',
  });

  static const List<String> topBarStyles = <String>[
    'Classic',
    'Minimal',
    'Compact',
    'Centered',
    'Floating',
    'Outlined',
    'Soft',
    'Dense',
    'Pill Actions',
    'Large Title',
    'Two Row',
    'Underline',
    'Elevated',
    'Edge To Edge',
    'Rounded Dock',
    'Segmented',
    'Translucent',
    'Utility',
    'Focus',
    'Workspace',
  ];

  static const List<String> bottomBarStyles = <String>[
    'Floating Pill',
    'Classic',
    'Minimal',
    'Compact',
    'Icons Only',
    'Outlined',
    'Soft Dock',
    'Elevated',
    'Segmented',
    'Bubble Select',
    'Underline',
    'Top Indicator',
    'Label Always',
    'Label Selected',
    'Wide Dock',
    'Inset Dock',
    'Edge To Edge',
    'Dense Dock',
    'Workspace',
    'Adaptive',
  ];

  static const List<String> bubbleStyles = <String>[
    'Soft Rounded',
    'Classic Tail',
    'Compact',
    'Pill',
    'Squircle',
    'Minimal',
    'Outlined',
    'Elevated',
    'Flat',
    'Sharp Tail',
    'Soft Square',
    'Dense',
    'Wide',
    'Airy',
    'Card',
    'Underline',
    'Border Accent',
    'Monochrome',
    'Workspace',
    'Focus',
  ];

  static const List<String> appIconStyles = <String>[
    'Chaty Original',
    'Outline',
    'Soft',
    'Rounded',
    'Minimal',
    'Mono',
    'Material',
    'Classic',
    'Compact',
    'Bold',
    'Thin',
    'Duotone',
    'Square',
    'Squircle',
    'Circle',
    'Badge',
    'Workspace',
    'Focus',
    'High Contrast',
    'Adaptive',
  ];

  static const List<String> notificationIconStyles = <String>[
    'Rounded Bell',
    'Outline Bell',
    'Filled Bell',
    'Message Dot',
    'Chat Bubble',
    'Minimal Dot',
    'Badge',
    'Ring',
    'Pulse',
    'Priority',
    'Silent',
    'Compact',
    'Classic',
    'Material',
    'Thin',
    'Bold',
    'Workspace',
    'Focus',
    'High Contrast',
    'Adaptive',
  ];

  static const List<String> typographyStyles = <String>[
    'System',
    'Modern',
    'Compact',
    'Comfortable',
    'Editorial',
    'Technical',
    'Monospace',
    'Humanist',
    'Geometric',
    'Rounded',
    'Dense',
    'Large',
    'Accessible',
    'Minimal',
    'Classic',
    'Workspace',
    'Focus',
    'Headline',
    'Soft',
    'High Contrast',
  ];

  static const List<String> animationStyles = <String>[
    'Fade Through',
    'Fade',
    'Slide Left',
    'Slide Right',
    'Slide Up',
    'Slide Down',
    'Scale',
    'Zoom',
    'Shared Axis X',
    'Shared Axis Y',
    'Shared Axis Z',
    'Flip X',
    'Flip Y',
    'Rotate Soft',
    'Rise Fade',
    'Drop Fade',
    'Elastic Scale',
    'Cupertino',
    'Material',
    'None',
  ];

  VisualPreferences copyWith({
    String? topBarStyle,
    String? bottomBarStyle,
    String? bubbleStyle,
    String? appIconStyle,
    String? notificationIconStyle,
    String? typographyStyle,
    String? entryAnimation,
    String? exitAnimation,
  }) {
    return VisualPreferences(
      topBarStyle: topBarStyle ?? this.topBarStyle,
      bottomBarStyle: bottomBarStyle ?? this.bottomBarStyle,
      bubbleStyle: bubbleStyle ?? this.bubbleStyle,
      appIconStyle: appIconStyle ?? this.appIconStyle,
      notificationIconStyle:
          notificationIconStyle ?? this.notificationIconStyle,
      typographyStyle: typographyStyle ?? this.typographyStyle,
      entryAnimation: entryAnimation ?? this.entryAnimation,
      exitAnimation: exitAnimation ?? this.exitAnimation,
    );
  }

  Map<String, dynamic> toMap() => <String, dynamic>{
        'topBarStyle': topBarStyle,
        'bottomBarStyle': bottomBarStyle,
        'bubbleStyle': bubbleStyle,
        'appIconStyle': appIconStyle,
        'notificationIconStyle': notificationIconStyle,
        'typographyStyle': typographyStyle,
        'entryAnimation': entryAnimation,
        'exitAnimation': exitAnimation,
      };

  factory VisualPreferences.fromMap(Map<String, dynamic> map) {
    String valid(String key, List<String> values, String fallback) {
      final value = map[key]?.toString();
      return value != null && values.contains(value) ? value : fallback;
    }

    return VisualPreferences(
      topBarStyle: valid('topBarStyle', topBarStyles, 'Classic'),
      bottomBarStyle:
          valid('bottomBarStyle', bottomBarStyles, 'Floating Pill'),
      bubbleStyle: valid('bubbleStyle', bubbleStyles, 'Soft Rounded'),
      appIconStyle:
          valid('appIconStyle', appIconStyles, 'Chaty Original'),
      notificationIconStyle: valid(
        'notificationIconStyle',
        notificationIconStyles,
        'Rounded Bell',
      ),
      typographyStyle:
          valid('typographyStyle', typographyStyles, 'System'),
      entryAnimation:
          valid('entryAnimation', animationStyles, 'Fade Through'),
      exitAnimation:
          valid('exitAnimation', animationStyles, 'Fade Through'),
    );
  }
}
