// lib/controllers/track_controller.dart
import 'dart:convert';
import 'dart:io';

import 'package:shelf/shelf.dart';

import '../models/parcel.dart';
import '../services/email_service.dart';
import '../services/parcel_service.dart';

class TrackController {
  static EmailService? _emailService;

  static EmailService get emailService {
    if (_emailService == null) {
      final useBrevo = Platform.environment['USE_BREVO'] == 'true';
      
      if (useBrevo) {
        _emailService = EmailService.forBrevo(
          apiKey: Platform.environment['BREVO_API_KEY'] ?? '',
          fromEmail: Platform.environment['BREVO_FROM_EMAIL'] ?? 'contact@procolis.sn',
          fromName: Platform.environment['BREVO_FROM_NAME'] ?? 'PRO COLIS',
        );
      } else {
        _emailService = EmailService.forSmtp(
          smtpHost: Platform.environment['SMTP_HOST'] ?? 'smtp.gmail.com',
          smtpPort: int.tryParse(Platform.environment['SMTP_PORT'] ?? '587') ?? 587,
          smtpSecure: Platform.environment['SMTP_SECURE'] == 'true',
          smtpUser: Platform.environment['SMTP_USER'] ?? '',
          smtpPass: Platform.environment['SMTP_PASS'] ?? '',
          smtpFrom: Platform.environment['SMTP_FROM'] ?? 'contact@procolis.sn',
          fromName: Platform.environment['SMTP_FROM_NAME'] ?? 'PRO COLIS',
        );
      }
    }
    return _emailService!;
  }

  static Future<Response> renderTrackPage(String trackingNumber) async {
    try {
      final parcelService = ParcelService(emailService: emailService);
      final parcelMap = await parcelService.getParcelByTrackingNumber(trackingNumber);

      if (parcelMap == null) {
        final html = _renderError('Colis non trouvé: $trackingNumber');
        return Response.ok(html, headers: {'Content-Type': 'text/html; charset=utf-8'});
      }

      // Récupérer les événements du colis
      final events = await parcelService.getParcelEvents(parcelMap['id'] ?? '');

      // Convertir manuellement le Map en Parcel
      final parcel = _convertMapToParcel(parcelMap);
      
      // Ajouter les événements au parcel
      final parcelWithEvents = parcel.copyWith(events: events);
      
      final html = _renderTrackPageHtml(parcelWithEvents);
      return Response.ok(html, headers: {'Content-Type': 'text/html; charset=utf-8'});

    } catch (e) {
      print('❌ Erreur renderTrackPage: $e');
      final html = _renderError('Erreur: ${e.toString()}');
      return Response.internalServerError(
        body: html,
        headers: {'Content-Type': 'text/html; charset=utf-8'}
      );
    }
  }

  static Future<Response> apiTrack(String trackingNumber) async {
    try {
      final parcelService = ParcelService(emailService: emailService);
      final parcelMap = await parcelService.getParcelByTrackingNumber(trackingNumber);

      if (parcelMap == null) {
        return Response.notFound(
          jsonEncode({
            'success': false,
            'message': 'Colis non trouvé'
          }),
          headers: {'Content-Type': 'application/json; charset=utf-8'}
        );
      }

      // Récupérer les événements
      final events = await parcelService.getParcelEvents(parcelMap['id'] ?? '');
      
      final parcel = _convertMapToParcel(parcelMap);
      final parcelWithEvents = parcel.copyWith(events: events);
      final parcelData = parcelWithEvents.toJson();

      return Response.ok(
        jsonEncode({
          'success': true,
          'data': parcelData,
        }),
        headers: {'Content-Type': 'application/json; charset=utf-8'}
      );

    } catch (e) {
      print('❌ Erreur apiTrack: $e');
      return Response.internalServerError(
        body: jsonEncode({
          'success': false,
          'message': 'Erreur serveur: ${e.toString()}'
        }),
        headers: {'Content-Type': 'application/json; charset=utf-8'}
      );
    }
  }

