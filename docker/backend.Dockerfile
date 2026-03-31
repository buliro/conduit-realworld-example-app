FROM node:22-alpine AS deps

WORKDIR /app

COPY package.json package-lock.json ./
COPY backend/package.json ./backend/package.json

RUN npm install --omit=dev --workspace backend

FROM node:22-alpine AS runner

ENV NODE_ENV=production

WORKDIR /app

RUN addgroup -S appgroup && adduser -S appuser -G appgroup

COPY --from=deps /app/node_modules ./node_modules
COPY backend ./backend

WORKDIR /app/backend

USER appuser

EXPOSE 3001

CMD ["node", "index.js"]
