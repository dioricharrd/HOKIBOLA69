import 'package:bolanet76/app/modules/home/bindings/connection_binding.dart';

class DependencyInjection {
  static void init() {
    ConnectionBinding().dependencies();
  }
}
