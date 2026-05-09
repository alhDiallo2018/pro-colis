// backend/lib/services/sms_service.dart
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';

class SmsService {
  final _log = Logger('SmsService');
  final String? apiKey;
  final String? apiSecret;
  final String? senderId;

  SmsService({
    this.apiKey,
    this.apiSecret,
    this.senderId = 'PROCOLIS',
  });

  /// Envoie un SMS avec code OTP
  Future<bool> sendOtp(String phoneNumber, String code) async {
    // Nettoyer le numéro de téléphone
    final cleanedPhone = _cleanPhoneNumber(phoneNumber);
    
    final message = '''
🔐 PRO COLIS - Votre code de vérification

Code OTP: $code

Ce code est valable 10 minutes.
Ne le partagez jamais avec personne.

PRO COLIS - Service colis sécurisé
''';

    return await sendSms(cleanedPhone, message);
  }

  /// Envoie une notification de statut de colis
  Future<bool> sendParcelStatusUpdate(
    String phoneNumber,
    String trackingNumber,
    String status,
    String location,
  ) async {
    final cleanedPhone = _cleanPhoneNumber(phoneNumber);
    
    final message = '''
📦 PRO COLIS - Mise à jour colis

N° suivi: $trackingNumber
Statut: $status
Lieu: $location

Suivez votre colis: https://procolis.com/track/$trackingNumber
''';

    return await sendSms(cleanedPhone, message);
  }

  /// Envoie une confirmation de livraison
  Future<bool> sendDeliveryConfirmation(
    String phoneNumber,
    String trackingNumber,
    String receiverName,
  ) async {
    final cleanedPhone = _cleanPhoneNumber(phoneNumber);
    
    final message = '''
✅ PRO COLIS - Colis livré !

N° suivi: $trackingNumber
Destinataire: $receiverName

Merci d'avoir utilisé PRO COLIS !
Notez votre expérience: https://procolis.com/rate/$trackingNumber
''';

    return await sendSms(cleanedPhone, message);
  }

  /// Envoi de SMS via API (Orange SMS / Twilio / Africa's Talking)
  Future<bool> sendSms(String phoneNumber, String message) async {
    try {
      // Utiliser Orange SMS API pour le Sénégal
      final response = await _sendViaOrangeSms(phoneNumber, message);
      
      if (response) {
        _log.info('SMS sent to $phoneNumber');
      } else {
        _log.warning('Failed to send SMS to $phoneNumber');
        // Fallback vers autre provider
        return await _sendViaAfricaTalking(phoneNumber, message);
      }
      
      return response;
    } catch (e) {
      _log.severe('SMS sending error: $e');
      return false;
    }
  }

  /// Envoi via Orange SMS API
  Future<bool> _sendViaOrangeSms(String phoneNumber, String message) async {
    // Implémentation Orange SMS API
    // Nécessite un compte Orange Developer
    try {
      final url = Uri.parse('https://api.orange.com/sms/v3/orders');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          'outboundSMSMessageRequest': {
            'address': 'tel:$phoneNumber',
            'senderAddress': 'tel:+221$senderId',
            'outboundSMSTextMessage': {'message': message},
          },
        }),
      );
      
      return response.statusCode == 201;
    } catch (e) {
      _log.severe('Orange SMS error: $e');
      return false;
    }
  }

  /// Envoi via Africa's Talking API
  Future<bool> _sendViaAfricaTalking(String phoneNumber, String message) async {
    try {
      final url = Uri.parse('https://api.africastalking.com/version1/messaging');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'apiKey': apiSecret ?? '',
        },
        body: {
          'username': 'procolis',
          'to': phoneNumber,
          'message': message,
          'from': senderId,
        },
      );
      
      final data = jsonDecode(response.body);
      return response.statusCode == 201 && data['SMSMessageData']['Recipients'][0]['status'] == 'Success';
    } catch (e) {
      _log.severe('Africa\'s Talking error: $e');
      return false;
    }
  }

  /// Nettoie le numéro de téléphone au format international
  String _cleanPhoneNumber(String phoneNumber) {
    // Enlever tous les caractères non numériques
    String cleaned = phoneNumber.replaceAll(RegExp(r'[^0-9+]'), '');
    
    // Format Sénégalais: +221XXXXXXXXX
    if (cleaned.startsWith('77') || cleaned.startsWith('78') || 
        cleaned.startsWith('76') || cleaned.startsWith('70')) {
      cleaned = '+221$cleaned';
    } else if (cleaned.startsWith('0')) {
      cleaned = '+221${cleaned.substring(1)}';
    } else if (!cleaned.startsWith('+')) {
      cleaned = '+221$cleaned';
    }
    
    return cleaned;
  }
}