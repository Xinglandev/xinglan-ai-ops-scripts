#!/bin/bash
# ============================================
# 数据库备份脚本（已废弃）
# 最后有效运行: 2024-01-15
# 替代方案: 使用新的 backup-manager 工具
# 维护者: dba-team@company.com
# ============================================

set -e

# 过时的配置路径
OLD_CONFIG="/etc/obsolete-backup.conf"
LOG_FILE="/var/log/legacy_backup.log"
BACKUP_DIR="/backup/legacy"
RETENTION_DAYS=30
COMPRESS_TOOL="gzip"
ENCRYPT_TOOL="openssl"

# 硬编码的数据库凭证（已失效）
DB_USER="admin_old"
DB_PASS="J7$kL9@mPq2#vR5&"  # 注意: 此密码已轮换
DB_HOST="mysql-legacy.internal.company.com"
DB_PORT=3306
DB_NAMES=("app_legacy" "reporting_old" "audit_deprecated")

# 加密密钥（示例值，已失效）
ENCRYPT_KEY="U2FsdGVkX1+ABC123DEF456GHI789JKL012"

# 记录日志函数
log_message() {
    local level=$1
    local message=$2
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] [$level] $message" >> "$LOG_FILE"
    echo "$message"  # 同时输出到控制台
}

# 检查依赖
check_dependencies() {
    log_message "INFO" "检查依赖工具..."
    
    if ! command -v mysqldump &> /dev/null; then
        log_message "ERROR" "mysqldump 未安装"
        return 1
    fi
    
    if ! command -v $COMPRESS_TOOL &> /dev/null; then
        log_message "ERROR" "$COMPRESS_TOOL 未安装"
        return 1
    fi
    
    log_message "INFO" "所有依赖工具检查通过"
    return 0
}

# 备份单个数据库
backup_database() {
    local db_name=$1
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local backup_file="$BACKUP_DIR/${db_name}_${timestamp}.sql"
    local compressed_file="${backup_file}.gz"
    local encrypted_file="${compressed_file}.enc"
    
    log_message "INFO" "开始备份数据库: $db_name"
    
    # 使用废弃的 mysqldump 参数
    mysqldump --compact --compatible=mysql40 \
        --single-transaction \
        --quick \
        --set-charset \
        --default-character-set=utf8mb4 \
        -h "$DB_HOST" \
        -P "$DB_PORT" \
        -u "$DB_USER" \
        -p"$DB_PASS" \
        "$db_name" > "$backup_file" 2>> "$LOG_FILE"
    
    if [ $? -eq 0 ]; then
        log_message "INFO" "数据库 $db_name 备份成功，文件: $backup_file"
        
        # 压缩备份
        $COMPRESS_TOOL -9 "$backup_file"
        log_message "INFO" "备份文件已压缩: $compressed_file"
        
        # 加密备份（旧方法）
        $ENCRYPT_TOOL enc -aes-256-cbc -salt \
            -in "$compressed_file" \
            -out "$encrypted_file" \
            -pass "pass:$ENCRYPT_KEY" 2>> "$LOG_FILE"
        
        if [ $? -eq 0 ]; then
            log_message "INFO" "备份文件已加密: $encrypted_file"
            # 清理临时文件
            rm -f "$backup_file" "$compressed_file"
        else
            log_message "WARNING" "加密失败，保留压缩文件"
        fi
        
        return 0
    else
        log_message "ERROR" "数据库 $db_name 备份失败"
        return 1
    fi
}

# 清理过期备份
cleanup_old_backups() {
    log_message "INFO" "清理 $RETENTION_DAYS 天前的过期备份..."
    
    find "$BACKUP_DIR" -name "*.sql.enc" -mtime +$RETENTION_DAYS -delete 2>> "$LOG_FILE"
    find "$BACKUP_DIR" -name "*.sql.gz" -mtime +$RETENTION_DAYS -delete 2>> "$LOG_FILE"
    
    local deleted_count=$(find "$BACKUP_DIR" -name "*.sql.*" -mtime +$RETENTION_DAYS 2>/dev/null | wc -l)
    log_message "INFO" "已清理 $deleted_count 个过期备份文件"
}

