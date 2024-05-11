FROM node:20.11.1

# Install the latest Chrome dev package and necessary fonts and libraries
RUN apt-get update \\
    && apt-get install -y wget gnupg \\
    && wget -q -O - <https://dl-ssl.google.com/linux/linux_signing_key.pub> | gpg --dearmor -o /usr/share/keyrings/googlechrome-linux-keyring.gpg \\
    && echo "deb [arch=amd64 signed-by=/usr/share/keyrings/googlechrome-linux-keyring.gpg] <https://dl-ssl.google.com/linux/chrome/deb/> stable main" > /etc/apt/sources.list.d/google.list \\
    && apt-get update \\
    && apt-get install -y google-chrome-stable fonts-ipafont-gothic fonts-wqy-zenhei fonts-thai-tlwg fonts-khmeros fonts-kacst fonts-freefont-ttf libxss1 dbus dbus-x11 \\
    --no-install-recommends \\
    && rm -rf /var/lib/apt/lists/* \\
    && groupadd -r apify && useradd -rm -g apify -G audio,video apify

# Determine the path of the installed Google Chrome
RUN which google-chrome-stable || true

# Switch to the non-root user
USER apify

# Set the working directory
WORKDIR /home/apify

# Copy package.json and package-lock.json
COPY --chown=apify:apify package*.json ./

# Install Puppeteer without downloading bundled Chromium
RUN npm install puppeteer --no-save

# Copy your Puppeteer script into the Docker image
COPY --chown=apify:apify . .

# Update the PUPPETEER_EXECUTABLE_PATH to the correct Chrome path (placeholder, update based on the output of `which google-chrome-stable`)
ENV PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=true \
    PUPPETEER_EXECUTABLE_PATH=/usr/bin/google-chrome-stable

# Set the command to run your Puppeteer script
CMD ["node", "puppeteer-script.js"]
