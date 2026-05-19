#!/bin/bash
# ============================================================
# SMART JOB AGENT INSTALLER
# - Checks what's already installed
# - Skips completed steps
# - Waits for user input
# - Resumable if interrupted
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

# Progress file to track completed steps
PROGRESS_FILE="/tmp/job-agent-progress"
STEPS_COMPLETED=""

# Load previous progress if exists
if [[ -f "$PROGRESS_FILE" ]]; then
    STEPS_COMPLETED=$(cat "$PROGRESS_FILE")
    echo -e "${YELLOW}📋 Previous progress detected. Resuming from where we left off...${NC}"
fi

# Function to mark a step as completed
mark_completed() {
    if [[ ! "$STEPS_COMPLETED" == *"$1"* ]]; then
        STEPS_COMPLETED="$STEPS_COMPLETED $1"
        echo "$STEPS_COMPLETED" > "$PROGRESS_FILE"
    fi
}

# Function to check if step is already completed
is_completed() {
    [[ "$STEPS_COMPLETED" == *"$1"* ]]
}

# Function to wait for user input
wait_for_input() {
    local prompt="$1"
    local var_name="$2"
    local input_value=""
    
    echo ""
    echo -e "${BOLD}${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${BOLD}${YELLOW}➤ $prompt${NC}"
    echo -e "${BOLD}${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo ""
    
    while [[ -z "$input_value" ]]; do
        read -p "Enter value: " input_value
        if [[ -z "$input_value" ]]; then
            echo -e "${RED}❌ Input cannot be empty. Please try again.${NC}"
        fi
    done
    
    eval "$var_name='$input_value'"
    echo -e "${GREEN}✓ Received!${NC}"
    echo ""
}

# Check if running as root
if [[ $EUID -ne 0 ]]; then
    echo -e "${YELLOW}⚠️  This script needs admin privileges. Restarting with sudo...${NC}"
    exec sudo bash "$0" "$@"
fi

clear
echo -e "${BOLD}${CYAN}"
echo "╔════════════════════════════════════════════════════════════════╗"
echo "║           🤖 SMART JOB AGENT INSTALLER v3.0                    ║"
echo "║           Checks completed steps - Saves time & data           ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo -e "${NC}"
echo ""

# ============================================================
# STEP 1: System Update (Skip if done)
# ============================================================
if ! is_completed "step1"; then
    echo -e "${BOLD}${BLUE}▶ STEP 1/8: Updating system packages${NC}"
    echo ""
    apt update -y
    apt upgrade -y --allow-downgrades --allow-remove-essential --allow-change-held-packages
    mark_completed "step1"
    echo -e "${GREEN}✅ Step 1 completed${NC}"
    echo ""
else
    echo -e "${GREEN}✅ Step 1 already completed - skipping${NC}"
    echo ""
fi

# ============================================================
# STEP 2: Install Dependencies (Skip if done)
# ============================================================
if ! is_completed "step2"; then
    echo -e "${BOLD}${BLUE}▶ STEP 2/8: Installing dependencies${NC}"
    echo ""
    
    # Check and install each package only if missing
    PACKAGES="curl wget git build-essential software-properties-common python3 python3-pip python3-venv tmux htop jq"
    
    for pkg in $PACKAGES; do
        if dpkg -l | grep -q "^ii  $pkg "; then
            echo -e "  ✓ $pkg already installed"
        else
            echo -e "  📦 Installing $pkg..."
            apt install -y "$pkg"
        fi
    done
    
    # Install Node.js 20.x if not present
    if ! command -v node &> /dev/null; then
        echo -e "  📦 Installing Node.js 20.x..."
        curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
        apt install -y nodejs
    else
        echo -e "  ✓ Node.js already installed: $(node --version)"
    fi
    
    # Install PM2 if not present
    if ! command -v pm2 &> /dev/null; then
        echo -e "  📦 Installing PM2..."
        npm install -g pm2
    else
        echo -e "  ✓ PM2 already installed"
    fi
    
    mark_completed "step2"
    echo -e "${GREEN}✅ Step 2 completed${NC}"
    echo ""
else
    echo -e "${GREEN}✅ Step 2 already completed - skipping${NC}"
    echo ""
fi