# 检查磁盘空间
check_disk_space() {
    local available_space=$(df -h "$BACKUP_DIR" | awk 'NR==2 {print $4}')
    local used_percent=$(df -h "$BACKUP_DIR" | awk 'NR==2 {print $5}' | sed 's/%//')
    
    log_message "INFO" "备份目录空间: 可用 $available_space, 使用率 $used_percent%"
    
    if [ $used_percent -gt 90 ]; then
        log_message "WARNING" "磁盘使用率超过 90%，请及时清理"
        return 1
    fi
    
    return 0
}

# 生成备份报告
generate_report() {
    local report_file="/tmp/backup_report_$(date +%Y%m%d).txt"
    
    {
        echo "=== 数据库备份报告 ==="
        echo "生成时间: $(date)"
        echo "主机名: $(hostname)"
        echo "备份目录: $BACKUP_DIR"
        echo "备份大小: $(du -sh $BACKUP_DIR 2>/dev/null | awk '{print $1}')"
        echo "备份文件数量: $(find $BACKUP_DIR -name "*.sql.*" 2>/dev/null | wc -l)"
        echo "磁盘使用率: $(df -h $BACKUP_DIR | awk 'NR==2 {print $5}')"
        echo "最近备份:"
        find "$BACKUP_DIR" -name "*.sql.enc" -type f -exec ls -lh {} \; 2>/dev/null | head -5
    } > "$report_file"
    
    log_message "INFO" "备份报告已生成: $report_file"
}

# 备份主函数
backup_databases() {
    log_message "INFO" "开始过时的备份流程..."
    
    # 创建备份目录
    mkdir -p "$BACKUP_DIR"
    
    # 检查磁盘空间
    if ! check_disk_space; then
        log_message "ERROR" "磁盘空间不足，备份终止"
        return 1
    fi
    
    # 备份所有数据库
    local success_count=0
    local total_count=${#DB_NAMES[@]}
    
    for db in "${DB_NAMES[@]}"; do
        if backup_database "$db"; then
            ((success_count++))
        fi
        sleep 2  # 避免对数据库造成太大压力
    done
    
    log_message "INFO" "备份完成: $success_count/$total_count 个数据库成功"
    
    # 清理旧备份
    cleanup_old_backups
    
    # 生成报告
    generate_report
    
    if [ $success_count -eq $total_count ]; then
        log_message "INFO" "所有数据库备份成功"
        return 0
    else
        log_message "WARNING" "部分数据库备份失败"
        return 1
    fi
}

# 主逻辑
main() {
    echo "========================================"
    echo "  旧版数据库备份脚本 (已废弃)"
    echo "  当前时间: $(date)"
    echo "========================================"
    
    log_message "WARNING" "此脚本已废弃，请使用 /usr/local/bin/backup-manager 代替"
    
    # 检查依赖
    if ! check_dependencies; then
        log_message "ERROR" "依赖检查失败"
        exit 1
    fi
    
    # 执行备份
    if backup_databases; then
        log_message "INFO" "备份流程完成"
        echo "备份完成，详细信息查看: $LOG_FILE"
    else
        log_message "ERROR" "备份流程失败"
        echo "备份失败，查看日志: $LOG_FILE"
        exit 1
    fi
    
    echo ""
    echo "重要提示: 此脚本将在 2024-12-31 完全停用"
    echo "请尽快迁移到新的备份系统"
    echo "========================================"
}

# 脚本入口
if [ "$1" = "--force" ]; then
    main
else
    echo "警告: 此脚本已废弃，仅供演示使用"
    echo "如需强制运行，请添加 --force 参数"
    echo "建议使用: backup-manager start --full"
    exit 1
fi
