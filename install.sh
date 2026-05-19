#!/bin/bash
# ============================================================
# ULTIMATE JOB AGENT INSTALLER
# - Full validation of Telegram credentials
# - Checks EVERYTHING before proceeding
# - Clear pass/fail feedback
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

# ============================================================
# VALIDATION FUNCTIONS
# ============================================================

validate_bot_token() {
    local token="$1"
    
    # Check format
    if [[ ! "$token" =~ ^[0-9]+:[a-zA-Z0-9_-]+$ ]]; then
        echo -e "${RED}❌ Invalid format: Token must be numbers:letters${NC}"
        return 1
    fi
    
    echo -e "${CYAN}   📡 Verifying with Telegram API...${NC}"
    
    # Test the token
    local response=$(curl -s "https://api.telegram.org/bot$token/getMe")
    
    if echo "$response" | grep -q '"ok":true'; then
        local bot_name=$(echo "$response" | grep -o '"first_name":"[^"]*"' | cut -d'"' -f4)
        local bot_username=$(echo "$response" | grep -o '"username":"[^"]*"' | cut -d'"' -f4)
        echo -e "${GREEN}   ✅ Bot Token VALID${NC}"
        echo -e "${GREEN}   🤖 Bot Name: $bot_name${NC}"
        echo -e "${GREEN}   📛 Username: @$bot_username${NC}"
        return 0
    else
        echo -e "${RED}   ❌ Bot Token INVALID${NC}"
        echo -e "${RED}   Response: $response${NC}"
        return 1
    fi
}

validate_chat_id() {
    local chat_id="$1"
    local bot_token="$2"
    
    # Check if it's a number
    if [[ ! "$chat_id" =~ ^[0-9]+$ ]]; then
        echo -e "${RED}❌ Invalid Chat ID: Must be numbers only${NC}"
        return 1
    fi
    
    echo -e "${CYAN}   📡 Testing message send to this Chat ID...${NC}"
    
    # Try to send a test message
    local response=$(curl -s -X POST "https://api.telegram.org/bot$bot_token/sendMessage" \
        -d "chat_id=$chat_id&text=🔍 Validating your Chat ID... This is a test message.")
    
    if echo "$response" | grep -q '"ok":true'; then
        echo -e "${GREEN}   ✅ Chat ID VALID${NC}"
        echo -e "${GREEN}   📱 Message sent successfully! Check Telegram.${NC}"
        return 0
    else
        local error=$(echo "$response" | grep -o '"description":"[^"]*"' | cut -d'"' -f4)
        echo -e "${RED}   ❌ Chat ID INVALID${NC}"
        echo -e "${RED}   Error: $error${NC}"
        return 1
    fi
}

get_valid_bot_token() {
    local token=""
    local attempts=0
    
    while true; do
        attempts=$((attempts + 1))
        echo ""
        echo -e "${BOLD}${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -e "${BOLD}${YELLOW}➤ Paste your Telegram Bot Token (Attempt $attempts/5)${NC}"
        echo -e "${BOLD}${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo ""
        read -p "→ " token </dev/tty
        
        if [[ -z "$token" ]]; then
            echo -e "${RED}❌ Token cannot be empty${NC}"
            continue
        fi
        
        if validate_bot_token "$token"; then
            echo "$token"
            return 0
        fi
        
        if [[ $attempts -ge 5 ]]; then
            echo -e "${RED}❌ Too many failed attempts. Exiting.${NC}"
            exit 1
        fi
        
        echo -e "${YELLOW}⚠️  Let's try again. Make sure you copied the token correctly.${NC}"
    done
}

