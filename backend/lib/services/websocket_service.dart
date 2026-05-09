// backend/lib/services/websocket_service.dart
import 'dart:convert';

import 'package:logging/logging.dart';
// ignore: unused_import
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class WebSocketService {
  final _log = Logger('WebSocketService');
  final Map<String, List<WebSocketChannel>> _subscriptions = {};
  
  void handleConnection(WebSocketChannel channel, String userId) {
    _log.info('Client $userId connected');
    
    // Écouter les messages du client
    channel.stream.listen(
      (message) {
        final data = jsonDecode(message);
        _handleMessage(channel, userId, data);
      },
      onDone: () {
        _removeChannel(userId);
        _log.info('Client $userId disconnected');
      },
    );
  }
  
  void _handleMessage(WebSocketChannel channel, String userId, Map<String, dynamic> data) {
    final type = data['type'];
    
    switch (type) {
      case 'subscribe':
        final topic = data['topic'];
        _subscribe(channel, userId, topic);
        break;
        
      case 'unsubscribe':
        final topic = data['topic'];
        _unsubscribe(channel, userId, topic);
        break;
        
      case 'location_update':
        final parcelId = data['parcelId'];
        final latitude = data['latitude'];
        final longitude = data['longitude'];
        _broadcastLocation(parcelId, latitude, longitude);
        break;
    }
  }
  
  void _subscribe(WebSocketChannel channel, String userId, String topic) {
    _subscriptions.putIfAbsent(topic, () => []).add(channel);
    _log.info('User $userId subscribed to $topic');
  }
  
  void _unsubscribe(WebSocketChannel channel, String userId, String topic) {
    _subscriptions[topic]?.remove(channel);
    if (_subscriptions[topic]?.isEmpty ?? false) {
      _subscriptions.remove(topic);
    }
  }
  
  void _removeChannel(String userId) {
    _subscriptions.forEach((topic, channels) {
      // ignore: unnecessary_null_comparison
      channels.removeWhere((c) => c == null);
    });
    _subscriptions.removeWhere((_, channels) => channels.isEmpty);
  }
  
  void _broadcastLocation(String parcelId, double latitude, double longitude) {
    final topic = 'parcel.$parcelId';
    final message = jsonEncode({
      'type': 'location_update',
      'parcelId': parcelId,
      'latitude': latitude,
      'longitude': longitude,
      'timestamp': DateTime.now().toIso8601String(),
    });
    
    _subscriptions[topic]?.forEach((channel) {
      channel.sink.add(message);
    });
  }
  
  void broadcastStatusUpdate(String parcelId, String status, String location) {
    final topic = 'parcel.$parcelId';
    final message = jsonEncode({
      'type': 'status_update',
      'parcelId': parcelId,
      'status': status,
      'location': location,
      'timestamp': DateTime.now().toIso8601String(),
    });
    
    _subscriptions[topic]?.forEach((channel) {
      channel.sink.add(message);
    });
  }
}