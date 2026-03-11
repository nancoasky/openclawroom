# OpenClaw 生产环境管理 Makefile
# 基于 docker-compose.yml 部署 v2026.3.8 版本
# 作者: 根据用户需求定制
# 用法: make [命令]

# 基础变量定义
DOCKER_COMPOSE = docker compose
SERVICE_NAME = openclaw-gateway
DATA_DIR = ./data
NPM_GLOBAL_DIR = ./.npm-global
BASHRC_FILE = ./.bashrc
COMPOSE_FILE = docker-compose.yml
BACKUP_SUFFIX = .backup-$(shell date +%Y%m%d-%H%M%S)

# 颜色输出（美化用）
GREEN = \033[0;32m
YELLOW = \033[1;33m
RED = \033[0;31m
BLUE = \033[0;34m
NC = \033[0m # No Color

.PHONY: help install uninstall start stop restart status logs backup restore \
        backup-data restore-list tui shell config exec update ps clean \
        backup-info check-dir

# 默认目标：显示帮助
help:
	@echo "$(GREEN)OpenClaw 管理 Makefile$(NC)"
	@echo "用法: make [目标]"
	@echo ""
	@echo "📦 安装与卸载:"
	@echo "  install     首次安装并启动 OpenClaw (会创建数据目录)"
	@echo "  uninstall   彻底卸载 (停止服务、删除容器、备份数据)"
	@echo ""
	@echo "🚀 服务生命周期管理:"
	@echo "  start       启动服务 (后台运行)"
	@echo "  stop        停止服务"
	@echo "  restart     重启服务"
	@echo "  status      查看服务状态"
	@echo "  logs        查看实时日志 (Ctrl+C 退出)"
	@echo ""
	@echo "🔄 数据与配置:"
	@echo "  backup      备份所有数据 (data + .npm-global + .bashrc)"
	@echo "  backup-info 查看备份文件详情"
	@echo "  restore     从最新的备份恢复 (交互式选择)"
	@echo "  restore-list 列出所有可用的备份文件"
	@echo ""
	@echo "💬 交互操作:"
	@echo "  tui         进入 TUI 对话模式 (最快聊天方式)"
	@echo "  shell       进入容器内部的 Shell"
	@echo "  config      运行配置向导"
	@echo "  exec CMD    在容器中执行自定义命令 (如: make exec 'openclaw --version')"
	@echo ""
	@echo "🧹 维护工具:"
	@echo "  ps          查看容器进程状态"
	@echo "  update      更新镜像到指定版本 (需手动修改 COMPOSE_FILE 中的版本标签)"
	@echo "  clean       清理停止的容器和无用镜像 (谨慎使用)"

# 📦 安装与卸载

## install: 首次安装并启动
install: check-dir
	@echo "$(GREEN)▶ 步骤1: 检查 Docker 环境...$(NC)"
	@command -v docker >/dev/null 2>&1 || { echo "$(RED)❌ Docker 未安装，请先安装 Docker$(NC)" >&2; exit 1; }
	@$(DOCKER_COMPOSE) version >/dev/null 2>&1 || { echo "$(RED)❌ Docker Compose 不可用$(NC)" >&2; exit 1; }
	@echo "$(GREEN)✅ Docker 环境正常$(NC)"
	
	@echo "$(GREEN)▶ 步骤2: 拉取 OpenClaw 3.8 镜像...$(NC)"
	@$(DOCKER_COMPOSE) pull
	
	@echo "$(GREEN)▶ 步骤3: 启动服务...$(NC)"
	@$(DOCKER_COMPOSE) up -d
	
	@echo "$(GREEN)▶ 步骤4: 等待服务启动...$(NC)"
	@sleep 5
	
	@echo "$(GREEN)✅ 安装完成！$(NC)"
	@echo "$(YELLOW)接下来请完成初始化配置:$(NC)"
	@echo "  1. 进入容器:  make shell"
	@echo "  2. 运行向导:  openclaw onboard"
	@echo "  3. 开始对话:  openclaw tui"
	@echo ""
	@echo "$(YELLOW)数据目录: $(DATA_DIR) 已创建$(NC)"
	@echo "$(YELLOW)NPM全局目录: $(NPM_GLOBAL_DIR) 已创建$(NC)"

## uninstall: 彻底卸载 (备份 + 停止 + 删除)
uninstall: backup
	@echo "$(RED)⚠️  正在执行卸载操作...$(NC)"
	@read -p "确定要彻底卸载 OpenClaw 吗？: "; \
	if [ "$$REPLY" != "y" ] && [ "$$REPLY" != "Y" ]; then \
		echo "$(GREEN)卸载已取消$(NC)"; exit 0; \
	fi
	
	@echo "$(YELLOW)▶ 停止并删除容器...$(NC)"
	@$(DOCKER_COMPOSE) down -v
	
	@echo "$(YELLOW)▶ 备份数据目录 (以防万一)...$(NC)"
	@if [ -d $(DATA_DIR) ]; then \
		mv $(DATA_DIR) $(DATA_DIR)$(BACKUP_SUFFIX); \
		echo "$(GREEN)原数据已重命名为 $(DATA_DIR)$(BACKUP_SUFFIX)$(NC)"; \
	fi
	@if [ -d $(NPM_GLOBAL_DIR) ]; then \
		mv $(NPM_GLOBAL_DIR) $(NPM_GLOBAL_DIR)$(BACKUP_SUFFIX); \
		echo "$(GREEN)原NPM目录已重命名为 $(NPM_GLOBAL_DIR)$(BACKUP_SUFFIX)$(NC)"; \
	fi
	@if [ -f $(BASHRC_FILE) ]; then \
		mv $(BASHRC_FILE) $(BASHRC_FILE)$(BACKUP_SUFFIX); \
		echo "$(GREEN)原bashrc已重命名为 $(BASHRC_FILE)$(BACKUP_SUFFIX)$(NC)"; \
	fi
	
	@echo "$(GREEN)✅ 卸载完成。容器已删除，数据已备份$(NC)"
	@echo "如需彻底删除所有数据，请手动删除备份目录。"

# 🚀 服务生命周期管理

## start: 启动服务
start:
	@echo "$(GREEN)▶ 启动 OpenClaw 服务...$(NC)"
	@$(DOCKER_COMPOSE) up -d
	@$(DOCKER_COMPOSE) ps

## stop: 停止服务
stop:
	@echo "$(YELLOW)▶ 停止 OpenClaw 服务...$(NC)"
	@$(DOCKER_COMPOSE) stop
	@echo "$(GREEN)✅ 服务已停止$(NC)"

## restart: 重启服务
restart:
	@echo "$(YELLOW)▶ 重启 OpenClaw 服务...$(NC)"
	@$(DOCKER_COMPOSE) restart
	@$(DOCKER_COMPOSE) ps

## status: 查看服务状态
status:
	@$(DOCKER_COMPOSE) ps

## logs: 查看实时日志
logs:
	@$(DOCKER_COMPOSE) logs -f

# 🔄 数据与配置

## backup: 备份所有数据 (data + .npm-global + .bashrc)
backup:
	@echo "$(GREEN)▶ 创建完整数据备份...$(NC)"
	@mkdir -p ./backup
	@BACKUP_FILE="./backup/openclaw-full-$$(date +%Y%m%d-%H%M%S).tar.gz"; \
	BACKUP_ITEMS=""; \
	BACKUP_DESC=""; \
	if [ -d $(DATA_DIR) ] && [ "$$(ls -A $(DATA_DIR) 2>/dev/null)" ]; then \
		BACKUP_ITEMS="$$BACKUP_ITEMS $(DATA_DIR)"; \
		BACKUP_DESC="$$BACKUP_DESC data"; \
	fi; \
	if [ -d $(NPM_GLOBAL_DIR) ] && [ "$$(ls -A $(NPM_GLOBAL_DIR) 2>/dev/null)" ]; then \
		BACKUP_ITEMS="$$BACKUP_ITEMS $(NPM_GLOBAL_DIR)"; \
		BACKUP_DESC="$$BACKUP_DESC .npm-global"; \
	fi; \
	if [ -f $(BASHRC_FILE) ]; then \
		BACKUP_ITEMS="$$BACKUP_ITEMS $(BASHRC_FILE)"; \
		BACKUP_DESC="$$BACKUP_DESC .bashrc"; \
	fi; \
	if [ -n "$$BACKUP_ITEMS" ]; then \
		tar -czf $$BACKUP_FILE $$BACKUP_ITEMS 2>/dev/null; \
		BACKUP_SIZE=$$(ls -lh $$BACKUP_FILE | awk '{print $$5}'); \
		echo "$(GREEN)✅ 备份已创建: $$BACKUP_FILE ($(BLUE)$$BACKUP_SIZE$(GREEN))$(NC)"; \
		echo "$(BLUE)   包含项目:$$BACKUP_DESC$(NC)"; \
	else \
		echo "$(YELLOW)⚠️  没有找到可备份的数据，跳过备份$(NC)"; \
		rm -f $$BACKUP_FILE 2>/dev/null; \
	fi

## backup-info: 查看备份文件详情
backup-info:
	@echo "$(GREEN)▶ 备份文件详情:$(NC)"
	@echo ""
	@if [ -d ./backup ] && [ "$$(ls -A ./backup 2>/dev/null)" ]; then \
		echo "$(BLUE)备份文件列表:$(NC)"; \
		ls -lh ./backup/*.tar.gz 2>/dev/null | awk '{printf "  %s  %s  %s\n", $$9, $$5, $$6" "$$7};' || echo "  (无备份文件)"; \
		echo ""; \
		TOTAL_SIZE=$$(du -sh ./backup 2>/dev/null | cut -f1); \
		BACKUP_COUNT=$$(ls -1 ./backup/*.tar.gz 2>/dev/null | wc -l); \
		echo "$(BLUE)统计:$(NC)"; \
		echo "  备份文件数量: $$BACKUP_COUNT"; \
		echo "  总大小: $$TOTAL_SIZE"; \
	else \
		echo "$(YELLOW)⚠️  backup 目录为空或不存在$(NC)"; \
	fi

## restore-list: 列出所有可用的备份文件
restore-list:
	@echo "$(GREEN)▶ 可用的备份文件:$(NC)"
	@if [ -d ./backup ] && [ "$$(ls -A ./backup/*.tar.gz 2>/dev/null)" ]; then \
		echo ""; \
		echo "$(BLUE)序号  文件名                                      大小      日期$(NC)"; \
		echo "───────────────────────────────────────────────────────────────────"; \
		ls -1t ./backup/*.tar.gz 2>/dev/null | nl -w3 -s') ' | while read line; do \
			file=$$(echo $$line | awk '{print $$2}'); \
			size=$$(ls -lh $$file | awk '{print $$5}'); \
			date=$$(ls -l $$file | awk '{print $$6" "$$7}'); \
			name=$$(basename $$file); \
			printf "%s  %-42s  %-8s  %s\n" "$$(echo $$line | awk '{print $$1}')" "$$name" "$$size" "$$date"; \
		done; \
		echo ""; \
		echo "$(BLUE)使用 'make restore' 进行交互式恢复$(NC)"; \
	else \
		echo "$(YELLOW)⚠️  没有找到备份文件$(NC)"; \
	fi

## restore: 从备份恢复 (交互式选择)
restore:
	@echo "$(GREEN)▶ 可用的备份文件:$(NC)"
	@ls -1t ./backup/*.tar.gz 2>/dev/null || { echo "$(YELLOW)没有找到备份文件$(NC)"; exit 1; }
	@echo ""
	@read -p "请输入要恢复的备份文件名 (不含路径): " filename; \
	if [ ! -f "./backup/$$filename" ]; then \
		echo "$(RED)❌ 文件不存在: ./backup/$$filename$(NC)"; exit 1; \
	fi; \
	echo ""; \
	echo "$(YELLOW)⚠️  警告: 恢复将覆盖当前数据！$(NC)"; \
	read -p "确认要恢复吗？: "; \
	if [ "$$REPLY" != "y" ] && [ "$$REPLY" != "Y" ]; then \
		echo "$(GREEN)恢复已取消$(NC)"; exit 0; \
	fi; \
	echo ""; \
	echo "$(YELLOW)▶ 正在停止服务...$(NC)"; \
	$(MAKE) stop; \
	echo "$(YELLOW)▶ 备份当前数据 (以防万一)...$(NC)"; \
	if [ -d $(DATA_DIR) ]; then \
		mv $(DATA_DIR) $(DATA_DIR).pre-restore-$$(date +%Y%m%d-%H%M%S); \
	fi; \
	if [ -d $(NPM_GLOBAL_DIR) ]; then \
		mv $(NPM_GLOBAL_DIR) $(NPM_GLOBAL_DIR).pre-restore-$$(date +%Y%m%d-%H%M%S); \
	fi; \
	if [ -f $(BASHRC_FILE) ]; then \
		mv $(BASHRC_FILE) $(BASHRC_FILE).pre-restore-$$(date +%Y%m%d-%H%M%S); \
	fi; \
	mkdir -p $(DATA_DIR); \
	echo "$(YELLOW)▶ 解压备份文件...$(NC)"; \
	tar -xzf "./backup/$$filename"; \
	echo "$(GREEN)✅ 数据恢复完成$(NC)"; \
	echo ""; \
	$(MAKE) start; \
	echo ""; \
	echo "$(GREEN)✅ 恢复完成！服务已重启$(NC)"

# 💬 交互操作

## tui: 进入 TUI 对话模式
tui:
	@echo "$(GREEN)▶ 进入 TUI 对话模式 (输入 exit 退出)...$(NC)"
	@$(DOCKER_COMPOSE) exec $(SERVICE_NAME) openclaw tui

## shell: 进入容器 Shell
shell:
	@echo "$(GREEN)▶ 进入容器 Shell (输入 exit 退出)...$(NC)"
	@$(DOCKER_COMPOSE) exec $(SERVICE_NAME) /bin/bash

## config: 运行配置向导
config:
	@echo "$(GREEN)▶ 启动配置向导...$(NC)"
	@$(DOCKER_COMPOSE) exec $(SERVICE_NAME) openclaw onboard

## exec: 执行自定义命令 (用法: make exec 'openclaw --version')
exec:
	@if [ -z "$(cmd)" ]; then \
		echo "$(RED)❌ 请指定要执行的命令，例如: make exec 'openclaw --version'$(NC)"; \
		exit 1; \
	fi
	@$(DOCKER_COMPOSE) exec $(SERVICE_NAME) $(cmd)

# 🧹 维护工具

## ps: 查看容器进程
ps:
	@$(DOCKER_COMPOSE) ps

## update: 更新镜像 (需先手动修改 docker-compose.yml 中的版本标签)
update:
	@echo "$(YELLOW)▶ 拉取最新镜像...$(NC)"
	@$(DOCKER_COMPOSE) pull
	@echo "$(YELLOW)▶ 重新创建容器...$(NC)"
	@$(DOCKER_COMPOSE) up -d --force-recreate
	@$(DOCKER_COMPOSE) ps

## clean: 清理无用资源
clean:
	@echo "$(YELLOW)▶ 清理停止的容器...$(NC)"
	@docker container prune -f
	@echo "$(YELLOW)▶ 清理无用的镜像...$(NC)"
	@docker image prune -f
	@echo "$(GREEN)✅ 清理完成$(NC)"

# 内部辅助函数
check-dir:
	@mkdir -p $(DATA_DIR)
	@chmod 755 $(DATA_DIR)
	@mkdir -p $(NPM_GLOBAL_DIR)
	@chmod 755 $(NPM_GLOBAL_DIR)
	@if [ ! -f $(BASHRC_FILE) ]; then \
		touch $(BASHRC_FILE); \
	fi