// backend/lib/services/email_service.dart
import 'package:logging/logging.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server/gmail.dart';

import '../models/otp.dart';

class EmailService {
  final _log = Logger('EmailService');
  final String? smtpUsername;
  final String? smtpPassword;

  EmailService({this.smtpUsername, this.smtpPassword});

  /// Envoie un email avec code OTP
  Future<bool> sendOtp(String email, String code, OtpType type) async {
    String subject;
    String htmlBody;

    switch (type) {
      case OtpType.login:
        subject = '🔐 PRO COLIS - Code de connexion';
        htmlBody = _buildLoginOtpEmail(code);
        break;
      case OtpType.verification:
        subject = '✅ PRO COLIS - Vérification de votre compte';
        htmlBody = _buildVerificationOtpEmail(code);
        break;
      case OtpType.passwordReset:
        subject = '🔑 PRO COLIS - Réinitialisation du mot de passe';
        htmlBody = _buildPasswordResetOtpEmail(code);
        break;
    }

    return await sendEmail(email, subject, htmlBody);
  }

  /// Envoie une notification de colis créé
  Future<bool> sendParcelCreatedEmail(
    String email,
    String trackingNumber,
    String receiverName,
    String receiverPhone,
  ) async {
    final subject = '📦 PRO COLIS - Votre colis a été créé';
    final htmlBody = _buildParcelCreatedEmail(trackingNumber, receiverName, receiverPhone);
    return await sendEmail(email, subject, htmlBody);
  }

  /// Envoie un reçu de livraison
  Future<bool> sendDeliveryReceipt(
    String email,
    String trackingNumber,
    String receiverName,
    DateTime deliveryDate,
    double? price,
  ) async {
    final subject = '📄 PRO COLIS - Reçu de livraison';
    final htmlBody = _buildDeliveryReceiptEmail(trackingNumber, receiverName, deliveryDate, price);
    return await sendEmail(email, subject, htmlBody);
  }

  /// Envoi d'email via SMTP
  Future<bool> sendEmail(String to, String subject, String htmlBody) async {
    try {
      final smtpServer = gmail(smtpUsername!, smtpPassword!);
      
      final message = Message()
        ..from = Address(smtpUsername!, 'PRO COLIS')
        ..recipients.add(to)
        ..subject = subject
        ..html = htmlBody;

      await send(message, smtpServer);
      _log.info('Email sent to $to');
      return true;
    } catch (e) {
      _log.severe('Email sending error: $e');
      return false;
    }
  }

  String _buildLoginOtpEmail(String code) {
    return '''
    <!DOCTYPE html>
    <html>
    <head>
      <meta charset="UTF-8">
      <style>
        body { font-family: 'Segoe UI', Arial, sans-serif; line-height: 1.6; color: #333; }
        .container { max-width: 600px; margin: 0 auto; padding: 20px; }
        .header { background: linear-gradient(135deg, #0B6E3A, #168A48); padding: 30px; text-align: center; border-radius: 10px 10px 0 0; }
        .header h1 { color: white; margin: 0; font-size: 28px; }
        .content { background: #f9f9f9; padding: 30px; border-radius: 0 0 10px 10px; }
        .otp-code { font-size: 36px; font-weight: bold; color: #0B6E3A; text-align: center; padding: 20px; letter-spacing: 5px; background: white; border-radius: 10px; margin: 20px 0; }
        .footer { text-align: center; padding: 20px; font-size: 12px; color: #888; }
        .warning { background: #FFF3E0; padding: 15px; border-radius: 8px; margin: 20px 0; font-size: 14px; }
      </style>
    </head>
    <body>
      <div class="container">
        <div class="header">
          <h1>PRO COLIS</h1>
        </div>
        <div class="content">
          <h2>🔐 Connexion à votre compte</h2>
          <p>Bonjour,</p>
          <p>Vous avez demandé à vous connecter à votre compte PRO COLIS. Utilisez le code ci-dessous :</p>
          
          <div class="otp-code">$code</div>
          
          <p>⚠️ Ce code est valable pendant <strong>10 minutes</strong>.</p>
          
          <div class="warning">
            <strong>🔒 Pour votre sécurité :</strong><br>
            • Ne partagez jamais ce code avec personne<br>
            • Les équipes PRO COLIS ne vous demanderont jamais ce code<br>
            • Si vous n'êtes pas à l'origine de cette demande, ignorez cet email
          </div>
        </div>
        <div class="footer">
          <p>PRO COLIS - Solution de transport interurbain sécurisé</p>
          <p>© 2024 PRO COLIS. Tous droits réservés.</p>
        </div>
      </div>
    </body>
    </html>
    ''';
  }

