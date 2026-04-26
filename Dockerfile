# Stage 1: Build the React frontend
FROM node:20-alpine AS frontend-build

WORKDIR /app/frontend
COPY frontend/package.json frontend/package-lock.json* ./
RUN npm install
COPY frontend/ ./
RUN npm run build

# Stage 2: Production backend
FROM node:20-alpine

WORKDIR /app

COPY backend/package.json backend/package-lock.json* ./
RUN npm install --omit=dev

COPY backend/ ./

# Copy the built frontend into the backend's public folder
COPY --from=frontend-build /app/frontend/dist ./public

EXPOSE 5000

CMD ["node", "server.js"]
