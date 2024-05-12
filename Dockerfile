FROM bitnami/node:18-debian-12 as builder

WORKDIR /app
RUN apt-get update \
    && apt-get install -y wget gnupg \
    && wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add - \
    && sh -c 'echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" >> /etc/apt/sources.list.d/google.list' \
    && apt-get update \
    && apt-get install -y google-chrome-stable fonts-ipafont-gothic fonts-wqy-zenhei fonts-thai-tlwg fonts-kacst fonts-freefont-ttf libxss1 \
    --no-install-recommends \
    && rm -rf /var/lib/apt/lists/*
RUN corepack enable && corepack prepare npm@latest --activate

ENV PUPPETEER_SKIP_CHROMIUM_DOWNLOAD true
ENV PNPM_HOME=/usr/local/bin

COPY package*.json *-lock.yaml ./
# RUN npm install node-gyp -g
COPY . .
RUN npm ci
RUN npm run build
    # npm prune --production
#  apk add --no-cache --virtual .gyp \
# RUN apk add --no-cache --virtual .gyp \
#     python3 \
#     make \
#     g++ \
#     && apk add --no-cache git \
#     && pnpm install && pnpm run build \
#     && apk del .gyp

FROM bitnami/node:18-debian-12 as deploy

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

RUN corepack enable && corepack prepare npm@latest  --activate 
ENV PNPM_HOME=/usr/local/bin
ENV PUPPETEER_SKIP_CHROMIUM_DOWNLOAD true
# RUN npm install node-gyp -g
COPY --from=builder /app/assets ./assets
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/*.json /app/*-lock.yaml ./
# RUN npm cache clean --force && pnpm install --production --ignore-scripts \
#     && addgroup -g 1001 -S nodejs && adduser -S -u 1001 nodejs \
#     && rm -rf $PNPM_HOME/.npm $PNPM_HOME/.node-gyp

CMD ["npm","dist","start"]
