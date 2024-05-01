#!/bin/bash

# 检查是否以root用户运行脚本
if [ "$(id -u)" != "0" ]; then
    echo "此脚本需要以root用户权限运行。"
    echo "请尝试使用 'sudo -i' 命令切换到root用户，然后再次运行此脚本。"
    exit 1
fi

# 脚本保存路径
SCRIPT_PATH="$HOME/Taiko.sh"


# 自动设置快捷键的功能
function check_and_set_alias() {
    local alias_name="taiko"
    local shell_rc="$HOME/.bashrc"

    # 对于Zsh用户，使用.zshrc
    if [ -n "$ZSH_VERSION" ]; then
        shell_rc="$HOME/.zshrc"
    elif [ -n "$BASH_VERSION" ]; then
        shell_rc="$HOME/.bashrc"
    fi

    # 检查快捷键是否已经设置
    if ! grep -q "$alias_name" "$shell_rc"; then
        echo "设置快捷键 '$alias_name' 到 $shell_rc"
        echo "alias $alias_name='bash $SCRIPT_PATH'" >> "$shell_rc"
        # 添加提醒用户激活快捷键的信息
        echo "快捷键 '$alias_name' 已设置。请运行 'source $shell_rc' 来激活快捷键，或重新打开终端。"
    else
        # 如果快捷键已经设置，提供一个提示信息
        echo "快捷键 '$alias_name' 已经设置在 $shell_rc。"
        echo "如果快捷键不起作用，请尝试运行 'source $shell_rc' 或重新打开终端。"
    fi
}

# 节点安装功能
function install_node() {

# 更新系统包列表
sudo apt update

# 检查 Git 是否已安装
if ! command -v git &> /dev/null
then
    # 如果 Git 未安装，则进行安装
    echo "未检测到 Git，正在安装..."
    sudo apt install git -y
else
    # 如果 Git 已安装，则不做任何操作
    echo "Git 已安装。"
fi

# 克隆 Taiko 仓库
git clone https://github.com/taikoxyz/simple-taiko-node.git

# 进入 Taiko 目录
cd simple-taiko-node

# 如果不存在.env文件，则从示例创建一个
if [ ! -f .env ]; then
  cp .env.sample .env
fi

# 提示用户输入环境变量的值


read -p "请输入EVM钱包私钥,不需要带0x: " l1_proposer_private_key

read -p "请输入EVM钱包地址: " l2_suggested_fee_recipient

# 检测并罗列未被占用的端口
function list_recommended_ports {
    local start_port=8000 # 可以根据需要调整起始搜索端口
    local needed_ports=7
    local count=0
    local ports=()

    while [ "$count" -lt "$needed_ports" ]; do
        if ! ss -tuln | grep -q ":$start_port " ; then
            ports+=($start_port)
            ((count++))
        fi
        ((start_port++))
    done

    echo "推荐的端口如下："
    for port in "${ports[@]}"; do
        echo -e "\033[0;32m$port\033[0m"
    done
}

# 使用推荐端口函数为端口配置
list_recommended_ports

# 提示用户输入端口配置，允许使用默认值


# 将用户输入的值写入.env文件
sed -i "s|L1_ENDPOINT_HTTP=.*|L1_ENDPOINT_HTTP=http://188.40.51.249:8545|" .env
sed -i "s|L1_ENDPOINT_WS=.*|L1_ENDPOINT_WS=ws://188.40.51.249:8546|" .env
sed -i "s|L1_BEACON_HTTP=.*|L1_BEACON_HTTP=https://burned-twilight-log.ethereum-holesky.quiknode.pro|" .env
sed -i "s|ENABLE_PROPOSER=.*|ENABLE_PROPOSER=true|" .env
sed -i "s|L1_PROPOSER_PRIVATE_KEY=.*|L1_PROPOSER_PRIVATE_KEY=${l1_proposer_private_key}|" .env
sed -i "s|L2_SUGGESTED_FEE_RECIPIENT=.*|L2_SUGGESTED_FEE_RECIPIENT=${l2_suggested_fee_recipient}|" .env
sed -i "s|PROVER_ENDPOINTS=.*|PROVER_ENDPOINTS=http://kenz-prover.hekla.kzvn.xyz:9876|" .env


# 更新.env文件中的端口配置
sed -i "s|PORT_L2_EXECUTION_ENGINE_HTTP=.*|PORT_L2_EXECUTION_ENGINE_HTTP=8000|" .env
sed -i "s|PORT_L2_EXECUTION_ENGINE_WS=.*|PORT_L2_EXECUTION_ENGINE_WS=8001|" .env
sed -i "s|PORT_L2_EXECUTION_ENGINE_METRICS=.*|PORT_L2_EXECUTION_ENGINE_METRICS=8002|" .env
sed -i "s|PORT_L2_EXECUTION_ENGINE_P2P=.*|PORT_L2_EXECUTION_ENGINE_P2P=8003|" .env
sed -i "s|PORT_PROVER_SERVER=.*|PORT_PROVER_SERVER=8004|" .env
sed -i "s|PORT_PROMETHEUS=.*|PORT_PROMETHEUS=8005|" .env
sed -i "s|PORT_GRAFANA=.*|PORT_GRAFANA=8006|" .env
sed -i "s|BLOCK_PROPOSAL_FEE=.*|BLOCK_PROPOSAL_FEE=30|" .env

# 用户信息已配置完毕
echo "用户信息已配置完毕。"

# 升级所有已安装的包
sudo apt upgrade -y

# 安装基本组件
sudo apt install pkg-config curl build-essential libssl-dev libclang-dev ufw docker-compose-plugin -y

# 检查 Docker 是否已安装
if ! command -v docker &> /dev/null
then
    # 如果 Docker 未安装，则进行安装
    echo "未检测到 Docker，正在安装..."
    sudo apt-get install ca-certificates curl gnupg lsb-release

    # 添加 Docker 官方 GPG 密钥
    sudo mkdir -p /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

    # 设置 Docker 仓库
    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
      $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

    # 授权 Docker 文件
    sudo chmod a+r /etc/apt/keyrings/docker.gpg
    sudo apt-get update

    # 安装 Docker 最新版本
    sudo apt-get install docker-ce docker-ce-cli containerd.io docker-compose-plugin -y
else
    echo "Docker 已安装。"
fi

    # 安装 Docker compose 最新版本
DOCKER_CONFIG=${DOCKER_CONFIG:-$HOME/.docker}
mkdir -p $DOCKER_CONFIG/cli-plugins
curl -SL https://github.com/docker/compose/releases/download/v2.5.0/docker-compose-linux-x86_64 -o $DOCKER_CONFIG/cli-plugins/docker-compose
chmod +x $DOCKER_CONFIG/cli-plugins/docker-compose
docker compose version

# 验证 Docker Engine 安装是否成功
sudo docker run hello-world
# 应该能看到 hello-world 程序的输出

# 运行 Taiko 节点
docker compose --profile l2_execution_engine down
docker stop simple-taiko-node-taiko_client_proposer-1 && docker rm simple-taiko-node-taiko_client_proposer-1
docker compose --profile l2_execution_engine up -d
docker compose --profile proposer up -d

# 获取公网 IP 地址
public_ip=$(curl -s ifconfig.me)

# 准备原始链接
original_url="LocalHost:8006/d/L2ExecutionEngine/l2-execution-engine-overview?orgId=1&refresh=10s"

# 替换 LocalHost 为公网 IP 地址
updated_url=$(echo $original_url | sed "s/LocalHost/$public_ip/")

# 显示更新后的链接
echo "请通过以下链接查询设备运行情况，如果无法访问，请等待2-3分钟后重试：$updated_url"

}

