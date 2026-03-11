## docker如何安装clawhub
```
# 创建用户全局目录
mkdir -p ~/.npm-global

# 配置 npm 使用新目录
npm config set prefix '~/.npm-global'

# 添加到 PATH
echo 'export PATH=~/.npm-global/bin:$PATH' >> ~/.bashrc
source ~/.bashrc

# 现在可以安装
npm install -g clawhub
```

## docker如何安装tavily-search技能
```
# 1. 进入容器
docker exec -it openclaw bash

# 2. 设置环境变量
export TAVILY_API_KEY="tvly-你的API-Key"

# 3. 写入 ~/.bashrc 永久生效
echo 'export TAVILY_API_KEY="tvly-你的API-Key"' >> ~/.bashrc
source ~/.bashrc

# 4. 验证
echo $TAVILY_API_KEY

# 5. 重启 OpenClaw
openclaw gateway restart
```
如果还是不行则尝试在docker-compose.yml文件中添加对应的TAVILY_API_KEY变量