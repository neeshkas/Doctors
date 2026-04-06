# Этап 1: Сборка Flutter Web
FROM ghcr.io/cirruslabs/flutter:3.24.0 AS build

WORKDIR /app
COPY pubspec.yaml pubspec.lock* ./
RUN flutter pub get
COPY . .
RUN flutter build web --release

# Этап 2: Nginx для раздачи статики
FROM nginx:1.27-alpine
COPY --from=build /app/build/web /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf
EXPOSE 80
