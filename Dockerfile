# Stage 1: Build Flutter Web
FROM ghcr.io/cirruslabs/flutter:stable AS build

WORKDIR /app
COPY . .
RUN flutter pub get
RUN flutter build web --release

# Stage 2: Serve with Nginx
FROM nginx:alpine
COPY --from=build /app/build/web /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 8080
CMD ["nginx", "-g", "daemon off;"]