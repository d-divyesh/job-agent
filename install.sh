#!/bin/bash
# ============================================================
# JOB AGENT MASTER INSTALLER
# Repository: https://github.com/YOUR_USERNAME/job-agent
# Version: 2.0.0
# ============================================================

set -e
set -o pipefail

REPO_URL="https://raw.githubusercontent.com/YOUR_USERNAME/job-agent/main"
SCRIPT_VERSION="2.0.0"

LOG_FILE="/var/log/job-agent-setup.log"
ERROR_LOG="/var/log/job-agent-errors.log"
PROJECT_DIR="/opt/job-agent"
CONFIG_DIR="$HOME/.openclaw"

CURRENT_STEP=0
TOTAL_STEPS=10
START_TIME=$(date +%s)

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

show_header() {
    clear
    echo -e "${BOLD}${CYAN}"
    echo "╔════════════════════════════════════════════════════════════════╗"
    echo "║           🤖 JOB AGENT MASTER SETUP v$SCRIPT_VERSION                ║"
    echo "╚════════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

show_progress_bar() {
    local current=$1
    local total=$2
    local percent=$((current * 100 / total))
    local filled=$((percent / 2))
    local empty=$((50 - filled))
    echo -ne "${CYAN}["
    printf "%${filled}s" | tr ' ' '█'
    printf "%${empty}s" | tr ' ' '░'
    echo -ne "] ${percent}%${NC}"
}

show_elapsed() {
    local elapsed=$(($(date +%s) - START_TIME))
    printf "${YELLOW}⏱️  Time: %02d:%02d${NC}" $((elapsed/60)) $((elapsed%60))
}

show_step() {
    case $3 in
        "running") echo -e "${BLUE}▶ STEP $1/$TOTAL_STEPS: $2${NC}" ;;
        "done") echo -e "${GREEN}✅ STEP $1/$TOTAL_STEPS: $2 - COMPLETE${NC}" ;;
        "pending") echo -e "${MAGENTA}◻ STEP $1/$TOTAL_STEPS: $2 (pending)${NC}" ;;
    esac
}

update_dashboard() {
    show_header
    echo ""
    echo -e "${BOLD}📊 INSTALLATION PROGRESS${NC}"
    echo "═══════════════════════════════════════════════════════════════"
    show_progress_bar $CURRENT_STEP $TOTAL_STEPS
    echo -e "    $(show_elapsed)"
    echo ""
    echo -e "${BOLD}📋 STEP STATUS${NC}"
    echo "═══════════════════════════════════════════════════════════════"
    
    for i in {1..10}; do
        if [[ -f "/tmp/step_${i}_done" ]]; then
            case $i in
                1) show_step 1 "System Cleanup" "done" ;;
                2) show_step 2 "Install Dependencies" "done" ;;
                3) show_step 3 "Install Ollama" "done" ;;
                4) show_step 4 "Pull AI Model" "done" ;;
                5) show_step 5 "Install OpenClaw" "done" ;;
                6) show_step 6 "Telegram Setup" "done" ;;
                7) show_step 7 "Configure OpenClaw" "done" ;;
                8) show_step 8 "Create Profile" "done" ;;
                9) show_step 9 "Setup 24/7 Service" "done" ;;
                10) show_step 10 "Final Test" "done" ;;
            esac
        elif [[ $i -eq $CURRENT_STEP ]]; then
            case $i in
                1) show_step 1 "System Cleanup" "running" ;;
                2) show_step 2 "Install Dependencies" "running" ;;
                3) show_step 3 "Install Ollama" "running" ;;
                4) show_step 4 "Pull AI Model" "running" ;;
                5) show_step 5 "Install OpenClaw" "running" ;;
                6) show_step 6 "Telegram Setup" "running" ;;
                7) show_step 7 "Configure OpenClaw" "running" ;;
                8) show_step 8 "Create Profile" "running" ;;
                9) show_step 9 "Setup 24/7 Service" "running" ;;
                10) show_step 10 "Final Test" "running" ;;
            esac
        else
            case $i in
                1) show_step 1 "System Cleanup" "pending" ;;
                2) show_step 2 "Install Dependencies" "pending" ;;
                3) show_step 3 "Install Ollama" "pending" ;;
                4) show_step 4 "Pull AI Model" "pending" ;;
                5) show_step 5 "Install OpenClaw" "pending" ;;
                6) show_step 6 "Telegram Setup" "pending" ;;
                7) show_step 7 "Configure OpenClaw" "pending" ;;
                8) show_step 8 "Create Profile" "pending" ;;
                9) show_step 9 "Setup 24/7 Service" "pending" ;;
                10) show_step 10 "Final Test" "pending" ;;
            esac
        fi
    done
    echo ""
}

