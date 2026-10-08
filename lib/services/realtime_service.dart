import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';

class RealtimeService {
  WebSocketChannel? _channel;

  Stream<Map<String, dynamic>> connect({
    required String websocketUrl,
    required String token,
    required String channelName,
  }) {
    _channel = WebSocketChannel.connect(Uri.parse(websocketUrl));

    _channel!.sink.add(jsonEncode({
      'event': 'subscribe',
      'data': {
        'channel': channelName,
        'token': token,
      },
    }));

    return _channel!.stream.map((event) {
      if (event is String) {
        final data = jsonDecode(event);
        return Map<String, dynamic>.from(data);
      }
      return <String, dynamic>{};
    });
  }

  Future<void> dispose() async {
    await _channel?.sink.close();
  }
}
