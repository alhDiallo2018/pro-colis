// lib/routes/index.dart
import 'package:procolis_backend/services/email_service.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';

import 'auth_routes.dart';
import 'client_routes.dart';
import 'driver_routes.dart';
import 'garage_admin_routes.dart';
import 'notification_routes.dart';
import 'public_routes.dart';
import 'score_routes.dart';
import 'super_admin_routes.dart';
import 'track_routes.dart';
import 'upload_routes.dart';

class AppRoutes {
  static Router createRouter({required EmailService emailService}) {
    final router = Router();
    
    // Montage des routes par rôle
    router.mount('/auth', AuthRoutes(emailService: emailService).router);
    router.mount('/public', PublicRoutes(emailService: emailService).router);
    router.mount('/client', ClientRoutes(emailService: emailService).router);
    router.mount('/driver', DriverRoutes(emailService: emailService).router);
    router.mount('/garage-admin', GarageAdminRoutes(emailService: emailService).router);
    router.mount('/super-admin', SuperAdminRoutes(emailService: emailService).router);
    router.mount('/notifications', NotificationRoutes().router);
    router.mount('/upload', UploadRoutes().router);
    router.mount('/score', ScoreRoutes().router);
    
    // ========== ROUTES DE TRACKING ==========
    // Les routes de tracking sont montées à la racine pour être accessibles
    // via /track/ et /api/track/
    router.mount('/', TrackRoutes.handler);
    
    // Route racine
    router.get('/', (Request request) {
      return Response.ok('''
      <!DOCTYPE html>
      <html lang="fr">
      <head>
          <meta charset="UTF-8">
          <meta name="viewport" content="width=device-width, initial-scale=1.0">
          <title>PRO COLIS - Suivi de colis</title>
          <style>
              * { margin: 0; padding: 0; box-sizing: border-box; }
              body {
                  font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Oxygen, Ubuntu, sans-serif;
                  background: linear-gradient(135deg, #f5f7fa 0%, #c3cfe2 100%);
                  min-height: 100vh;
                  display: flex;
                  justify-content: center;
                  align-items: center;
                  padding: 20px;
              }
              .container {
                  max-width: 520px;
                  width: 100%;
                  background: white;
                  border-radius: 24px;
                  box-shadow: 0 20px 60px rgba(0,0,0,0.15);
                  padding: 40px 35px;
                  text-align: center;
              }
              .logo {
                  font-size: 56px;
                  margin-bottom: 8px;
              }
              h1 {
                  font-size: 28px;
                  color: #0B6E3A;
                  font-weight: 700;
                  letter-spacing: 1px;
              }
              .subtitle {
                  color: #6c757d;
                  font-size: 15px;
                  margin-top: 6px;
              }
              .features {
                  display: flex;
                  justify-content: center;
                  gap: 30px;
                  margin: 25px 0 30px 0;
              }
              .feature {
                  text-align: center;
              }
              .feature .icon {
                  font-size: 28px;
                  display: block;
                  margin-bottom: 6px;
              }
              .feature .label {
                  font-size: 12px;
                  color: #6c757d;
              }
              .input-group {
                  display: flex;
                  gap: 10px;
                  margin: 20px 0 16px 0;
              }
              input {
                  flex: 1;
                  padding: 14px 18px;
                  border: 2px solid #e9ecef;
                  border-radius: 12px;
                  font-size: 15px;
                  font-family: 'Courier New', monospace;
                  transition: border-color 0.3s;
                  background: #f8f9fa;
              }
              input:focus {
                  outline: none;
                  border-color: #0B6E3A;
                  background: white;
              }
              button {
                  padding: 14px 28px;
                  background: linear-gradient(135deg, #0B6E3A, #0D8C46);
                  color: white;
                  border: none;
                  border-radius: 12px;
                  cursor: pointer;
                  font-size: 15px;
                  font-weight: 600;
                  transition: transform 0.2s, box-shadow 0.2s;
                  white-space: nowrap;
              }
              button:hover {
                  transform: translateY(-2px);
                  box-shadow: 0 4px 15px rgba(11, 110, 58, 0.4);
              }
              .example {
                  font-size: 13px;
                  color: #6c757d;
                  margin-top: 12px;
              }
              .example a {
                  color: #0B6E3A;
                  text-decoration: none;
                  font-weight: 600;
              }
              .example a:hover {
                  text-decoration: underline;
              }
              .footer {
                  margin-top: 25px;
                  padding-top: 20px;
                  border-top: 1px solid #e9ecef;
                  font-size: 12px;
                  color: #adb5bd;
              }
              .footer a {
                  color: #0B6E3A;
                  text-decoration: none;
              }
              @media (max-width: 480px) {
                  .container { padding: 30px 20px; }
                  .input-group { flex-direction: column; }
                  button { width: 100%; }
                  .features { gap: 15px; }
              }
          </style>
      </head>
      <body>
          <div class="container">
              <div class="logo">📦</div>
              <h1>PRO COLIS</h1>
              <p class="subtitle">Suivez vos colis en temps réel</p>
              
              <div class="features">
                  <div class="feature">
                      <span class="icon">🔍</span>
                      <span class="label">Recherche rapide</span>
                  </div>
                  <div class="feature">
                      <span class="icon">📱</span>
                      <span class="label">Suivi en temps réel</span>
                  </div>
                  <div class="feature">
                      <span class="icon">📍</span>
                      <span class="label">Localisation</span>
                  </div>
              </div>
              
              <div class="input-group">
                  <input type="text" id="trackingNumber" placeholder="Ex: COL-20260526-ADE4B8" autofocus>
                  <button onclick="track()">Suivre</button>
              </div>
              
              <div class="example">
                  💡 Essayez: <a href="/track/COL-20260526-ADE4B8">COL-20260526-ADE4B8</a>
              </div>
              
              <div class="footer">
                  <p>📞 +221 33 123 45 67 • 📧 <a href="mailto:contact@procolis.sn">contact@procolis.sn</a></p>
                  <p style="margin-top: 4px;">© 2024 PRO COLIS - Service de transport interurbain</p>
              </div>
          </div>
          <script>
              function track() {
                  const input = document.getElementById('trackingNumber');
                  const value = input.value.trim().toUpperCase();
                  if (value) {
                      window.location.href = '/track/' + encodeURIComponent(value);
                  } else {
                      input.style.borderColor = '#dc3545';
                      setTimeout(() => input.style.borderColor = '#e9ecef', 2000);
                  }
              }
              document.addEventListener('DOMContentLoaded', function() {
                  const input = document.getElementById('trackingNumber');
                  input.addEventListener('keypress', function(e) {
                      if (e.key === 'Enter') track();
                  });
                  // Mettre en majuscules automatiquement
                  input.addEventListener('input', function() {
                      const start = this.selectionStart;
                      const end = this.selectionEnd;
                      this.value = this.value.toUpperCase();
                      this.setSelectionRange(start, end);
                  });
              });
          </script>
      </body>
      </html>
      ''', headers: {'Content-Type': 'text/html; charset=utf-8'});
    });
    
    return router;
  }
}