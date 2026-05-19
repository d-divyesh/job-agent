# 🤖 Job Agent - Autonomous 24/7 Job Application System

[![Version](https://img.shields.io/badge/version-2.0.0-blue.svg)]()
[![Platform](https://img.shields.io/badge/platform-Linux-red.svg)]()
[![License](https://img.shields.io/badge/license-MIT-green.svg)]()

## 🚀 One-Command Installation

curl -fsSL https://raw.githubusercontent.com/YOUR_USERNAME/job-agent/main/install.sh | sudo bash

---

## ✨ Features

| Feature | Description |
|---------|-------------|
| 🔄 24/7 Autonomous Operation | Runs day and night without stopping |
| 🧠 Local AI | No API keys, no token limits, completely free |
| 📱 Telegram Bot Interface | Control everything from your phone |
| 📊 Progress Dashboard | Visual installation tracking with percentages |
| 🔍 Auto Job Search | Scrapes Indeed, LinkedIn, and job boards |
| 📝 Resume Tailoring | Customizes resume per job automatically |
| 📧 Auto-Apply | Submits applications to supported portals |
| 🛡️ CAPTCHA Handling | Pings you on Telegram when human help needed |
| 💾 Low Resource Usage | Runs on 4GB RAM, 10GB disk space |
| 🔐 Privacy Focused | All data stays on your machine |

---

## 🤖 Telegram Commands

| Command | Action |
|---------|--------|
| /help | Show all available commands |
| /status | Check agent health and uptime |
| /find [job title] | Search for jobs (e.g., /find field technician) |
| /profile | View your saved profile information |
| /resume [job_id] | Generate tailored resume for specific job |
| /apply [job_id] | Auto-apply to a job posting |
| /stats | Show application statistics |
| /pause | Pause the agent |
| /resume | Resume the agent |
| /stop | Stop the agent completely |

---

## 🔧 Maintenance Commands

### Service Management

# Check if agent is running
systemctl status openclaw-gateway

# Check Ollama AI status
systemctl status ollama

# Restart agent
systemctl restart openclaw-gateway

# Stop agent
systemctl stop openclaw-gateway

# Start agent
systemctl start openclaw-gateway

### View Logs

# View live agent logs
journalctl -u openclaw-gateway -f

# View last 100 lines
journalctl -u openclaw-gateway -n 100

# View Ollama logs
journalctl -u ollama -f

# View setup log
cat /var/log/job-agent-setup.log

# View error log
cat /var/log/job-agent-errors.log

### Edit Configuration

# Edit your profile (name, skills, experience)
nano /opt/job-agent/config/profile.json

# Edit resume template
nano /opt/job-agent/templates/resume_template.txt

# Edit agent configuration
nano ~/.openclaw/openclaw.json

### Manual Control

# Run agent in foreground (for debugging)
openclaw gateway start

# Attach to tmux session
tmux attach -t jobagent

# List all tmux sessions
tmux ls

# Kill and restart tmux session
tmux kill-session -t jobagent
tmux new -s jobagent 'openclaw gateway start'

---

## 📁 Directory Structure

/opt/job-agent/
│
├── config/
│   └── profile.json
│
├── templates/
│   └── resume_template.txt
│
├── output/
│   ├── resumes/
│   └── logs/
│
├── scripts/
│   ├── healthcheck.sh
│   └── backup.sh
│
└── systemd/
    ├── ollama.service
    └── openclaw-gateway.service

~/.openclaw/
└── openclaw.json

/var/log/
├── job-agent-setup.log
└── job-agent-errors.log

---

## 📝 Requirements

| Requirement | Minimum | Recommended |
|-------------|---------|-------------|
| Operating System | Ubuntu 20.04+ / Debian 11+ | Ubuntu 22.04 LTS |
| RAM | 4GB | 8GB+ |
| Disk Space | 10GB | 20GB |
| CPU | 2 cores | 4 cores |
| Internet | Required | Required |

---

## 🗑️ Uninstall

curl -fsSL https://raw.githubusercontent.com/YOUR_USERNAME/job-agent/main/uninstall.sh | sudo bash

---

## ❓ Troubleshooting

### Agent not responding on Telegram

systemctl restart openclaw-gateway
cat ~/.openclaw/openclaw.json | grep botToken

### Ollama not working

systemctl status ollama
systemctl restart ollama
ollama run qwen2.5:3b "Hello"

### Out of memory errors

free -h
ollama pull qwen2.5:1.5b

---

## 📄 License

MIT License

---

Made with 🔥 for job seekers worldwide