  /// Convertit un Map en objet Parcel avec gestion des noms de colonnes
  static Parcel _convertMapToParcel(Map<String, dynamic> map) {
    // Fonction pour récupérer une valeur avec plusieurs noms possibles
    String getString(String key, {String? altKey}) {
      final value = map[key] ?? map[altKey];
      return value?.toString() ?? '';
    }

    double getDouble(String key, {String? altKey}) {
      final value = map[key] ?? map[altKey];
      if (value == null) return 0.0;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) return double.tryParse(value) ?? 0.0;
      return 0.0;
    }

    bool getBool(String key, {String? altKey}) {
      final value = map[key] ?? map[altKey];
      if (value == null) return false;
      if (value is bool) return value;
      if (value is String) return value.toLowerCase() == 'true';
      return false;
    }

    DateTime getDateTime(String key, {String? altKey}) {
      final value = map[key] ?? map[altKey];
      if (value == null) return DateTime.now();
      if (value is DateTime) return value;
      if (value is String) {
        try {
          return DateTime.parse(value);
        } catch (e) {
          return DateTime.now();
        }
      }
      return DateTime.now();
    }

    List<String> getList(String key, {String? altKey}) {
      final value = map[key] ?? map[altKey];
      if (value == null) return [];
      if (value is List) {
        return value.map((e) => e?.toString() ?? '').toList();
      }
      if (value is String && value.isNotEmpty) {
        try {
          final decoded = jsonDecode(value);
          if (decoded is List) {
            return decoded.map((e) => e?.toString() ?? '').toList();
          }
        } catch (e) {}
      }
      return [];
    }

