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