// lib/services/email_service.dart
import 'package:logging/logging.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';

class EmailService {
  final String smtpHost;
  final int smtpPort;
  final bool smtpSecure;
  final String smtpUser;
  final String smtpPass;
  final String smtpFrom;
  final String fromName;
  final _log = Logger('EmailService');

  EmailService({
    required this.smtpHost,
    required this.smtpPort,
    required this.smtpSecure,
    required this.smtpUser,
    required this.smtpPass,
    required this.smtpFrom,
    this.fromName = 'PRO COLIS',
  });

  /// Crée le serveur SMTP configuré
  SmtpServer _createSmtpServer() {
    return SmtpServer(
      smtpHost,
      port: smtpPort,
      ssl: smtpSecure,
      username: smtpUser,
      password: smtpPass,
    );
  }

  /// Extrait l'email du format "Nom <email>" ou retourne tel quel
  String _extractEmail(String emailString) {
    final match = RegExp(r'<(.+?)>').firstMatch(emailString);
    if (match != null) {
      return match.group(1)!;
    }
    return emailString;
  }

  /// Envoie un email générique
  Future<bool> sendEmail({
    required String to,
    required String subject,
    required String htmlBody,
    String? textBody,
  }) async {
    try {
      final smtpServer = _createSmtpServer();
      final fromEmail = _extractEmail(smtpFrom);
      
      final message = Message()
        ..from = Address(fromEmail, fromName)
        ..recipients.add(to)
        ..subject = subject
        ..html = htmlBody;
      
      if (textBody != null) {
        message.text = textBody;
      }

      final sendReport = await send(message, smtpServer);
      _log.info('Email envoyé à $to: ${sendReport.toString()}');
      return true;
    } catch (e) {
      _log.severe('Erreur envoi email à $to: $e');
      return false;
    }
  }

  /// Envoie un code OTP
  Future<bool> sendOtpCode(String to, String code, {String type = 'connexion'}) async {
    final subject = '🔐 PRO COLIS - Code de vérification';
    final htmlBody = _buildOtpEmail(code, type);
    final textBody = '''
PRO COLIS - Code de vérification

Votre code de vérification est : $code

Ce code est valable pendant 10 minutes.
Si vous n'êtes pas à l'origine de cette demande, ignorez cet email.

---
PRO COLIS - Service de transport interurbain
''';
    return await sendEmail(
      to: to, 
      subject: subject, 
      htmlBody: htmlBody,
      textBody: textBody,
    );
  }

  /// Envoie une confirmation de création de colis
  Future<bool> sendParcelConfirmation(String to, String trackingNumber, String receiverName) async {
    final subject = '📦 PRO COLIS - Votre colis a été créé';
    final htmlBody = _buildParcelConfirmationEmail(trackingNumber, receiverName);
    final textBody = '''
PRO COLIS - Confirmation de création de colis

Bonjour,

Votre colis a été créé avec succès !

Numéro de suivi : $trackingNumber
Destinataire : $receiverName

Suivez votre colis : https://proscolis.sn/track/$trackingNumber

---
PRO COLIS - Service client disponible 24/7
''';
    return await sendEmail(
      to: to, 
      subject: subject, 
      htmlBody: htmlBody,
      textBody: textBody,
    );
  }

  /// Envoie une notification de livraison
  Future<bool> sendDeliveryNotification(String to, String trackingNumber, String receiverName) async {
    final subject = '✅ PRO COLIS - Colis livré avec succès';
    final htmlBody = _buildDeliveryNotificationEmail(trackingNumber, receiverName);
    final textBody = '''
PRO COLIS - Colis livré avec succès

Bonjour,

Nous avons le plaisir de vous informer que votre colis a été livré.

Numéro de suivi : $trackingNumber
Destinataire : $receiverName

Merci d'avoir utilisé PRO COLIS !

---
PRO COLIS - Service de transport interurbain
''';
    return await sendEmail(
      to: to, 
      subject: subject, 
      htmlBody: htmlBody,
      textBody: textBody,
    );
  }

  /// Envoie une notification de mise à jour de statut
  Future<bool> sendStatusUpdateEmail(
    String to, 
    String trackingNumber, 
    String status, 
    String statusLabel
  ) async {
    final subject = '📬 PRO COLIS - Mise à jour de votre colis';
    final htmlBody = _buildStatusUpdateEmail(trackingNumber, status, statusLabel);
    final textBody = '''
PRO COLIS - Mise à jour du statut

Bonjour,

Le statut de votre colis a été mis à jour.

Numéro de suivi : $trackingNumber
Nouveau statut : $statusLabel

Suivez votre colis : https://proscolis.sn/track/$trackingNumber

---
PRO COLIS - Service de transport interurbain
''';
    return await sendEmail(
      to: to, 
      subject: subject, 
      htmlBody: htmlBody,
      textBody: textBody,
    );
  }

