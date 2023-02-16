import 'dart:convert';
import 'dart:isolate';
import 'dart:io';

void main(List<String> args) async {
  do {
    print("Ask me a question");
    final input = stdin.readLineSync(encoding: utf8);

    switch (input) {
      case null:
        continue;
      case 'exit':
        exit(0);
      default:
        final response = await getAIAnswer(input!);
        print(response);
    }
  } while (true);
}

final Map<String, String> conversationalPrompts = {
  'hello': 'Hello there!',
  'how are you?':
      'As a computer, I don\'t have emotions, but I am functioning correctly.',
  'what do you do?': 'I am a computer program designed to assist you.',
  'where are you located?':
      'I am a computer program, so I do not have a physical location.',
  'what can you do?':
      'I can perform a variety of tasks, such as answering your questions, providing information, and helping you complete tasks.',
  'what time is it?': 'I can tell you the current time, which is ',
};

Future<String> getAIAnswer(String prompt) async {
  ReceivePort rp = ReceivePort();
  await Isolate.spawn(_communicator, rp.sendPort);
  final broadCast = rp.asBroadcastStream();
  final SendPort communicatorSendPort =
      await broadCast.firstWhere((element) => element is SendPort);

  // Send the prompt
  communicatorSendPort.send(prompt);
  return broadCast
      .takeWhile((element) => element is String)
      .cast<String>()
      .take(1)
      .first;
}

void _communicator(SendPort sp) async {
  ReceivePort receivePort = ReceivePort();
  // Pass the sendport of this isolate to the main isolate to receieve prompts
  sp.send(receivePort.sendPort);

  // Listen to receiver port of this isolate
  await for (final prompt
      in receivePort.takeWhile((element) => element is String).cast<String>()) {
    print("User: $prompt");
    sp.send(conversationalPrompts[prompt.toLowerCase().trim()] ??
        "Can't answer your question!");
  }
}
