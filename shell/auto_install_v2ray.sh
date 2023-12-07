#!/bin/bash
#*************脚本介绍**************************
#安装v2ray的自动脚本，可以自定义配置端口及UUID
# ***************************************



# 默认配置
DEFAULT_PORT=1080
DEFAULT_UUID=$(cat /proc/sys/kernel/random/uuid)

# 从命令行参数获取端口和UUID，如果没有提供则使用默认值
PORT=${1:-$DEFAULT_PORT}
UUID=${2:-$DEFAULT_UUID}

# 更新系统包
sudo yum update -y

# 安装curl
sudo yum install curl -y

# 使用官方安装脚本自动安装v2ray
#bash <(curl -L -s https://raw.githubusercontent.com/v2fly/fhs-install-v2ray/master/install-release.sh)
#先下载文件，在执行
wget https://raw.githubusercontent.com/v2fly/fhs-install-v2ray/master/install-release.sh
bash install-release.sh

# 配置v2ray

# v2ray配置文件路径
V2RAY_DIR="/etc/v2ray/${PORT}"
V2RAY_CONFIG="${V2RAY_DIR}/config.json"

#创建文件夹
mkdir -p /var/log/v2ray
mkdir -p ${V2RAY_DIR}
# 写入v2ray配置
cat <<EOF > ${V2RAY_CONFIG}
{
  "log" : {
    "access": "/var/log/v2ray/${PORT}access.log",
    "error": "/var/log/v2ray/${PORT}error.log",
    "loglevel": "warning"
  },
  "inbounds": [{
    "port": ${PORT}, 
    "listen":"127.0.0.1",
    "protocol": "vmess",
    "settings": {
      "clients": [
        {
          "id": "${UUID}",
          "level": 1,
          "alterId": 64
        }
      ]
    },
    "streamSettings": {
      "network": "ws", 
      "wsSettings": {
        "path": "/v2ray" 
      }
    }
  }],
  "outbounds": [{
    "protocol": "freedom",
    "settings": {}
  }]
}
EOF

#指定配置文件
# V2Ray systemd服务文件路径
V2RAY_SERVICE_FILE="/etc/systemd/system/v2ray.service"
# 使用sed命令修改ExecStart行
sudo sed -i "s|^ExecStart=.*|ExecStart=/usr/bin/v2ray -config ${V2RAY_CONFIG}|" $V2RAY_SERVICE_FILE


# 启动v2ray服务
sudo systemctl enable v2ray
sudo systemctl start v2ray

# 检查v2ray服务状态
sudo systemctl status v2ray -l --no-pager

# 输出配置信息
echo "v2ray已安装并配置完成"
echo "端口: ${PORT}"
echo "UUID: ${UUID}"
echo "alterId: 64"
echo "传输协议: websocket"
echo "路径: /v2ray"