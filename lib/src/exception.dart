part of fixnum;

class OverflowException implements Exception {
  String? message;
  final Type type;
  final String min;
  final String max;

  @pragma("vm:entry-point")
  OverflowException(
      {required this.type, required this.min, required this.max, this.message});

  @override
  String toString() {
    String str = "OverflowException: ";

    if (message != null) {
      str += "${message!}, ";
    }

    return "$str The range of $type is [$min, $max].";
  }
}
