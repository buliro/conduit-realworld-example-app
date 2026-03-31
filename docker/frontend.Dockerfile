FROM node:22-alpine AS build

WORKDIR /app

COPY package.json package-lock.json ./
COPY frontend/package.json ./frontend/package.json

RUN npm install --workspace frontend

COPY frontend ./frontend

RUN npm run build -w frontend

FROM nginx:1.27-alpine AS runner

RUN rm /etc/nginx/conf.d/default.conf \
  && printf '%s\n' \
  'server {' \
  '    listen 8080;' \
  '    server_name _;' \
  '    root /usr/share/nginx/html;' \
  '    index index.html;' \
  '' \
  '    location / {' \
  '        try_files $uri $uri/ /index.html;' \
  '    }' \
  '' \
  '    location = /healthz {' \
  '        access_log off;' \
  '        add_header Content-Type text/plain;' \
  '        return 200 "ok";' \
  '    }' \
  '' \
  '    location ~* \.(?:css|js|mjs|json|jpg|jpeg|gif|png|svg|ico|webp|woff2?)$ {' \
  '        expires 7d;' \
  '        add_header Cache-Control "public, max-age=604800, immutable";' \
  '        try_files $uri =404;' \
  '    }' \
  '}' \
  > /etc/nginx/conf.d/default.conf \
  && mkdir -p /var/cache/nginx /var/run /tmp/nginx \
  && chown -R nginx:nginx /usr/share/nginx/html /var/cache/nginx /var/run /tmp/nginx /etc/nginx/conf.d

COPY --from=build /app/frontend/dist /usr/share/nginx/html

USER nginx

EXPOSE 8080
