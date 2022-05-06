import 'package:logger/logger.dart';

var log = Logger();

bool isNullOrZero(dynamic val) {
  return val == 0.0 || val == null;
}