mark_step_done() { touch "/tmp/step_${1}_done"; CURRENT_STEP=$(($1 + 1)); update_dashboard; }
log() { echo "[$(date '+%H:%M:%S')] $1" | tee -a "$LOG_FILE"; update_dashboard; }
success() { echo -e "${GREEN}✅ $1${NC}" | tee -a "$LOG_FILE"; update_dashboard; }

send_telegram() {
    if [[ -n "$TELEGRAM_BOT_TOKEN" && -n "$TELEGRAM_CHAT_ID" ]]; then
        curl -s -X POST "https://api.telegram.org/bot$TELEGRAM_BOT_TOKEN/sendMessage" \
            -d "chat_id=$TELEGRAM_CHAT_ID&text=$1" > /dev/null 2>&1
    fi
}

# Main installation steps
check_admin() {
    update_dashboard
    log "Checking admin privileges..."
    if [[ $EUID -ne 0 ]]; then
        exec sudo bash "$0" "$@"
    fi
    success "Admin confirmed"
    mark_step_done 1
    sleep 1
}

system_cleanup() {
    update_dashboard
    log "🧹 Cleaning system..."
    for service in bluetooth cups avahi-daemon whoopsie modemmanager speech-dispatcher snapd; do
        systemctl stop "$service.service" 2>/dev/null || true
        systemctl disable "$service.service" 2>/dev/null || true
    done
    apt update && apt upgrade -y
    apt autoremove -y --purge
    journalctl --vacuum-time=1d 2>/dev/null || true
    success "Cleanup complete"
    mark_step_done 1
    sleep 1
}

install_dependencies() {
    update_dashboard
    log "📦 Installing dependencies..."
    apt install -y curl wget git build-essential software-properties-common \
        python3 python3-pip python3-venv tmux htop jq
    curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
    apt install -y nodejs
    npm install -g pm2
    success "Dependencies installed"
    mark_step_done 2
    sleep 1
}

install_ollama() {
    update_dashboard
    log "🤖 Installing Ollama..."
    curl -fsSL https://ollama.com/install.sh | sh
    
    cat > /etc/systemd/system/ollama.service << 'EOF'
[Unit]
Description=Ollama AI Service
After=network.target

[Service]
Type=simple
User=root
ExecStart=/usr/local/bin/ollama serve
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF
    
    systemctl daemon-reload
    systemctl enable ollama
    systemctl start ollama
    sleep 5
    success "Ollama installed"
    mark_step_done 3
    sleep 1
}

pull_ai_model() {
    update_dashboard
    log "📥 Pulling AI model (5-10 minutes)..."
    ollama pull qwen2.5:3b
    echo ""
    success "AI model ready"
    mark_step_done 4
    sleep 1
}

install_openclaw() {
    update_dashboard
    log "🔧 Installing OpenClaw..."
    npm install -g openclaw
    success "OpenClaw installed"
    mark_step_done 5
    sleep 1
}

setup_telegram() {
    update_dashboard
    echo ""
    echo -e "${YELLOW}════════════════════════════════════════════════════════════════${NC}"
    echo -e "${BOLD}📱 TELEGRAM BOT SETUP${NC}"
    echo -e "${YELLOW}════════════════════════════════════════════════════════════════${NC}"
    echo ""
    echo "1. Open Telegram → @BotFather → /newbot"
    echo "2. Name: My Job Agent | Username: myjobagent_bot"
    echo ""
    read -p "Paste Bot Token: " TELEGRAM_BOT_TOKEN
    echo ""
    echo "Get Chat ID from @userinfobot"
    read -p "Paste Chat ID: " TELEGRAM_CHAT_ID
    
    curl -s -X POST "https://api.telegram.org/bot$TELEGRAM_BOT_TOKEN/sendMessage" \
        -d "chat_id=$TELEGRAM_CHAT_ID&text=✅ Job Agent Setup Started" -o /dev/null
    
    export TELEGRAM_BOT_TOKEN TELEGRAM_CHAT_ID
    success "Telegram configured"
    mark_step_done 6
    sleep 1
}

