FROM dart:stable

WORKDIR /app

# Copier tout le code
COPY . .

# Installer les dépendances
RUN dart pub get

# Créer les dossiers uploads
RUN mkdir -p uploads/parcels uploads/profiles

EXPOSE 8080

# Exécuter sans compilation AOT
CMD ["dart", "run", "bin/server.dart"]