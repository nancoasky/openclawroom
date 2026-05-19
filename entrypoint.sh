#!/bin/bash
set -e

CONFIG_DIR="/home/node/.openclaw"
AUTH_FILE="$CONFIG_DIR/agents/main/agent/auth-profiles.json"

echo "========================================="
echo "OpenClaw Container Starting..."
echo "========================================="

# 检查是否以 root 运行
if [ "$(id -u)" = "0" ]; then
    echo "🔧 Running as root, fixing permissions..."
    
    # 创建配置目录（如果不存在）
    if [ ! -d "$CONFIG_DIR" ]; then
        echo "   → Creating $CONFIG_DIR"
        mkdir -p "$CONFIG_DIR"
    fi
    
    # 修复配置目录权限
    echo "   → Setting ownership for $CONFIG_DIR"
    chown -R node:node "$CONFIG_DIR" 2>/dev/null || echo "   ⚠️  chown failed (expected on Windows bind mount)"
    
    echo "   → Setting permissions for $CONFIG_DIR"
    chmod -R 755 "$CONFIG_DIR" 2>/dev/null || echo "   ⚠️  chmod failed (expected on Windows bind mount)"
    
    # 特别处理 auth-profiles.json
    if [ -f "$AUTH_FILE" ]; then
        echo "   → Setting permissions for auth-profiles.json"
        chown node:node "$AUTH_FILE" 2>/dev/null || true
        chmod 644 "$AUTH_FILE" 2>/dev/null || true
    fi
    
    echo "✅ Permission fix completed"
    echo "🔄 Switching to node user..."
    
    # 使用 su 的正确方式：直接传递命令字符串
    exec su node -c "openclaw gateway run"
else
    echo "ℹ️  Already running as non-root, skipping permission fix"
    exec openclaw gateway run
fi