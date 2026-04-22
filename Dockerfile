FROM ghcr.io/openclaw/openclaw:2026.4.21

USER root

RUN mkdir -p /var/lib/apt/lists/partial && \
    apt-get update && \
    apt-get install -y --fix-missing --no-install-recommends \
    libnspr4 libnss3 libatk1.0-0 libatk-bridge2.0-0 \
    libcups2 libdrm2 libxkbcommon0 libxcomposite1 \
    libxdamage1 libxfixes3 libxrandr2 libgbm1 libasound2 \
    && rm -rf /var/lib/apt/lists/*

# 不需要安装任何额外工具
# 复制并设置权限在一行完成
COPY --chmod=755 entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
CMD ["openclaw", "gateway", "run"]