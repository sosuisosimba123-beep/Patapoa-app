import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';
import '../utils/api_error_handler.dart';

class QueuedRequest {
  final String id;
  final String method;
  final String endpoint;
  final Map<String, dynamic> body;
  final int timestamp;

  QueuedRequest({
    required this.id,
    required this.method,
    required this.endpoint,
    required this.body,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'method': method,
    'endpoint': endpoint,
    'body': body,
    'timestamp': timestamp,
  };

  factory QueuedRequest.fromJson(Map<String, dynamic> json) => QueuedRequest(
    id: json['id'],
    method: json['method'],
    endpoint: json['endpoint'],
    body: json['body'],
    timestamp: json['timestamp'],
  );
}

class RequestQueueService {
  static final RequestQueueService _instance = RequestQueueService._internal();
  factory RequestQueueService() => _instance;
  RequestQueueService._internal();

  final ApiService _apiService = ApiService();
  bool _isProcessing = false;

  /// Adds a request to the queue to be sent later
  Future<void> enqueue(String method, String endpoint, Map<String, dynamic> body) async {
    final queue = await _getQueue();

    final request = QueuedRequest(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      method: method,
      endpoint: endpoint,
      body: body,
      timestamp: DateTime.now().millisecondsSinceEpoch,
    );

    queue.add(request);
    await _saveQueue(queue);

    // Try to process immediately in the background
    processQueue();
  }

  /// Attempts to send all pending requests in the queue
  Future<void> processQueue() async {
    if (_isProcessing) return;
    _isProcessing = true;

    try {
      final queue = await _getQueue();
      if (queue.isEmpty) return;

      final remainingQueue = <QueuedRequest>[];

      for (var request in queue) {
        try {
          if (request.method == 'POST') {
            await _apiService.post(request.endpoint, request.body);
          } else if (request.method == 'PUT') {
            await _apiService.put(request.endpoint, request.body);
          }
          // Success: don't add to remaining
        } catch (e) {
          // If it's a network error, keep it in queue and stop processing for now
          if (e is NetworkException || e is RequestTimeoutException) {
            remainingQueue.add(request);
            // Wait for next trigger (timer or new request)
            break;
          }
          // For other errors (4xx), we might want to discard or log it
        }
      }

      await _saveQueue(remainingQueue);
    } finally {
      _isProcessing = false;
    }
  }

  Future<List<QueuedRequest>> _getQueue() async {
    final prefs = await SharedPreferences.getInstance();
    final String? data = prefs.getString('request_queue');
    if (data == null) return [];

    final List<dynamic> jsonList = jsonDecode(data);
    return jsonList.map((j) => QueuedRequest.fromJson(j)).toList();
  }

  Future<void> _saveQueue(List<QueuedRequest> queue) async {
    final prefs = await SharedPreferences.getInstance();
    final String data = jsonEncode(queue.map((r) => r.toJson()).toList());
    await prefs.setString('request_queue', data);
  }
}
