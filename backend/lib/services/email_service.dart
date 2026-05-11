import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server/gmail.dart';
import 'package:logging/logging.dart';

class EmailService {
  final String smtpHost;
  final int smtpPort;
  final bool smtpSecure;
  final String smtpUser;
  final String smtpPass;
  final String smtpFrom;
  final _log = Logger('EmailService');

  EmailService({
    required this.smtpHost,
    required this.smtpPort,
    required this.smtpSecure,
    required this.smtpUser,
    required this.smtpPass,
    required this.smtpFrom,
  });

  /// Envoie un email
  Future<bool> sendEmail({
    required String to,
    required String subject,
    required String htmlBody,
  }) async {
    try {
      // Configuration SMTP pour Gmail
      final smtpServer = gmail(smtpUser, smtpPass);
      
      final message = Message()
        ..from = Address(smtpUser, 'PRO COLIS')
        ..recipients.add(to)
        ..subject = subject
        ..html = htmlBody;

      final sendReport = await send(message, smtpServer);
      _log.info('Email envoyé à $to: ${sendReport.toString()}');
      return true;
    } catch (e) {
      _log.severe('Erreur envoi email: $e');
      return false;
    }
  }

  /// Envoie un code OTP
  Future<bool> sendOtpCode(String to, String code, String type) async {
    final subject = '🔐 PRO COLIS - Code de vérification';
    final htmlBody = _buildOtpEmail(code, type);
    return await sendEmail(to: to, subject: subject, htmlBody: htmlBody);
  }

  /// Envoie une confirmation de colis
  Future<bool> sendParcelConfirmation(String to, String trackingNumber, String receiverName) async {
    final subject = '📦 PRO COLIS - Votre colis a été créé';
    final htmlBody = _buildParcelConfirmationEmail(trackingNumber, receiverName);
    return await sendEmail(to: to, subject: subject, htmlBody: htmlBody);
  }

  /// Envoie une notification de livraison
  Future<bool> sendDeliveryNotification(String to, String trackingNumber, String receiverName) async {
    final subject = '✅ PRO COLIS - Colis livré avec succès';
    final htmlBody = _buildDeliveryNotificationEmail(trackingNumber, receiverName);
    return await sendEmail(to: to, subject: subject, htmlBody: htmlBody);
  }

  String _buildOtpEmail(String code, String type) {
    return '''
    <!DOCTYPE html>
    <html>
    <head>
      <meta charset="UTF-8">
      <style>
        body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
        .container { max-width: 600px; margin: 0 auto; padding: 20px; }
        .header { background: #0B6E3A; padding: 20px; text-align: center; border-radius: 10px 10px 0 0; }
        .header h1 { color: white; margin: 0; }
        .content { background: #f9f9f9; padding: 30px; border-radius: 0 0 10px 10px; }
        .code { font-size: 32px; font-weight: bold; color: #0B6E3A; text-align: center; padding: 20px; letter-spacing: 5px; }
        .footer { text-align: center; padding: 20px; font-size: 12px; color: #888; }
      </style>
    </head>
    <body>
      <div class="container">
        <div class="header">
          <h1>PRO COLIS</h1>
        </div>
        <div class="content">
          <h2>Code de vérification</h2>
          <p>Votre code de vérification est :</p>
          <div class="code">$code</div>
          <p>Ce code est valable pendant 10 minutes.</p>
          <p>Si vous n'êtes pas à l'origine de cette demande, ignorez cet email.</p>
        </div>
        <div class="footer">
          <p>PRO COLIS - Service de transport interurbain</p>
        </div>
      </div>
    </body>
    </html>
    ''';
  }

  String _buildParcelConfirmationEmail(String trackingNumber, String receiverName) {
    return '''
    <!DOCTYPE html>
    <html>
    <head>
      <meta charset="UTF-8">
      <style>
        body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
        .container { max-width: 600px; margin: 0 auto; padding: 20px; }
        .header { background: #0B6E3A; padding: 20px; text-align: center; border-radius: 10px 10px 0 0; }
        .tracking { font-size: 24px; font-weight: bold; color: #0B6E3A; font-family: monospace; }
      </style>
    </head>
    <body>
      <div class="container">
        <div class="header">
          <h1>PRO COLIS</h1>
        </div>
        <div class="content">
          <h2>📦 Colis créé avec succès !</h2>
          <p>Votre colis a été enregistré dans notre système.</p>
          <p><strong>Numéro de suivi :</strong></p>
          <div class="tracking">$trackingNumber</div>
          <p><strong>Destinataire :</strong> $receiverName</p>
          <p>🔗 Suivez votre colis : <a href="https://proscolis.sn/track/$trackingNumber">https://proscolis.sn/track/$trackingNumber</a></p>
        </div>
        <div class="footer">
          <p>PRO COLIS - Service client disponible 24/7</p>
        </div>
      </div>
    </body>
    </html>
    ''';
  }

  String _buildDeliveryNotificationEmail(String trackingNumber, String receiverName) {
    return '''
    <!DOCTYPE html>
    <html>
    <head>
      <meta charset="UTF-8">
      <style>
        body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
        .container { max-width: 600px; margin: 0 auto; padding: 20px; }
        .header { background: #0B6E3A; padding: 20px; text-align: center; border-radius: 10px 10px 0 0; }
      </style>
    </head>
    <body>
      <div class="container">
        <div class="header">
          <h1>PRO COLIS</h1>
        </div>
        <div class="content">
          <h2>✅ Colis livré avec succès !</h2>
          <p>Bonjour,</p>
          <p>Nous avons le plaisir de vous informer que votre colis a été livré.</p>
          <p><strong>Numéro de suivi :</strong> $trackingNumber</p>
          <p><strong>Destinataire :</strong> $receiverName</p>
          <p>Merci d'avoir utilisé PRO COLIS !</p>
        </div>
        <div class="footer">
          <p>PRO COLIS - Service de transport interurbain</p>
        </div>
      </div>
    </body>
    </html>
    ''';
  }
}