# 查看节点日志
function check_service_status() {
    cd #HOME
    cd simple-taiko-node
    docker compose logs -f --tail 20
}

# 更改常规配置
function change_option() {
cd #HOME
cd simple-taiko-node



read -p "请输入EVM钱包私钥: " l1_proposer_private_key

read -p "请输入EVM钱包地址: " l2_suggested_fee_recipient

# 将用户输入的值写入.env文件
sed -i "s|L1_ENDPOINT_HTTP=.*|L1_ENDPOINT_HTTP=http://188.40.51.249:8545|" .env
sed -i "s|L1_ENDPOINT_WS=.*|L1_ENDPOINT_WS=ws://188.40.51.249:8546|" .env
sed -i "s|L1_BEACON_HTTP=.*|L1_BEACON_HTTP=https://burned-twilight-log.ethereum-holesky.quiknode.pro|" .env
sed -i "s|ENABLE_PROPOSER=.*|ENABLE_PROPOSER=true|" .env
sed -i "s|L1_PROPOSER_PRIVATE_KEY=.*|L1_PROPOSER_PRIVATE_KEY=${l1_proposer_private_key}|" .env
sed -i "s|L2_SUGGESTED_FEE_RECIPIENT=.*|L2_SUGGESTED_FEE_RECIPIENT=${l2_suggested_fee_recipient}|" .env
sed -i "s|DISABLE_P2P_SYNC=.*|DISABLE_P2P_SYNC=false|" .env
sed -i "s|PROVER_ENDPOINTS=.*|PROVER_ENDPOINTS=http://kenz-prover.hekla.kzvn.xyz:9876|" .env


docker compose --profile l2_execution_engine down
docker stop simple-taiko-node-taiko_client_proposer-1 && docker rm simple-taiko-node-taiko_client_proposer-1
docker compose --profile l2_execution_engine up -d
docker compose --profile proposer up -d

}

function change_prover() {
cd #HOME
cd simple-taiko-node


sed -i "s|PROVER_ENDPOINTS=.*|PROVER_ENDPOINTS=http://kenz-prover.hekla.kzvn.xyz:9876|" .env

docker compose --profile l2_execution_engine down
docker stop simple-taiko-node-taiko_client_proposer-1 && docker rm simple-taiko-node-taiko_client_proposer-1
docker compose --profile l2_execution_engine up -d
docker compose --profile proposer up -d

}

# 主菜单
function main_menu() {
    clear
    echo "Taiko节点"
    echo "请选择要执行的操作:"
    echo "1. 安装节点"
    echo "2. 查看节点日志"
    echo "3. 设置快捷键的功能"
    echo "4. 更改常规配置"
    echo "5. 更换rpc"
    read -p "请输入选项（1-3）: " OPTION

    case $OPTION in
    1) install_node ;;
    2) check_service_status ;;
    3) check_and_set_alias ;; 
    4) change_option ;; 
    5) change_prover ;; 
    *) echo "无效选项。" ;;
    esac
}

# 显示主菜单
main_menu
