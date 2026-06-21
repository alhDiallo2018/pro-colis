// lib/config/constants.dart
class AppConstants {
  static const int parcelCreationPoints = 1;
  static const int parcelAcceptancePoints = 1;
  static const int parcelDeliveryPoints = 1;
  static const int welcomeBonusPoints = 5;
  static const int referralBonusPoints = 2;
  static const int minPurchasePoints = 1;
  static const int maxPurchasePoints = 1000;
  static const int pricePerPoint = 100; // FCFA

  static const String transactionTypeParcelCreation = 'parcel_creation';
  static const String transactionTypeParcelAcceptance = 'parcel_acceptance';
  static const String transactionTypeParcelDelivery = 'parcel_delivery';
  static const String transactionTypePurchase = 'purchase';
  static const String transactionTypeBonus = 'bonus';
  static const String transactionTypeRefund = 'refund';

  static const String transactionStatusPending = 'pending';
  static const String transactionStatusCompleted = 'completed';
  static const String transactionStatusFailed = 'failed';
  static const String transactionStatusRefunded = 'refunded';
}