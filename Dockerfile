FROM ghcr.io/openclaw/openclaw:2026.5.6

USER root

# 更换为国内/稳定镜像源（以清华源为例）
RUN sed -i 's/deb.debian.org/mirrors.tuna.tsinghua.edu.cn/g' /etc/apt/sources.list.d/debian.sources 2>/dev/null || \
    sed -i 's/deb.debian.org/mirrors.tuna.tsinghua.edu.cn/g' /etc/apt/sources.list

# 安装 Chrome 及 Puppeteer 依赖
RUN apt-get update && \
    apt-get install -y --fix-missing --no-install-recommends \
    libnspr4 libnss3 libatk1.0-0 libatk-bridge2.0-0 \
    libcups2 libdrm2 libxkbcommon0 libxcomposite1 \
    libxdamage1 libxfixes3 libxrandr2 libgbm1 libasound2 \
    libxshmfence1 ca-certificates fonts-liberation \
    libappindicator3-1 libasound2-plugins libcurl4 \
    libdbus-glib-1-2 libgtk-3-0 libx11-xcb1 xdg-utils \
    wget curl gnupg && \
    rm -rf /var/lib/apt/lists/*

# 安装 Google Chrome（使用 gpg 方式替代 apt-key）
RUN wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | gpg --dearmor > /etc/apt/trusted.gpg.d/google-chrome.gpg && \
    echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" > /etc/apt/sources.list.d/google-chrome.list && \
    apt-get update && \
    apt-get install -y google-chrome-stable --no-install-recommends && \
    rm -rf /var/lib/apt/lists/*

# 设置 Chrome 路径环境变量（对 node 用户生效）
ENV PUPPETEER_EXECUTABLE_PATH=/usr/bin/google-chrome-stable

# 确保 node 用户有权限访问 Chrome
RUN chown -R node:node /usr/bin/google-chrome-stable || true

# 确保 node 用户可以写入 Puppeteer 缓存
RUN mkdir -p /home/node/.cache/puppeteer && \
    chown -R node:node /home/node/.cache

# 如果你的 entrypoint.sh 需要修改，复制并设置权限
COPY --chmod=755 entrypoint.sh /entrypoint.sh
RUN chown node:node /entrypoint.sh

# 保持 USER root，让 entrypoint.sh 处理权限修复和用户切换
# 不要切换用户，因为 entrypoint.sh 会处理

ENTRYPOINT ["/entrypoint.sh"]
CMD ["openclaw", "gateway", "run"]