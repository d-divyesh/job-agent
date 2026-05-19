#!/bin/bash
# ============================================================
# FIXED SMART JOB AGENT INSTALLER
# - Properly waits for user input
# - Shows clear prompts
# - No automatic empty input
# ============================================================

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# Progress file
PROGRESS_FILE="/tmp/job-agent-progress"
STEPS_COMPLETED=""

if [[ -f "$PROGRESS_FILE" ]]; then
    STEPS_COMPLETED=$(cat "$PROGRESS_FILE")
    echo -e "${YELLOW}📋 Previous progress detected. Resuming...${NC}"
fi

mark_completed() {
    if [[ ! "$STEPS_COMPLETED" == *"$1"* ]]; then
        STEPS_COMPLETED="$STEPS_COMPLETED $1"
        echo "$STEPS_COMPLETED" > "$PROGRESS_FILE"
    fi
}

is_completed() {
    [[ "$STEPS_COMPLETED" == *"$1"* ]]
}

# FIXED: Proper input function that waits
get_input() {
    local prompt="$1"
    local var_name="$2"
    local input_value=""
    
    echo ""
    echo -e "${BOLD}${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BOLD}${YELLOW}➤ $prompt${NC}"
    echo -e "${BOLD}${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    
    # Use /dev/tty to ensure we're reading from the terminal
    while [[ -z "$input_value" ]]; do
        read -p "→ " input_value </dev/tty
        if [[ -z "$input_value" ]]; then
            echo -e "${RED}❌ Input cannot be empty. Please try again.${NC}"
        fi
    done
    
    eval "$var_name='$input_value'"
    echo -e "${GREEN}✓ Received: ${input_value:0:20}...${NC}"
}

# Check root
if [[ $EUID -ne 0 ]]; then
    echo -e "${YELLOW}⚠️ Need admin privileges. Restarting with sudo...${NC}"
    exec sudo bash "$0" "$@"
fi

clear
echo -e "${BOLD}${CYAN}"
echo "╔════════════════════════════════════════════════════════════════╗"
echo "║           🤖 FIXED SMART JOB AGENT INSTALLER                   ║"
echo "║           Properly waits for your input                        ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo -e "${NC}"
echo ""

# ============================================================
# STEP 1-5: Quick checks (skip if already done)
# ============================================================

if ! is_completed "step1"; then
    echo -e "${BOLD}${BLUE}▶ STEP 1/6: System Update${NC}"
    apt update -y
    apt upgrade -y -y
    mark_completed "step1"
    echo -e "${GREEN}✅ Step 1 completed${NC}"
    echo ""
else
    echo -e "${GREEN}✅ Step 1 already done - skipping${NC}"
    echo ""
fi

if ! is_completed "step2"; then
    echo -e "${BOLD}${BLUE}▶ STEP 2/6: Installing Dependencies${NC}"
    apt install -y curl wget git build-essential python3 python3-pip tmux htop jq
    
    if ! command -v node &> /dev/null; then
        curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
        apt install -y nodejs
    fi
    
    if ! command -v npm &> /dev/null; then
        apt install -y npm
    fi
    
    mark_completed "step2"
    echo -e "${GREEN}✅ Step 2 completed${NC}"
    echo ""
else
    echo -e "${GREEN}✅ Step 2 already done - skipping${NC}"
    echo ""
fi

if ! is_completed "step3"; then
    echo -e "${BOLD}${BLUE}▶ STEP 3/6: Installing Ollama${NC}"
    
    if ! command -v ollama &> /dev/null; then
        curl -fsSL https://ollama.com/install.sh | sh
    fi
    
    systemctl enable ollama 2>/dev/null || true
    systemctl start ollama
    
    mark_completed "step3"
    echo -e "${GREEN}✅ Step 3 completed${NC}"
    echo ""
else
    echo -e "${GREEN}✅ Step 3 already done - skipping${NC}"
    echo ""
fi

if ! is_completed "step4"; then
    echo -e "${BOLD}${BLUE}▶ STEP 4/6: Pulling AI Model${NC}"
    echo -e "${YELLOW}This takes 5-10 minutes...${NC}"
    
    if ! ollama list | grep -q "qwen2.5:3b"; then
        ollama pull qwen2.5:3b
    else
        echo -e "${GREEN}✓ Model already downloaded${NC}"
    fi
    
    mark_completed "step4"
    echo -e "${GREEN}✅ Step 4 completed${NC}"
    echo ""
else
    echo -e "${GREEN}✅ Step 4 already done - skipping${NC}"
    echo ""
fi

if ! is_completed "step5"; then
    echo -e "${BOLD}${BLUE}▶ STEP 5/6: Installing OpenClaw${NC}"
    
    if ! command -v openclaw &> /dev/null; then
        npm install -g openclaw
    fi
    
    mark_completed "step5"
    echo -e "${GREEN}✅ Step 5 completed${NC}"
    echo ""
else
    echo -e "${GREEN}✅ Step 5 already done - skipping${NC}"
    echo ""
fi

# ============================================================
# STEP 6: Telegram Setup (WAITS FOR INPUT)
# ============================================================

echo -e "${BOLD}${BLUE}▶ STEP 6/6: Telegram Bot Setup${NC}"
echo ""