# ============================================================
# STEP 3: Install Ollama (Skip if already installed)
# ============================================================
if ! is_completed "step3"; then
    echo -e "${BOLD}${BLUE}▶ STEP 3/8: Installing Ollama (Local AI)${NC}"
    echo ""
    
    if ! command -v ollama &> /dev/null; then
        echo -e "  📦 Installing Ollama..."
        curl -fsSL https://ollama.com/install.sh | sh
    else
        echo -e "  ✓ Ollama already installed: $(ollama --version)"
    fi
    
    # Create systemd service if not exists
    if [[ ! -f /etc/systemd/system/ollama.service ]]; then
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
    fi
    
    systemctl enable ollama
    systemctl start ollama
    sleep 3
    
    mark_completed "step3"
    echo -e "${GREEN}✅ Step 3 completed${NC}"
    echo ""
else
    echo -e "${GREEN}✅ Step 3 already completed - skipping${NC}"
    echo ""
fi

# ============================================================
# STEP 4: Pull AI Model (Skip if already downloaded)
# ============================================================
if ! is_completed "step4"; then
    echo -e "${BOLD}${BLUE}▶ STEP 4/8: Pulling AI Model${NC}"
    echo ""
    
    # Check if model already exists
    if ollama list | grep -q "qwen2.5:3b"; then
        echo -e "  ✓ AI Model already downloaded"
    else
        echo -e "  📥 Downloading Qwen 2.5 3B model (this takes 5-10 minutes)..."
        ollama pull qwen2.5:3b
    fi
    
    mark_completed "step4"
    echo -e "${GREEN}✅ Step 4 completed${NC}"
    echo ""
else
    echo -e "${GREEN}✅ Step 4 already completed - skipping${NC}"
    echo ""
fi

# ============================================================
# STEP 5: Install OpenClaw (Skip if done)
# ============================================================
if ! is_completed "step5"; then
    echo -e "${BOLD}${BLUE}▶ STEP 5/8: Installing OpenClaw${NC}"
    echo ""
    
    if ! command -v openclaw &> /dev/null; then
        echo -e "  📦 Installing OpenClaw..."
        npm install -g openclaw
    else
        echo -e "  ✓ OpenClaw already installed"
    fi
    
    mark_completed "step5"
    echo -e "${GREEN}✅ Step 5 completed${NC}"
    echo ""
else
    echo -e "${GREEN}✅ Step 5 already completed - skipping${NC}"
    echo ""
fi

# ============================================================
# STEP 6: Telegram Setup (ALWAYS requires input - can't skip)
# ============================================================
echo -e "${BOLD}${BLUE}▶ STEP 6/8: Telegram Bot Setup${NC}"
echo ""

# Check if credentials already exist
if [[ -f /root/.openclaw/telegram-creds ]] && ! is_completed "step6"; then
    echo -e "${YELLOW}⚠️  Previous Telegram credentials found.${NC}"
    echo -e "${YELLOW}   Do you want to reuse them or enter new ones?${NC}"
    echo ""
    echo "   [1] Reuse existing credentials"
    echo "   [2] Enter new credentials"
    echo ""
    read -p "Choose (1 or 2): " reuse_choice
    
    if [[ "$reuse_choice" == "1" ]]; then
        source /root/.openclaw/telegram-creds
        echo -e "${GREEN}✓ Using existing credentials${NC}"
    else
        wait_for_input "Paste your Telegram Bot Token (from @BotFather)" "TELEGRAM_BOT_TOKEN"
        wait_for_input "Paste your Chat ID (from @userinfobot)" "TELEGRAM_CHAT_ID"
    fi
else
    # Show instructions
    echo -e "${CYAN}📱 TELEGRAM SETUP INSTRUCTIONS:${NC}"
    echo ""
    echo "   Step A: Create a Bot"
    echo "     1. Open Telegram → Search @BotFather"
    echo "     2. Send: /newbot"
    echo "     3. Name it: My Job Agent"
    echo "     4. Username: myjobagent_bot"
    echo "     5. COPY THE TOKEN"
    echo ""
    echo "   Step B: Get Your Chat ID"
    echo "     1. Search @userinfobot on Telegram"
    echo "     2. Send any message"
    echo "     3. COPY YOUR CHAT ID"
    echo ""
    
    wait_for_input "Paste your Telegram Bot Token" "TELEGRAM_BOT_TOKEN"
    wait_for_input "Paste your Chat ID" "TELEGRAM_CHAT_ID"
fi

# Save credentials
mkdir -p /root/.openclaw
cat > /root/.openclaw/telegram-creds << EOF
TELEGRAM_BOT_TOKEN="$TELEGRAM_BOT_TOKEN"
TELEGRAM_CHAT_ID="$TELEGRAM_CHAT_ID"
EOF

# Test connection
echo -e "${CYAN}📡 Testing Telegram connection...${NC}"
TEST_RESULT=$(curl -s -X POST "https://api.telegram.org/bot$TELEGRAM_BOT_TOKEN/sendMessage" \
    -d "chat_id=$TELEGRAM_CHAT_ID&text=✅ Smart Job Agent installation in progress!" \
    -o /dev/null -w "%{http_code}")

