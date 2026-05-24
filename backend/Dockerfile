# backend/Dockerfile
FROM dart:stable AS build

WORKDIR /app

# Copier uniquement les fichiers de dépendances d'abord
COPY pubspec.yaml pubspec.lock* ./

# Supprimer le cache existant et forcer le téléchargement
RUN rm -rf ~/.pub-cache
RUN dart pub get --verbose

# Copier tout le code source
COPY . .

# Vérifier que les packages sont bien installés
RUN ls -la ~/.pub-cache/hosted/pub.dev/

# Compiler l'application
RUN dart compile exe bin/server.dart -o server || dart run bin/server.dart

# Image de production
FROM debian:bullseye-slim

RUN apt-get update && apt-get install -y \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Créer le dossier uploads
RUN mkdir -p uploads/parcels uploads/profiles

# Copier l'exécutable
COPY --from=build /app/server .
COPY --from=build /app/uploads ./uploads || true
COPY --from=build /app/.env .env || true

EXPOSE 8080

CMD ["./server"]