# Étape 1: Build avec toutes les dépendances
FROM dart:stable AS build

WORKDIR /app

# Copier les fichiers de dépendances
COPY pubspec.* ./
RUN dart pub get

# Copier le code source
COPY . .

# Compiler
RUN dart compile exe bin/server.dart -o server

# Étape 2: Image plus petite
FROM debian:bullseye-slim

RUN apt-get update && apt-get install -y ca-certificates && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Créer les dossiers
RUN mkdir -p uploads/parcels uploads/profiles

# Copier l'exécutable
COPY --from=build /app/server .
COPY --from=build /app/uploads ./uploads || true

EXPOSE 8080

CMD ["./server"]