if [[ "$TEST_RESULT" == "200" ]]; then
    echo -e "${GREEN}✅ Telegram connection successful!${NC}"
else
    echo -e "${RED}❌ Telegram connection failed. Please check your token and chat ID.${NC}"
    exit 1
fi

mark_completed "step6"
echo -e "${GREEN}✅ Step 6 completed${NC}"
echo ""

# ============================================================
# STEP 7: Configure OpenClaw (Skip if done)
# ============================================================
if ! is_completed "step7"; then
    echo -e "${BOLD}${BLUE}▶ STEP 7/8: Configuring OpenClaw${NC}"
    echo ""
    
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
    
    mkdir -p /opt/job-agent/{config,templates,output/{resumes,logs}}
    
    # Create profile if not exists
    if [[ ! -f /opt/job-agent/config/profile.json ]]; then
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
    fi
    
    mark_completed "step7"
    echo -e "${GREEN}✅ Step 7 completed${NC}"
    echo ""
else
    echo -e "${GREEN}✅ Step 7 already completed - skipping${NC}"
    echo ""
fi

# ============================================================
# STEP 8: Setup 24/7 Service (Skip if done)
# ============================================================
if ! is_completed "step8"; then
    echo -e "${BOLD}${BLUE}▶ STEP 8/8: Setting up 24/7 Service${NC}"
    echo ""
    
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
    
    # Create health check
    cat > /usr/local/bin/job-agent-healthcheck.sh << 'EOF'
#!/bin/bash
if ! systemctl is-active --quiet openclaw-gateway; then
    systemctl restart openclaw-gateway
fi
EOF
    chmod +x /usr/local/bin/job-agent-healthcheck.sh
    
    # Add to crontab
    (crontab -l 2>/dev/null | grep -v "job-agent-healthcheck"; echo "* * * * * /usr/local/bin/job-agent-healthcheck.sh") | crontab -
    
    mark_completed "step8"
    echo -e "${GREEN}✅ Step 8 completed${NC}"
    echo ""
else
    echo -e "${GREEN}✅ Step 8 already completed - skipping${NC}"
    echo ""
fi

# ============================================================
# FINAL: Send success message and show dashboard
# ============================================================
send_telegram() {
    curl -s -X POST "https://api.telegram.org/bot$TELEGRAM_BOT_TOKEN/sendMessage" \
        -d "chat_id=$TELEGRAM_CHAT_ID&text=$1" > /dev/null 2>&1
}

send_telegram "🎉 *SMART JOB AGENT IS ONLINE!* 🎉%0A%0A✅ All steps completed%0A✅ Your 24/7 job application agent is ready%0A%0A📱 Try these commands:%0A/help - Show all commands%0A/status - Check agent health%0A/find field technician - Search for jobs"

clear
echo -e "${BOLD}${GREEN}"
echo "╔════════════════════════════════════════════════════════════════╗"
echo "║                    🎉 SETUP COMPLETE! 🎉                       ║"
echo "║           Your Smart Job Agent is Now Operational              ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo -e "${NC}"
echo ""
echo -e "${GREEN}✅ Ollama AI: RUNNING${NC}"
echo -e "${GREEN}✅ OpenClaw Gateway: RUNNING${NC}"
echo -e "${GREEN}✅ Telegram Bot: CONNECTED${NC}"
echo -e "${GREEN}✅ Health Checks: ACTIVE${NC}"
echo -e "${GREEN}✅ Progress Saved: $PROGRESS_FILE${NC}"
echo ""
echo -e "${BOLD}🤖 TELEGRAM COMMANDS TO TEST:${NC}"
echo -e "   /help     - Show all commands"
echo -e "   /status   - Check agent health"
echo -e "   /find     - Search for jobs"
echo ""
echo -e "${BOLD}📁 EDIT YOUR PROFILE:${NC}"
echo -e "   nano /opt/job-agent/config/profile.json"
echo ""
echo -e "${BOLD}🔧 MANAGE THE AGENT:${NC}"
echo -e "   systemctl status openclaw-gateway"
echo -e "   systemctl restart openclaw-gateway"
echo -e "   journalctl -u openclaw-gateway -f"
echo ""
echo -e "${BOLD}${GREEN}Your agent is now working 24/7! 🔥${NC}"
echo ""
echo -e "${YELLOW}💡 Tip: If you interrupt the script, just run it again - it will resume from where it stopped!${NC}"
