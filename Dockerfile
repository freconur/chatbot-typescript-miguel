# FROM bitnami/node:18-debian-12 as builder
FROM bitnami/node:22.1.0 as builder
# RUN apt-get install -y python make gcc g++
WORKDIR /app
RUN apt-get update \
    && apt-get install -y wget gnupg \
    && wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add - \
    && sh -c 'echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" >> /etc/apt/sources.list.d/google.list' \
    && apt-get update \
    && apt-get install -y google-chrome-stable fonts-ipafont-gothic fonts-wqy-zenhei fonts-thai-tlwg fonts-kacst fonts-freefont-ttf libxss1 \
    --no-install-recommends \
    && rm -rf /var/lib/apt/lists/*
RUN corepack enable && corepack prepare pnpm@latest --activate

ENV PUPPETEER_SKIP_CHROMIUM_DOWNLOAD true
ENV PNPM_HOME=/usr/local/bin

COPY package*.json *-lock.yaml ./
# RUN npm install node-gyp -g
COPY . .
# RUN npm ci
# RUN npm run build && \
#     npm prune --production
#  apk add --no-cache --virtual .gyp \
# RUN apt-get install --no-cache --virtual .gyp \
# RUN   python3 \
#     make \
#     g++ \
    # && apt-get install --no-cache git \
    RUN pnpm install && pnpm run build
    # && apt-get remove .gyp

FROM bitnami/node:22.1.0 as deploy
# RUN apt-get install -y python make gcc g++
WORKDIR /app

ARG PORT
ENV PORT $PORT
EXPOSE $PORT

RUN apt-get update \
    && apt-get install -y wget gnupg \
    && wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add - \
    && sh -c 'echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" >> /etc/apt/sources.list.d/google.list' \
    && apt-get update \
    && apt-get install -y google-chrome-stable fonts-ipafont-gothic fonts-wqy-zenhei fonts-thai-tlwg fonts-kacst fonts-freefont-ttf libxss1 \
    --no-install-recommends \
    && rm -rf /var/lib/apt/lists/*

RUN corepack enable && corepack prepare pnpm@latest --activate 
ENV PNPM_HOME=/usr/local/bin
ENV PUPPETEER_SKIP_CHROMIUM_DOWNLOAD true
# RUN npm install node-gyp -g
COPY --from=builder /app/assets ./assets
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/*.json /app/*-lock.yaml ./
# RUN npm ci
# RUN npm cache clean --force && pnpm install --production --ignore-scripts \
#     && addgroup -g 1001 -S nodejs && adduser -S -u 1001 nodejs \
#     && rm -rf $PNPM_HOME/.npm $PNPM_HOME/.node-gyp
    RUN pnpm install --production --ignore-scripts

CMD ["node","./dist/app.js"]