    return Parcel(
      id: getString('id'),
      trackingNumber: getString('trackingNumber', altKey: 'tracking_number'),
      senderId: getString('senderId', altKey: 'sender_id'),
      senderName: getString('senderName', altKey: 'sender_name'),
      senderPhone: getString('senderPhone', altKey: 'sender_phone'),
      senderEmail: getString('senderEmail', altKey: 'sender_email'),
      receiverName: getString('receiverName', altKey: 'receiver_name'),
      receiverPhone: getString('receiverPhone', altKey: 'receiver_phone'),
      receiverEmail: getString('receiverEmail', altKey: 'receiver_email'),
      receiverAddress: getString('receiverAddress', altKey: 'receiver_address'),
      description: getString('description'),
      weight: getDouble('weight'),
      length: getDouble('length'),
      width: getDouble('width'),
      height: getDouble('height'),
      type: ParcelType.fromString(getString('type', altKey: 'type')),
      status: ParcelStatus.fromString(getString('status')),
      departureGarageId: getString('departureGarageId', altKey: 'departure_garage_id'),
      departureGarageName: getString('departureGarageName', altKey: 'departure_garage_name'),
      arrivalGarageId: getString('arrivalGarageId', altKey: 'arrival_garage_id'),
      arrivalGarageName: getString('arrivalGarageName', altKey: 'arrival_garage_name'),
      driverId: getString('driverId', altKey: 'driver_id'),
      driverName: getString('driverName', altKey: 'driver_name'),
      driverPhone: getString('driverPhone', altKey: 'driver_phone'),
      price: getDouble('price'),
      deliveryFees: getDouble('deliveryFees', altKey: 'delivery_fees'),
      totalAmount: getDouble('totalAmount', altKey: 'total_amount'),
      paymentMethod: map['paymentMethod'] != null || map['payment_method'] != null
          ? PaymentMethod.fromString(getString('paymentMethod', altKey: 'payment_method'))
          : null,
      paymentPhoneNumber: getString('paymentPhoneNumber', altKey: 'payment_phone_number'),
      paymentStatus: getString('paymentStatus', altKey: 'payment_status'),
      photoUrls: getList('photoUrls', altKey: 'photo_urls'),
      videoUrls: getList('videoUrls', altKey: 'video_urls'),
      audioUrls: getList('audioUrls', altKey: 'audio_urls'),
      signatureUrl: getString('signatureUrl', altKey: 'signature_url'),
      isInsured: getBool('isInsured', altKey: 'is_insured'),
      insuranceAmount: getDouble('insuranceAmount', altKey: 'insurance_amount'),
      isUrgent: getBool('isUrgent', altKey: 'is_urgent'),
      urgentFee: getDouble('urgentFee', altKey: 'urgent_fee'),
      notes: getString('notes'),
      pickupDate: getDateTime('pickupDate', altKey: 'pickup_date'),
      deliveryDate: map['deliveryDate'] != null || map['delivery_date'] != null
          ? getDateTime('deliveryDate', altKey: 'delivery_date')
          : null,
      estimatedDeliveryDate: map['estimatedDeliveryDate'] != null || map['estimated_delivery_date'] != null
          ? getDateTime('estimatedDeliveryDate', altKey: 'estimated_delivery_date')
          : null,
      createdAt: getDateTime('createdAt', altKey: 'created_at'),
      updatedAt: map['updatedAt'] != null || map['updated_at'] != null
          ? getDateTime('updatedAt', altKey: 'updated_at')
          : null,
      createdBy: getString('createdBy', altKey: 'created_by'),
      createdByName: getString('createdByName', altKey: 'created_by_name'),
      cancelledBy: getString('cancelledBy', altKey: 'cancelled_by'),
      cancellationReason: getString('cancellationReason', altKey: 'cancellation_reason'),
      cancelledAt: map['cancelledAt'] != null || map['cancelled_at'] != null
          ? getDateTime('cancelledAt', altKey: 'cancelled_at')
          : null,
      scoreDebited: getBool('scoreDebited', altKey: 'score_debited'),
      scoreRefunded: getBool('scoreRefunded', altKey: 'score_refunded'),
      isFreeForBidding: getBool('isFreeForBidding', altKey: 'is_free_for_bidding'),
      proposedPrice: getDouble('proposedPrice', altKey: 'proposed_price'),
      negotiatedPrice: getDouble('negotiatedPrice', altKey: 'negotiated_price'),
      selectedBidId: getString('selectedBidId', altKey: 'selected_bid_id'),
      bids: [], // Les bids sont chargés séparément
      events: [], // Les événements sont chargés séparément
    );
  }

  static String _renderTrackPageHtml(Parcel parcel) {
    final statusValue = parcel.status.value;
    final statusLabel = _getStatusLabel(statusValue);
    final isDelivered = statusValue == 'delivered';
    
    final date = parcel.createdAt.toIso8601String().substring(0, 10);
    final price = '${parcel.price?.toStringAsFixed(0) ?? '0'} FCFA';
    final weight = '${parcel.weight} kg';
    
    // Construire la timeline à partir des événements
    final statusOrder = ['pending', 'free', 'confirmed', 'picked_up', 'in_transit', 'arrived', 'out_for_delivery', 'delivered', 'cancelled'];
    final statusIcons = {
      'pending': '📝',
      'free': '🔓',
      'confirmed': '✅',
      'picked_up': '📦',
      'in_transit': '🚚',
      'arrived': '📍',
      'out_for_delivery': '🚗',
      'delivered': '🏠',
      'cancelled': '❌'
    };
    final statusLabels = {
      'pending': 'Création',
      'free': 'Libre service',
      'confirmed': 'Confirmé',
      'picked_up': 'Ramassé',
      'in_transit': 'En transit',
      'arrived': 'Arrivé',
      'out_for_delivery': 'En livraison',
      'delivered': 'Livré',
      'cancelled': 'Annulé'
    };

    // Créer un mapping des événements par statut pour récupérer les dates
    final eventDates = <String, String>{};
    for (final event in parcel.events) {
      final status = event['status']?.toString() ?? '';
      final timestamp = event['timestamp']?.toString() ?? event['created_at']?.toString() ?? '';
      if (status.isNotEmpty && timestamp.isNotEmpty) {
        try {
          final dateTime = DateTime.parse(timestamp);
          eventDates[status] = '${dateTime.day}/${dateTime.month}/${dateTime.year} à ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
        } catch (e) {
          eventDates[status] = timestamp.substring(0, 10);
        }
      }
    }

    final currentIndex = statusOrder.indexOf(statusValue);
    
    final steps = statusOrder.asMap().entries.map((entry) {
      final index = entry.key;
      final status = entry.value;
      final completed = index <= currentIndex && statusValue != 'cancelled';
      final current = index == currentIndex && statusValue != 'cancelled';
      final dateString = eventDates[status] ?? null;
      
      return {
        'status': status,
        'label': statusLabels[status] ?? status,
        'icon': statusIcons[status] ?? '📌',
        'completed': completed,
        'current': current,
        'date': dateString
      };
    }).toList();

    return '''
    <!DOCTYPE html>
    <html lang="fr">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Suivi de colis - PRO COLIS</title>
        <style>
            * { margin: 0; padding: 0; box-sizing: border-box; }
            body {
                font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, sans-serif;
                background: #f5f5f5;
                min-height: 100vh;
                display: flex;
                justify-content: center;
                align-items: center;
                padding: 20px;
            }
            .container {
                max-width: 500px;
                width: 100%;
                background: white;
                border-radius: 24px;
                box-shadow: 0 10px 40px rgba(0,0,0,0.1);
                overflow: hidden;
            }
            .header {
                background: linear-gradient(135deg, #0B6E3A, #0D8C46);
                padding: 30px 24px;
                color: white;
            }
            .header-content {
                display: flex;
                justify-content: space-between;
                align-items: flex-start;
            }
            .header-left h1 { font-size: 24px; font-weight: 700; }
            .header-left p { opacity: 0.8; font-size: 14px; margin-top: 4px; }
            .status-badge {
                background: ${isDelivered ? '#4CAF50' : statusValue == 'cancelled' ? '#f44336' : '#FF9800'};
                color: white;
                padding: 6px 16px;
                border-radius: 20px;
                font-size: 12px;
                font-weight: 600;
                display: inline-flex;
                align-items: center;
                gap: 6px;
            }
            .body { padding: 24px; }
            .tracking-number {
                background: #f8f9fa;
                border-radius: 12px;
                padding: 16px;
                display: flex;
                align-items: center;
                gap: 12px;
                border: 1px solid #e9ecef;
                margin-bottom: 20px;
            }
            .tracking-number .icon {
                background: rgba(11, 110, 58, 0.1);
                padding: 10px;
                border-radius: 8px;
                color: #0B6E3A;
            }
            .tracking-number .label { font-size: 11px; color: #6c757d; font-weight: 500; }
            .tracking-number .value {
                font-size: 16px;
                font-weight: 700;
                color: #1a2b3c;
                font-family: monospace;
            }
            .info-grid {
                display: grid;
                grid-template-columns: 1fr 1fr;
                gap: 12px;
                margin-bottom: 20px;
            }
            .info-card {
                background: #f8f9fa;
                border-radius: 12px;
                padding: 14px;
                border: 1px solid #e9ecef;
            }
            .info-card .icon { font-size: 16px; margin-bottom: 4px; }
            .info-card .label {
                font-size: 10px;
                color: #6c757d;
                font-weight: 500;
                text-transform: uppercase;
                letter-spacing: 0.5px;
            }
            .info-card .value {
                font-size: 14px;
                font-weight: 600;
                color: #1a2b3c;
                margin-top: 2px;
                word-break: break-word;
            }
            .info-card.full-width { grid-column: 1 / -1; }
            .timeline {
                margin: 24px 0;
                padding: 20px 0;
                border-top: 1px solid #e9ecef;
                border-bottom: 1px solid #e9ecef;
            }
            .timeline-title {
                font-size: 14px;
                font-weight: 600;
                color: #1a2b3c;
                margin-bottom: 16px;
            }
            .timeline-item {
                display: flex;
                gap: 16px;
                padding: 8px 0;
                position: relative;
            }
            .timeline-item:not(:last-child)::after {
                content: '';
                position: absolute;
                left: 15px;
                top: 32px;
                bottom: 0;
                width: 2px;
                background: #e9ecef;
            }
            .timeline-item.completed:not(:last-child)::after { background: #0B6E3A; }
            .timeline-dot {
                width: 32px;
                height: 32px;
                border-radius: 50%;
                background: #e9ecef;
                display: flex;
                align-items: center;
                justify-content: center;
                flex-shrink: 0;
                color: #6c757d;
                font-size: 14px;
                z-index: 1;
            }
            .timeline-item.completed .timeline-dot { background: #0B6E3A; color: white; }
            .timeline-item.current .timeline-dot {
                background: #0B6E3A;
                color: white;
                box-shadow: 0 0 0 4px rgba(11, 110, 58, 0.2);
            }
            .timeline-content .label {
                font-size: 13px;
                font-weight: 500;
                color: #1a2b3c;
            }
            .timeline-content .sub { font-size: 11px; color: #6c757d; }
            .timeline-item.completed .timeline-content .label { color: #0B6E3A; }
            .options {
                display: flex;
                flex-wrap: wrap;
                gap: 8px;
                margin: 16px 0;
            }
            .option-chip {
                padding: 4px 12px;
                border-radius: 20px;
                font-size: 11px;
                font-weight: 500;
                display: inline-flex;
                align-items: center;
                gap: 4px;
            }
            .option-chip.active {
                background: rgba(11, 110, 58, 0.1);
                color: #0B6E3A;
                border: 1px solid rgba(11, 110, 58, 0.2);
            }
            .option-chip.inactive {
                background: #f8f9fa;
                color: #6c757d;
                border: 1px solid #e9ecef;
            }
            .footer {
                background: #f8f9fa;
                padding: 16px 24px;
                text-align: center;
                border-top: 1px solid #e9ecef;
            }
            .footer p { font-size: 11px; color: #6c757d; }
            .footer a { color: #0B6E3A; text-decoration: none; font-weight: 500; }
            @media (max-width: 480px) {
                .info-grid { grid-template-columns: 1fr; }
                .header-content { flex-direction: column; gap: 12px; }
            }
        </style>
    </head>
    <body>
        <div class="container">
            <div class="header">
                <div class="header-content">
                    <div class="header-left">
                        <h1>📦 PRO COLIS</h1>
                        <p>Suivi de colis</p>
                    </div>
                    <div class="status-badge">
                        ${isDelivered ? '✅ Livré' : statusValue == 'cancelled' ? '❌ Annulé' : '📦 En cours'}
                    </div>
                </div>
            </div>
            
            <div class="body">
                <div class="tracking-number">
                    <div class="icon">📋</div>
                    <div>
                        <div class="label">N° de suivi</div>
                        <div class="value">${parcel.trackingNumber}</div>
                    </div>
                </div>
                
                <div class="info-grid">
                    <div class="info-card">
                        <div class="icon">📅</div>
                        <div class="label">Date</div>
                        <div class="value">$date</div>
                    </div>
                    <div class="info-card">
                        <div class="icon">📦</div>
                        <div class="label">Statut</div>
                        <div class="value">$statusLabel</div>
                    </div>
                    <div class="info-card">
                        <div class="icon">👤</div>
                        <div class="label">Expéditeur</div>
                        <div class="value">${parcel.senderName.isNotEmpty ? parcel.senderName : 'Non renseigné'}</div>
                    </div>
                    <div class="info-card">
                        <div class="icon">👤</div>
                        <div class="label">Destinataire</div>
                        <div class="value">${parcel.receiverName.isNotEmpty ? parcel.receiverName : 'Non renseigné'}</div>
                    </div>
                    <div class="info-card">
                        <div class="icon">📍</div>
                        <div class="label">Départ</div>
                        <div class="value">${parcel.departureGarageName.isNotEmpty ? parcel.departureGarageName : 'Non renseigné'}</div>
                    </div>
                    <div class="info-card">
                        <div class="icon">📍</div>
                        <div class="label">Arrivée</div>
                        <div class="value">${parcel.arrivalGarageName?.isNotEmpty == true ? parcel.arrivalGarageName : 'Non renseigné'}</div>
                    </div>
                    <div class="info-card">
                        <div class="icon">⚖️</div>
                        <div class="label">Poids</div>
                        <div class="value">$weight</div>
                    </div>
                    <div class="info-card">
                        <div class="icon">💰</div>
                        <div class="label">Montant</div>
                        <div class="value">$price</div>
                    </div>
                    ${parcel.driverName != null && parcel.driverName!.isNotEmpty ? '''
                    <div class="info-card full-width">
                        <div class="icon">🚗</div>
                        <div class="label">Chauffeur</div>
                        <div class="value">${parcel.driverName}</div>
                    </div>
                    ''' : ''}
                    ${parcel.isFreeForBidding ? '''
                    <div class="info-card full-width">
                        <div class="icon">🔓</div>
                        <div class="label">Mode</div>
                        <div class="value">Libre service - Enchères ouvertes</div>
                    </div>
                    ''' : ''}
                </div>
                
                <div class="options">
                    <span class="option-chip ${parcel.isUrgent ? 'active' : 'inactive'}">
                        ${parcel.isUrgent ? '🚀 Urgent' : '📦 Standard'}
                    </span>
                    <span class="option-chip ${parcel.isInsured ? 'active' : 'inactive'}">
                        ${parcel.isInsured ? '🛡️ Assuré' : '🔒 Non assuré'}
                    </span>
                    ${parcel.isFreeForBidding ? '''
                    <span class="option-chip active">
                        🔓 Enchères
                    </span>
                    ''' : ''}
                </div>
                
                <div class="timeline">
                    <div class="timeline-title">📋 Historique</div>
                    ${steps.map((step) => '''
                    <div class="timeline-item ${step['completed'] != null ? 'completed' : ''} ${step['current'] != null ? 'current' : ''}">
                        <div class="timeline-dot">${step['icon']}</div>
                        <div class="timeline-content">
                            <div class="label">${step['label']}</div>
                            ${step['current'] != null ? '<div class="sub">En cours</div>' : ''}
                            ${step['date'] != null ? '<div class="sub">${step['date']}</div>' : ''}
                        </div>
                    </div>
                    ''').join('')}
                </div>
                
                <div class="footer">
                    <p>
                        PRO COLIS - Service de transport interurbain<br>
                        📞 +221 33 123 45 67 | 📧 contact@procolis.sn<br>
                        📱 <a href="https://procolis.sn">www.procolis.sn</a>
                    </p>
                </div>
            </div>
        </div>
    </body>
    </html>
    ''';
  }

  static String _getStatusLabel(String status) {
    switch (status) {
      case 'pending':
        return 'En attente';
      case 'free':
        return '🔓 Libre service';
      case 'confirmed':
        return 'Confirmé';
      case 'picked_up':
        return 'Ramassé';
      case 'in_transit':
        return 'En transit';
      case 'arrived':
        return 'Arrivé au garage';
      case 'out_for_delivery':
        return 'En cours de livraison';
      case 'delivered':
        return 'Livré avec succès';
      case 'cancelled':
        return 'Annulé';
      default:
        return 'Mise à jour';
    }
  }

  static String _renderError(String message) {
    return '''
    <!DOCTYPE html>
    <html lang="fr">
    <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>Colis non trouvé - PRO COLIS</title>
        <style>
            * { margin: 0; padding: 0; box-sizing: border-box; }
            body {
                font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, sans-serif;
                background: #f5f5f5;
                min-height: 100vh;
                display: flex;
                justify-content: center;
                align-items: center;
                padding: 20px;
            }
            .container {
                max-width: 500px;
                width: 100%;
                background: white;
                border-radius: 24px;
                box-shadow: 0 10px 40px rgba(0,0,0,0.1);
                overflow: hidden;
                padding: 40px 24px;
            }
            .error-container { text-align: center; }
            .error-container .icon { font-size: 48px; margin-bottom: 16px; }
            .error-container h2 { color: #1a2b3c; margin-bottom: 8px; }
            .error-container p { color: #6c757d; margin-bottom: 16px; }
            .btn-primary {
                display: inline-block;
                padding: 10px 24px;
                background: #0B6E3A;
                color: white;
                border-radius: 12px;
                text-decoration: none;
                font-weight: 600;
            }
            .btn-primary:hover { background: #0D8C46; }
        </style>
    </head>
    <body>
        <div class="container">
            <div class="error-container">
                <div class="icon">🔍</div>
                <h2>Colis non trouvé</h2>
                <p>$message</p>
                <a href="/" class="btn-primary">Retour à l'accueil</a>
            </div>
        </div>
    </body>
    </html>
    ''';
  }
}