# Show instructions
echo -e "${CYAN}════════════════════════════════════════════════════════════════${NC}"
echo -e "${BOLD}📱 QUICK GUIDE TO GET YOUR TELEGRAM CREDENTIALS:${NC}"
echo -e "${CYAN}════════════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "${YELLOW}1. Get Bot Token from @BotFather:${NC}"
echo "   • Open Telegram → Search '@BotFather'"
echo "   • Send: /newbot"
echo "   • Name: My Job Agent"
echo "   • Username: myjobagent_bot"
echo "   • Copy the token (looks like: 123456789:ABCdefGHIjklMNOpqrsTUVwxyz)"
echo ""
echo -e "${YELLOW}2. Get Chat ID from @userinfobot:${NC}"
echo "   • Search '@userinfobot' on Telegram"
echo "   • Send any message (like 'hi')"
echo "   • Copy your Chat ID (a number like: 123456789)"
echo ""
echo -e "${CYAN}════════════════════════════════════════════════════════════════${NC}"
echo ""

# Check if we already have credentials
if [[ -f /root/.openclaw/telegram-creds ]] && ! is_completed "step6"; then
    echo -e "${YELLOW}⚠️  Previous Telegram credentials found.${NC}"
    echo ""
    echo "   [1] Use existing credentials"
    echo "   [2] Enter new credentials"
    echo ""
    read -p "Choose (1 or 2): " reuse_choice </dev/tty
    
    if [[ "$reuse_choice" == "1" ]]; then
        source /root/.openclaw/telegram-creds
        echo -e "${GREEN}✓ Using existing credentials${NC}"
    else
        get_input "Paste your Telegram Bot Token" "TELEGRAM_BOT_TOKEN"
        get_input "Paste your Chat ID" "TELEGRAM_CHAT_ID"
    fi
else
    get_input "Paste your Telegram Bot Token (from @BotFather)" "TELEGRAM_BOT_TOKEN"
    get_input "Paste your Chat ID (from @userinfobot)" "TELEGRAM_CHAT_ID"
fi

# Save credentials
mkdir -p /root/.openclaw
cat > /root/.openclaw/telegram-creds << EOF
TELEGRAM_BOT_TOKEN="$TELEGRAM_BOT_TOKEN"
TELEGRAM_CHAT_ID="$TELEGRAM_CHAT_ID"
EOF

# Test connection
echo ""
echo -e "${CYAN}📡 Testing Telegram connection...${NC}"
TEST_RESULT=$(curl -s -X POST "https://api.telegram.org/bot$TELEGRAM_BOT_TOKEN/sendMessage" \
    -d "chat_id=$TELEGRAM_CHAT_ID&text=✅ Smart Job Agent is being installed!" \
    -o /dev/null -w "%{http_code}")

if [[ "$TEST_RESULT" == "200" ]]; then
    echo -e "${GREEN}✅ Telegram connection successful!${NC}"
else
    echo -e "${RED}❌ Telegram connection failed (HTTP $TEST_RESULT)${NC}"
    echo -e "${YELLOW}Please check your token and chat ID, then run the script again.${NC}"
    exit 1
fi

# Create OpenClaw config
mkdir -p /root/.openclaw
cat > /root/.openclaw/openclaw.json << EOF
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

# Create profile
mkdir -p /opt/job-agent/config
cat > /opt/job-agent/config/profile.json << 'EOF'
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

# Create systemd service
cat > /etc/systemd/system/openclaw-gateway.service << EOF
[Unit]
Description=OpenClaw Job Agent
After=network.target ollama.service

[Service]
Type=simple
User=root
WorkingDirectory=/opt/job-agent
ExecStart=/usr/bin/openclaw gateway start
Restart=always
RestartSec=30

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable openclaw-gateway
systemctl start openclaw-gateway

# Health check
cat > /usr/local/bin/job-agent-healthcheck.sh << 'EOF'
#!/bin/bash
if ! systemctl is-active --quiet openclaw-gateway; then
    systemctl restart openclaw-gateway
fi
EOF
chmod +x /usr/local/bin/job-agent-healthcheck.sh
(crontab -l 2>/dev/null | grep -v "job-agent-healthcheck"; echo "* * * * * /usr/local/bin/job-agent-healthcheck.sh") | crontab -

mark_completed "step6"

# Send success message
curl -s -X POST "https://api.telegram.org/bot$TELEGRAM_BOT_TOKEN/sendMessage" \
    -d "chat_id=$TELEGRAM_CHAT_ID&text=🎉 *JOB AGENT IS ONLINE!* 🎉%0A%0A✅ Ready 24/7%0A✅ Type /help to start" > /dev/null

# Final dashboard
clear
echo -e "${BOLD}${GREEN}"
echo "╔════════════════════════════════════════════════════════════════╗"
echo "║                    🎉 SETUP COMPLETE! 🎉                       ║"
echo "║           Your Job Agent is Now Operational                    ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo -e "${NC}"
echo ""
echo -e "${GREEN}✅ Ollama: RUNNING${NC}"
echo -e "${GREEN}✅ OpenClaw: RUNNING${NC}"
echo -e "${GREEN}✅ Telegram: CONNECTED${NC}"
echo ""
echo -e "${BOLD}🤖 TEST ON TELEGRAM:${NC}"
echo -e "   Send /help to your bot"
echo ""
echo -e "${BOLD}📁 EDIT YOUR PROFILE:${NC}"
echo -e "   nano /opt/job-agent/config/profile.json"
echo ""
echo -e "${BOLD}${GREEN}Your agent is working 24/7! 🔥${NC}"