  // ==================== TEMPLATES HTML ====================

  String _buildOtpEmail(String code, String type) {
    return '''
    <!DOCTYPE html>
    <html>
    <head>
      <meta charset="UTF-8">
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
      <title>Code de vérification PRO COLIS</title>
      <style>
        body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Arial, sans-serif; line-height: 1.6; color: #333; margin: 0; padding: 0; background-color: #f4f4f4; }
        .container { max-width: 600px; margin: 20px auto; padding: 0; background-color: #ffffff; border-radius: 12px; overflow: hidden; box-shadow: 0 2px 8px rgba(0,0,0,0.1); }
        .header { background: linear-gradient(135deg, #0B6E3A 0%, #0a5a2f 100%); padding: 30px 20px; text-align: center; }
        .header h1 { color: white; margin: 0; font-size: 28px; letter-spacing: 1px; }
        .content { padding: 40px 30px; background: #ffffff; }
        .code { font-size: 36px; font-weight: bold; color: #0B6E3A; text-align: center; padding: 20px; letter-spacing: 8px; background: #f0f9f0; border-radius: 8px; font-family: monospace; margin: 20px 0; }
        .footer { text-align: center; padding: 20px; font-size: 12px; color: #888; background: #f9f9f9; border-top: 1px solid #eee; }
        .warning { font-size: 12px; color: #666; margin-top: 20px; padding-top: 20px; border-top: 1px solid #eee; }
      </style>
    </head>
    <body>
      <div class="container">
        <div class="header">
          <h1>PRO COLIS</h1>
        </div>
        <div class="content">
          <h2 style="color: #0B6E3A; margin-top: 0;">Code de vérification</h2>
          <p>Bonjour,</p>
          <p>Vous avez demandé un code de vérification pour ${type == 'connexion' ? 'vous connecter' : 'valider votre action'} sur votre compte PRO COLIS.</p>
          <div class="code">$code</div>
          <p>Ce code est valable pendant <strong>10 minutes</strong>.</p>
          <div class="warning">
            <p>⚠️ Si vous n'êtes pas à l'origine de cette demande, ignorez cet email.<br>
            Ne communiquez jamais ce code à qui que ce soit.</p>
          </div>
        </div>
        <div class="footer">
          <p>PRO COLIS - Service de transport interurbain</p>
          <p>&copy; 2024 PRO COLIS - Tous droits réservés</p>
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
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
      <title>Confirmation de colis - PRO COLIS</title>
      <style>
        body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Arial, sans-serif; line-height: 1.6; color: #333; margin: 0; padding: 0; background-color: #f4f4f4; }
        .container { max-width: 600px; margin: 20px auto; padding: 0; background-color: #ffffff; border-radius: 12px; overflow: hidden; box-shadow: 0 2px 8px rgba(0,0,0,0.1); }
        .header { background: linear-gradient(135deg, #0B6E3A 0%, #0a5a2f 100%); padding: 30px 20px; text-align: center; }
        .header h1 { color: white; margin: 0; font-size: 28px; letter-spacing: 1px; }
        .content { padding: 40px 30px; background: #ffffff; }
        .tracking-box { background: #f0f9f0; padding: 20px; border-radius: 8px; text-align: center; margin: 20px 0; }
        .tracking-number { font-size: 24px; font-weight: bold; color: #0B6E3A; font-family: monospace; letter-spacing: 2px; }
        .button { display: inline-block; background: #0B6E3A; color: white; padding: 12px 30px; text-decoration: none; border-radius: 6px; margin-top: 20px; font-weight: bold; }
        .footer { text-align: center; padding: 20px; font-size: 12px; color: #888; background: #f9f9f9; border-top: 1px solid #eee; }
      </style>
    </head>
    <body>
      <div class="container">
        <div class="header">
          <h1>PRO COLIS</h1>
        </div>
        <div class="content">
          <h2 style="color: #0B6E3A; margin-top: 0;">📦 Colis créé avec succès !</h2>
          <p>Bonjour,</p>
          <p>Votre colis a été enregistré dans notre système.</p>
          <div class="tracking-box">
            <strong>Numéro de suivi :</strong>
            <div class="tracking-number">$trackingNumber</div>
          </div>
          <p><strong>Destinataire :</strong> $receiverName</p>
          <p style="text-align: center;">
            <a href="https://proscolis.sn/track/$trackingNumber" class="button">🔍 Suivre mon colis</a>
          </p>
          <p>Vous pouvez suivre l'évolution de votre colis à tout moment.</p>
        </div>
        <div class="footer">
          <p>PRO COLIS - Service client disponible 24/7</p>
          <p>📞 Contactez-nous au +221 33 123 45 67</p>
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
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
      <title>Colis livré - PRO COLIS</title>
      <style>
        body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Arial, sans-serif; line-height: 1.6; color: #333; margin: 0; padding: 0; background-color: #f4f4f4; }
        .container { max-width: 600px; margin: 20px auto; padding: 0; background-color: #ffffff; border-radius: 12px; overflow: hidden; box-shadow: 0 2px 8px rgba(0,0,0,0.1); }
        .header { background: linear-gradient(135deg, #0B6E3A 0%, #0a5a2f 100%); padding: 30px 20px; text-align: center; }
        .header h1 { color: white; margin: 0; font-size: 28px; letter-spacing: 1px; }
        .content { padding: 40px 30px; background: #ffffff; text-align: center; }
        .checkmark { font-size: 64px; margin: 20px 0; }
        .info-box { background: #f0f9f0; padding: 20px; border-radius: 8px; margin: 20px 0; text-align: left; }
        .footer { text-align: center; padding: 20px; font-size: 12px; color: #888; background: #f9f9f9; border-top: 1px solid #eee; }
      </style>
    </head>
    <body>
      <div class="container">
        <div class="header">
          <h1>PRO COLIS</h1>
        </div>
        <div class="content">
          <div class="checkmark">✅</div>
          <h2 style="color: #0B6E3A; margin-top: 0;">Colis livré avec succès !</h2>
          <p>Bonjour,</p>
          <p>Nous avons le plaisir de vous informer que votre colis a été livré.</p>
          <div class="info-box">
            <p><strong>📦 Numéro de suivi :</strong><br>$trackingNumber</p>
            <p><strong>👤 Destinataire :</strong><br>$receiverName</p>
          </div>
          <p>Merci d'avoir utilisé PRO COLIS !<br>N'hésitez pas à nous laisser un avis sur notre service.</p>
        </div>
        <div class="footer">
          <p>PRO COLIS - Service de transport interurbain</p>
          <p>⭐ Notez votre expérience sur notre application</p>
        </div>
      </div>
    </body>
    </html>
    ''';
  }

