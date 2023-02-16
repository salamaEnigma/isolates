import 'dart:isolate';

void main(List<String> arguments) async {
  print("Isolate Test 1");
  getDates().take(10).forEach(print);
}

// Wrap the worker in a function that
// works as an interface
Stream<String> getDates() {
  ReceivePort rp = ReceivePort();
  return Isolate.spawn(_getDates, rp.sendPort)
      .asStream()
      .asyncExpand((_) => rp)
      .takeWhile((element) => element is String)
      .cast();
}

// First define the the worker function
void _getDates(SendPort sp) async {
  await for (final now in Stream<String>.periodic(
    const Duration(seconds: 1),
    (_) {
      return DateTime.now().toIso8601String();
    },
  )) {
    sp.send(now);
  }
}