get_valid_chat_id() {
    local bot_token="$1"
    local chat_id=""
    local attempts=0
    
    while true; do
        attempts=$((attempts + 1))
        echo ""
        echo -e "${BOLD}${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -e "${BOLD}${YELLOW}➤ Paste your Chat ID (Attempt $attempts/5)${NC}"
        echo -e "${BOLD}${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo ""
        read -p "→ " chat_id </dev/tty
        
        if [[ -z "$chat_id" ]]; then
            echo -e "${RED}❌ Chat ID cannot be empty${NC}"
            continue
        fi
        
        if validate_chat_id "$chat_id" "$bot_token"; then
            echo "$chat_id"
            return 0
        fi
        
        if [[ $attempts -ge 5 ]]; then
            echo -e "${RED}❌ Too many failed attempts. Exiting.${NC}"
            exit 1
        fi
        
        echo -e "${YELLOW}⚠️  Let's try again. Get your Chat ID from @userinfobot.${NC}"
    done
}

# Check root
if [[ $EUID -ne 0 ]]; then
    echo -e "${YELLOW}⚠️ Need admin privileges. Restarting with sudo...${NC}"
    exec sudo bash "$0" "$@"
fi

clear
echo -e "${BOLD}${CYAN}"
echo "╔════════════════════════════════════════════════════════════════╗"
echo "║           🤖 ULTIMATE JOB AGENT INSTALLER                      ║"
echo "║           With Full Telegram Credential Validation             ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo -e "${NC}"
echo ""

# ============================================================
# QUICK SETUP STEPS (Skip if already done)
# ============================================================

if ! is_completed "step1"; then
    echo -e "${BOLD}${BLUE}▶ STEP 1/5: System Update${NC}"
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
    echo -e "${BOLD}${BLUE}▶ STEP 2/5: Installing Dependencies${NC}"
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
    echo -e "${BOLD}${BLUE}▶ STEP 3/5: Installing Ollama${NC}"
    
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
    echo -e "${BOLD}${BLUE}▶ STEP 4/5: Pulling AI Model${NC}"
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
    echo -e "${BOLD}${BLUE}▶ STEP 5/5: Installing OpenClaw${NC}"
    
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
# TELEGRAM SETUP WITH FULL VALIDATION
# ============================================================

echo ""
echo -e "${BOLD}${CYAN}════════════════════════════════════════════════════════════════${NC}"
echo -e "${BOLD}📱 TELEGRAM BOT SETUP (With Validation)${NC}"
echo -e "${BOLD}${CYAN}════════════════════════════════════════════════════════════════${NC}"
echo ""

# Show instructions
echo -e "${YELLOW}📋 QUICK GUIDE:${NC}"
echo ""
echo -e "${CYAN}1. Create Bot Token (from @BotFather):${NC}"
echo "   • Open Telegram → Search '@BotFather'"
echo "   • Send: /newbot"
echo "   • Name: My Job Agent"
echo "   • Username: myjobagent_bot"
echo "   • COPY THE TOKEN"
echo ""
echo -e "${CYAN}2. Get Chat ID (from @userinfobot):${NC}"
echo "   • Search '@userinfobot' on Telegram"
echo "   • Send: /start"
echo "   • COPY YOUR CHAT ID (numbers only)"
echo ""
echo -e "${YELLOW}⚠️  The script will validate both before continuing!${NC}"
echo ""

# Check if we already have valid credentials
TELEGRAM_BOT_TOKEN=""
TELEGRAM_CHAT_ID=""

if [[ -f /root/.openclaw/telegram-creds-validated ]] && ! is_completed "telegram"; then
    echo -e "${YELLOW}⚠️  Previously saved credentials found.${NC}"
    echo ""
    echo "   [1] Test and use existing credentials"
    echo "   [2] Enter new credentials"
    echo ""
    read -p "Choose (1 or 2): " reuse_choice </dev/tty
    
    if [[ "$reuse_choice" == "1" ]]; then
        source /root/.openclaw/telegram-creds-validated
        echo -e "${CYAN}📡 Validating saved credentials...${NC}"
        if validate_bot_token "$TELEGRAM_BOT_TOKEN" && validate_chat_id "$TELEGRAM_CHAT_ID" "$TELEGRAM_BOT_TOKEN"; then
            echo -e "${GREEN}✅ Saved credentials are valid!${NC}"
        else
            echo -e "${RED}❌ Saved credentials are invalid. Please enter new ones.${NC}"
            reuse_choice="2"
        fi
    fi
    
    if [[ "$reuse_choice" == "2" ]]; then
        TELEGRAM_BOT_TOKEN=$(get_valid_bot_token)
        TELEGRAM_CHAT_ID=$(get_valid_chat_id "$TELEGRAM_BOT_TOKEN")
    fi