  String _buildVerificationOtpEmail(String code) {
    return '''
    <!DOCTYPE html>
    <html>
    <head>
      <meta charset="UTF-8">
      <style>
        body { font-family: 'Segoe UI', Arial, sans-serif; line-height: 1.6; color: #333; }
        .container { max-width: 600px; margin: 0 auto; padding: 20px; }
        .header { background: linear-gradient(135deg, #0B6E3A, #168A48); padding: 30px; text-align: center; border-radius: 10px 10px 0 0; }
        .content { background: #f9f9f9; padding: 30px; border-radius: 0 0 10px 10px; }
        .otp-code { font-size: 36px; font-weight: bold; color: #0B6E3A; text-align: center; padding: 20px; letter-spacing: 5px; background: white; border-radius: 10px; margin: 20px 0; }
        .benefits { background: #E8F5ED; padding: 20px; border-radius: 10px; margin: 20px 0; }
        .benefits h3 { color: #0B6E3A; margin-top: 0; }
      </style>
    </head>
    <body>
      <div class="container">
        <div class="header">
          <h1>Bienvenue sur PRO COLIS</h1>
        </div>
        <div class="content">
          <h2>✅ Vérification de votre compte</h2>
          <p>Félicitations pour votre inscription !</p>
          <p>Pour activer votre compte, veuillez utiliser le code de vérification ci-dessous :</p>
          
          <div class="otp-code">$code</div>
          
          <div class="benefits">
            <h3>🎉 Ce qui vous attend avec PRO COLIS :</h3>
            <ul>
              <li>📦 Suivi en temps réel de vos colis</li>
              <li>🔔 Notifications SMS et Email</li>
              <li>📍 Géolocalisation des chauffeurs</li>
              <li>📸 Photos de vos colis</li>
              <li>📄 Reçus numériques</li>
            </ul>
          </div>
          
          <p>Ce code est valable <strong>10 minutes</strong>.</p>
        </div>
        <div class="footer">
          <p>PRO COLIS - Simplifiez la gestion de vos colis</p>
        </div>
      </div>
    </body>
    </html>
    ''';
  }

  String _buildPasswordResetOtpEmail(String code) {
    return '''
    <!DOCTYPE html>
    <html>
    <head>
      <meta charset="UTF-8">
      <style>
        body { font-family: 'Segoe UI', Arial, sans-serif; line-height: 1.6; color: #333; }
        .container { max-width: 600px; margin: 0 auto; padding: 20px; }
        .header { background: linear-gradient(135deg, #0B6E3A, #168A48); padding: 30px; text-align: center; border-radius: 10px 10px 0 0; }
        .content { background: #f9f9f9; padding: 30px; border-radius: 0 0 10px 10px; }
        .otp-code { font-size: 36px; font-weight: bold; color: #0B6E3A; text-align: center; padding: 20px; letter-spacing: 5px; background: white; border-radius: 10px; margin: 20px 0; }
        .warning { background: #FFEBEE; padding: 15px; border-radius: 8px; margin: 20px 0; }
      </style>
    </head>
    <body>
      <div class="container">
        <div class="header">
          <h1>Réinitialisation du mot de passe</h1>
        </div>
        <div class="content">
          <h2>🔑 Mot de passe oublié ?</h2>
          <p>Vous avez demandé à réinitialiser votre mot de passe.</p>
          <p>Utilisez le code ci-dessous :</p>
          
          <div class="otp-code">$code</div>
          
          <div class="warning">
            <strong>⚠️ Attention :</strong><br>
            Si vous n'avez pas demandé cette réinitialisation, ignorez cet email. 
            Votre mot de passe restera inchangé.
          </div>
          
          <p>Ce code expire dans <strong>10 minutes</strong>.</p>
        </div>
        <div class="footer">
          <p>PRO COLIS - Service client disponible 24/7</p>
        </div>
      </div>
    </body>
    </html>
    ''';
  }

  String _buildParcelCreatedEmail(String trackingNumber, String receiverName, String receiverPhone) {
    return '''
    <!DOCTYPE html>
    <html>
    <head>
      <meta charset="UTF-8">
      <style>
        body { font-family: 'Segoe UI', Arial, sans-serif; }
        .container { max-width: 600px; margin: 0 auto; padding: 20px; }
        .tracking { font-size: 24px; font-weight: bold; color: #0B6E3A; font-family: monospace; }
      </style>
    </head>
    <body>
      <div class="container">
        <h2>📦 Colis créé avec succès</h2>
        <p>Votre colis a bien été enregistré dans notre système.</p>
        
        <h3>Numéro de suivi :</h3>
        <div class="tracking">$trackingNumber</div>
        
        <h3>Informations :</h3>
        <ul>
          <li><strong>Destinataire :</strong> $receiverName</li>
          <li><strong>Téléphone :</strong> $receiverPhone</li>
        </ul>
        
        <p>🔗 Suivez votre colis : <a href="https://procolis.com/track/$trackingNumber">https://procolis.com/track/$trackingNumber</a></p>
        
        <p>Vous serez notifié à chaque étape du transport.</p>
      </div>
    </body>
    </html>
    ''';
  }

  String _buildDeliveryReceiptEmail(
    String trackingNumber,
    String receiverName,
    DateTime deliveryDate,
    double? price,
  ) {
    return '''
    <!DOCTYPE html>
    <html>
    <head>
      <meta charset="UTF-8">
      <style>
        body { font-family: 'Segoe UI', Arial, sans-serif; }
        .receipt { background: white; padding: 20px; border: 1px solid #ddd; border-radius: 10px; }
        .header { text-align: center; border-bottom: 2px solid #0B6E3A; padding-bottom: 10px; margin-bottom: 20px; }
      </style>
    </head>
    <body>
      <div class="receipt">
        <div class="header">
          <h2>PRO COLIS</h2>
          <h3>📄 REÇU DE LIVRAISON</h3>
        </div>
        
        <p><strong>N° de suivi :</strong> $trackingNumber</p>
        <p><strong>Destinataire :</strong> $receiverName</p>
        <p><strong>Date de livraison :</strong> ${deliveryDate.toLocal().toString()}</p>
        ${price != null ? '<p><strong>Montant :</strong> ${price.toStringAsFixed(0)} FCFA</p>' : ''}
        
        <hr>
        <p><strong>Statut :</strong> ✅ Livré avec succès</p>
        <p>Merci d'avoir utilisé PRO COLIS !</p>
      </div>
    </body>
    </html>
    ''';
  }
}