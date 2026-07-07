# Stage 1: Build the NestJS application
FROM node:22-alpine AS builder

WORKDIR /app

# Copy package list and lockfiles
COPY package*.json ./
COPY prisma ./prisma/

# Install dependencies (including devDependencies for TypeScript compilation)
RUN npm ci

# Copy the rest of the application files
COPY . .

# Generate Prisma Client
RUN npx prisma generate

# Build the NestJS project
RUN npm run build

# Stage 2: Run the production application
FROM node:22-alpine AS runner

WORKDIR /app

# Install postgresql-client for pg_isready check in entrypoint
RUN apk add --no-cache postgresql-client

ENV NODE_ENV=production

# Copy built resources from builder
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/package*.json ./
COPY --from=builder /app/prisma ./prisma

# Expose the API port
EXPOSE 3000

# Copy and prepare entrypoint
COPY docker-entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

ENTRYPOINT ["docker-entrypoint.sh"]
CMD ["node", "dist/main"]
