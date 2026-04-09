FROM ghcr.io/openclaw/openclaw:2026.4.8

# 不需要安装任何额外工具
# 复制并设置权限在一行完成
COPY --chmod=755 entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
CMD ["openclaw", "gateway", "run"]