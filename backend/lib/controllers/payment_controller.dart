import 'dart:convert';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import 'package:uuid/uuid.dart';

class PaymentController {
  final _uuid = const Uuid();
  final List<Map<String, dynamic>> _payments = [];

  Router get router {
    final router = Router();
    
    router.post('/init', _initiatePayment);
    router.get('/<id>', _getPayment);
    router.post('/<id>/confirm', _confirmPayment);
    
    return router;
  }

  Future<Response> _initiatePayment(Request request) async {
    try {
      final body = await request.readAsString();
      final data = jsonDecode(body);
      
      final payment = {
        'id': _uuid.v4(),
        'userId': data['userId'],
        'parcelId': data['parcelId'],
        'amount': data['amount'],
        'method': data['method'],
        'phoneNumber': data['phoneNumber'],
        'status': 'pending',
        'createdAt': DateTime.now().toIso8601String(),
      };
      
      _payments.add(payment);
      
      // Simuler une URL de paiement selon la méthode
      String paymentUrl;
      switch (data['method']) {
        case 'wave':
          paymentUrl = 'https://wave.com/pay/${payment['id']}';
          break;
        case 'orangeMoney':
          paymentUrl = 'https://orange.com/pay/${payment['id']}';
          break;
        default:
          paymentUrl = 'https://payment.proscolis.sn/${payment['id']}';
      }
      
      return Response.ok(jsonEncode({
        'success': true,
        'paymentId': payment['id'],
        'paymentUrl': paymentUrl,
        'status': 'pending',
      }));
    } catch (e) {
      return Response.internalServerError(body: jsonEncode({
        'success': false,
        'message': 'Erreur lors de l\'initialisation: $e',
      }));
    }
  }

  Future<Response> _getPayment(Request request, String id) async {
    try {
      final payment = _payments.firstWhere(
        (p) => p['id'] == id,
        orElse: () => {},
      );
      
      if (payment.isEmpty) {
        return Response.notFound(jsonEncode({
          'success': false,
          'message': 'Paiement non trouvé',
        }));
      }
      
      return Response.ok(jsonEncode({
        'success': true,
        'payment': payment,
      }));
    } catch (e) {
      return Response.internalServerError(body: jsonEncode({
        'success': false,
        'message': 'Erreur lors de la récupération: $e',
      }));
    }
  }

  Future<Response> _confirmPayment(Request request, String id) async {
    try {
      final index = _payments.indexWhere((p) => p['id'] == id);
      if (index == -1) {
        return Response.notFound(jsonEncode({
          'success': false,
          'message': 'Paiement non trouvé',
        }));
      }
      
      _payments[index]['status'] = 'completed';
      _payments[index]['completedAt'] = DateTime.now().toIso8601String();
      
      return Response.ok(jsonEncode({
        'success': true,
        'payment': _payments[index],
      }));
    } catch (e) {
      return Response.internalServerError(body: jsonEncode({
        'success': false,
        'message': 'Erreur lors de la confirmation: $e',
      }));
    }
  }
}
