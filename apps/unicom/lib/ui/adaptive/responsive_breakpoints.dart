import 'package:flutter/widgets.dart';

enum DeviceType { phone, tablet, desktop }

class ResponsiveLayout {
  static const double phoneMax = 600;
  static const double tabletMax = 1100;

  static DeviceType getDeviceType(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width < phoneMax) return DeviceType.phone;
    if (width < tabletMax) return DeviceType.tablet;
    return DeviceType.desktop;
  }

  static bool isPhone(BuildContext context) => getDeviceType(context) == DeviceType.phone;
  static bool isTablet(BuildContext context) => getDeviceType(context) == DeviceType.tablet;
  static bool isDesktop(BuildContext context) => getDeviceType(context) == DeviceType.desktop;

  static double contentPadding(BuildContext context) {
    final type = getDeviceType(context);
    switch (type) {
      case DeviceType.phone:
        return 12.0;
      case DeviceType.tablet:
        return 20.0;
      case DeviceType.desktop:
        return 32.0;
    }
  }
}
