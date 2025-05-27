# Stage 1: build the app
FROM node:lts-alpine AS builder
WORKDIR /app

# 1. Install Git for version info
RUN apk update && apk add --no-cache git

# 2. Copy manifests & install JS deps without running postinstall scripts
COPY package*.json ./
RUN npm ci --ignore-scripts

# 3. Copy source
COPY . .

# 4. Patch package.json to redefine "build" → only "build:app"
RUN node -e "\
  const fs = require('fs'); \
  const pkg = JSON.parse(fs.readFileSync('package.json')); \
  pkg.scripts.build = 'run-s build:app'; \
  fs.writeFileSync('package.json', JSON.stringify(pkg, null, 2));"

# 5. Produce production bundle
RUN npm run build

# Stage 2: serve via nginx
FROM nginx:stable-alpine
RUN rm -rf /usr/share/nginx/html/*
COPY --from=builder /app/build /usr/share/nginx/html
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