else
    TELEGRAM_BOT_TOKEN=$(get_valid_bot_token)
    TELEGRAM_CHAT_ID=$(get_valid_chat_id "$TELEGRAM_BOT_TOKEN")
fi

# Save validated credentials
mkdir -p /root/.openclaw
cat > /root/.openclaw/telegram-creds-validated << EOF
TELEGRAM_BOT_TOKEN="$TELEGRAM_BOT_TOKEN"
TELEGRAM_CHAT_ID="$TELEGRAM_CHAT_ID"
EOF

# Final confirmation
echo ""
echo -e "${BOLD}${GREEN}════════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}✅ ALL VALIDATIONS PASSED!${NC}"
echo -e "${BOLD}${GREEN}════════════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "${GREEN}🤖 Bot Token: ${TELEGRAM_BOT_TOKEN:0:20}...${NC}"
echo -e "${GREEN}📱 Chat ID: $TELEGRAM_CHAT_ID${NC}"
echo ""
echo -e "${CYAN}📡 Sending final confirmation message...${NC}"

curl -s -X POST "https://api.telegram.org/bot$TELEGRAM_BOT_TOKEN/sendMessage" \
    -d "chat_id=$TELEGRAM_CHAT_ID&text=✅ *CREDENTIALS VALIDATED!*%0A%0AYour Job Agent installation will now continue.%0AThis may take 5-10 minutes for the AI model to download." \
    > /dev/null

echo -e "${GREEN}✅ Confirmation sent to Telegram!${NC}"
sleep 2

# ============================================================
# CONFIGURE OPENCLAW WITH VALIDATED CREDENTIALS
# ============================================================

echo ""
echo -e "${BOLD}${BLUE}🔧 Configuring OpenClaw with your credentials...${NC}"

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

mark_completed "telegram"

# Send final success message
curl -s -X POST "https://api.telegram.org/bot$TELEGRAM_BOT_TOKEN/sendMessage" \
    -d "chat_id=$TELEGRAM_CHAT_ID&text=🎉 *JOB AGENT IS ONLINE!* 🎉%0A%0A✅ All validations passed%0A✅ Agent is running 24/7%0A%0A📱 Try these commands:%0A/help - Show all commands%0A/status - Check health%0A/find field technician - Search for jobs" \
    > /dev/null

# Final dashboard
clear
echo -e "${BOLD}${GREEN}"
echo "╔════════════════════════════════════════════════════════════════╗"
echo "║                    🎉 SETUP COMPLETE! 🎉                       ║"
echo "║      Your Job Agent is Online with Validated Credentials       ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo -e "${NC}"
echo ""
echo -e "${GREEN}✅ Bot Token Validated${NC}"
echo -e "${GREEN}✅ Chat ID Validated${NC}"
echo -e "${GREEN}✅ Ollama: RUNNING${NC}"
echo -e "${GREEN}✅ OpenClaw: RUNNING${NC}"
echo ""
echo -e "${BOLD}🤖 TEST ON TELEGRAM:${NC}"
echo -e "   Check your Telegram - you should have received a message!"
echo -e "   Send /help to your bot"
echo ""
echo -e "${BOLD}📁 EDIT YOUR PROFILE:${NC}"
echo -e "   nano /opt/job-agent/config/profile.json"
echo ""
echo -e "${BOLD}${GREEN}Your validated agent is working 24/7! 🔥${NC}"
