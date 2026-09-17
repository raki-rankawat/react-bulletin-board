# Node 12 is the LTS that react-scripts 3.1.1 (webpack 4) shipped against, and
# the npm it bundles (6.x) keeps package-lock.json at lockfileVersion 1.
# Do NOT bump this image: Node >= 17 fails webpack 4 with
# "error:0308010C:digital envelope routines::unsupported".
FROM node:12-alpine AS deps
WORKDIR /app
COPY package.json package-lock.json ./
RUN npm ci

# --- development: CRA dev server on :3000 -----------------------------------
FROM deps AS dev
# CRA 3 binds HOST=0.0.0.0 by default, so the server is reachable from outside.
# Polling is required for file watching through a bind mount.
ENV CHOKIDAR_USEPOLLING=true
COPY . .
EXPOSE 3000
CMD ["npm", "start"]

# --- production build -------------------------------------------------------
FROM deps AS builder
COPY . .
RUN npm run build

FROM nginx:1.27-alpine AS prod
COPY --from=builder /app/build /usr/share/nginx/html
EXPOSE 80