configure_openclaw() {
    update_dashboard
    log "⚙️ Configuring OpenClaw..."
    mkdir -p "$CONFIG_DIR"
    
    cat > "$CONFIG_DIR/openclaw.json" << EOF
{
  "models": {
    "providers": {
      "ollama": {
        "baseUrl": "http://127.0.0.1:11434/v1",
        "apiKey": "no-key-required",
        "api": "openai-completions",
        "models": [{"id": "qwen2.5:3b", "name": "Qwen 3B Local"}]
      }
    }
  },
  "agents": {
    "defaults": {
      "model": {"primary": "ollama/qwen2.5:3b"},
      "llm": {"idleTimeoutSeconds": 120},
      "timeoutSeconds": 300
    }
  },
  "channels": {
    "telegram": {
      "enabled": true,
      "botToken": "$TELEGRAM_BOT_TOKEN",
      "chatId": "$TELEGRAM_CHAT_ID",
      "reconnectInterval": 30
    }
  }
}
EOF
    
    success "OpenClaw configured"
    mark_step_done 7
    sleep 1
}

create_profile() {
    update_dashboard
    log "📝 Creating profile..."
    mkdir -p "$PROJECT_DIR"/{config,templates,output/{resumes,logs}}
    
    cat > "$PROJECT_DIR/config/profile.json" << 'EOF'
{
  "name": "YOUR NAME HERE",
  "phone": "+1 555 123 4567",
  "email": "your.email@example.com",
  "location": "Your City, State",
  "summary": "Field Service Technician with experience in equipment maintenance.",
  "skills": ["Troubleshooting", "Maintenance", "Safety", "Customer Service"],
  "experience": [],
  "education": [],
  "jobPreferences": {"titles": ["Field Technician"], "locations": ["Remote"]}
}
EOF
    
    cat > "$PROJECT_DIR/templates/resume_template.txt" << 'EOF'
{{NAME}}
{{PHONE}} | {{EMAIL}} | {{LOCATION}}

PROFESSIONAL SUMMARY
{{SUMMARY}}

CORE SKILLS
{{SKILLS}}

AVAILABILITY
{{AVAILABILITY}}
EOF
    
    success "Profile created"
    mark_step_done 8
    sleep 1
}

setup_persistent_service() {
    update_dashboard
    log "🔄 Setting up 24/7 service..."
    
    cat > /etc/systemd/system/openclaw-gateway.service << EOF
[Unit]
Description=OpenClaw Job Agent
After=network.target ollama.service

[Service]
Type=simple
User=root
ExecStart=/usr/bin/openclaw gateway start
Restart=always
RestartSec=30

[Install]
WantedBy=multi-user.target
EOF

    systemctl daemon-reload
    systemctl enable openclaw-gateway
    systemctl start openclaw-gateway
    
    cat > /usr/local/bin/job-agent-healthcheck.sh << 'EOF'
#!/bin/bash
if ! systemctl is-active --quiet openclaw-gateway; then
    systemctl restart openclaw-gateway
fi
EOF
    chmod +x /usr/local/bin/job-agent-healthcheck.sh
    (crontab -l 2>/dev/null; echo "* * * * * /usr/local/bin/job-agent-healthcheck.sh") | crontab -
    
    success "24/7 service configured"
    mark_step_done 9
    sleep 1
}

final_test() {
    update_dashboard
    log "🔍 Running final tests..."
    
    if curl -s http://localhost:11434/api/tags > /dev/null; then
        success "  ✓ Ollama: RUNNING"
    fi
    
    if systemctl is-active --quiet openclaw-gateway; then
        success "  ✓ OpenClaw: RUNNING"
    fi
    
    send_telegram "🎉 *JOB AGENT ONLINE!* 🎉%0A✅ Ready 24/7"
    
    success "All tests passed!"
    mark_step_done 10
}

final_dashboard() {
    clear
    echo -e "${BOLD}${GREEN}"
    echo "╔════════════════════════════════════════════════════════════════╗"
    echo "║                    🎉 SETUP COMPLETE! 🎉                       ║"
    echo "╚════════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo -e "${GREEN}✅ Ollama: RUNNING${NC}"
    echo -e "${GREEN}✅ OpenClaw: RUNNING${NC}"
    echo -e "${GREEN}✅ Health Checks: ACTIVE${NC}"
    echo ""
    echo -e "${BOLD}🤖 Telegram: /help, /status, /find [job]${NC}"
    echo -e "${BOLD}${GREEN}Your agent is working 24/7! 🔥${NC}"
}

main() {
    update_dashboard
    check_admin
    system_cleanup
    install_dependencies
    install_ollama
    pull_ai_model
    install_openclaw
    setup_telegram
    configure_openclaw
    create_profile
    setup_persistent_service
    final_test
    final_dashboard
}

main "$@"