  String _buildStatusUpdateEmail(String trackingNumber, String status, String statusLabel) {
    // Couleur du statut
    String statusColor = '#0B6E3A';
    if (status == 'pending') statusColor = '#f39c12';
    if (status == 'shipped') statusColor = '#3498db';
    if (status == 'delivered') statusColor = '#27ae60';
    if (status == 'cancelled') statusColor = '#e74c3c';
    
    return '''
    <!DOCTYPE html>
    <html>
    <head>
      <meta charset="UTF-8">
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
      <title>Mise à jour colis - PRO COLIS</title>
      <style>
        body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Arial, sans-serif; line-height: 1.6; color: #333; margin: 0; padding: 0; background-color: #f4f4f4; }
        .container { max-width: 600px; margin: 20px auto; padding: 0; background-color: #ffffff; border-radius: 12px; overflow: hidden; box-shadow: 0 2px 8px rgba(0,0,0,0.1); }
        .header { background: linear-gradient(135deg, #0B6E3A 0%, #0a5a2f 100%); padding: 30px 20px; text-align: center; }
        .header h1 { color: white; margin: 0; font-size: 28px; letter-spacing: 1px; }
        .content { padding: 40px 30px; background: #ffffff; }
        .status-badge { display: inline-block; background: $statusColor; color: white; padding: 8px 20px; border-radius: 20px; font-weight: bold; margin: 10px 0; }
        .button { display: inline-block; background: #0B6E3A; color: white; padding: 12px 30px; text-decoration: none; border-radius: 6px; margin-top: 20px; font-weight: bold; }
        .footer { text-align: center; padding: 20px; font-size: 12px; color: #888; background: #f9f9f9; border-top: 1px solid #eee; }
      </style>
    </head>
    <body>
      <div class="container">
        <div class="header">
          <h1>PRO COLIS</h1>
        </div>
        <div class="content">
          <h2 style="color: #0B6E3A; margin-top: 0;">📬 Mise à jour de votre colis</h2>
          <p>Bonjour,</p>
          <p>Le statut de votre colis a été mis à jour.</p>
          <p><strong>Numéro de suivi :</strong> $trackingNumber</p>
          <p style="text-align: center;">
            <span class="status-badge">$statusLabel</span>
          </p>
          <p style="text-align: center;">
            <a href="https://proscolis.sn/track/$trackingNumber" class="button">🔍 Suivre mon colis</a>
          </p>
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