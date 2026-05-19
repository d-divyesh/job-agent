#!/bin/bash
# ============================================================
# JOB AGENT UNINSTALLER
# Repository: https://github.com/d-divyesh/job-agent
# Version: 2.0.0
# ============================================================

set -e

echo "🗑️ Uninstalling Job Agent..."

# Stop services
echo "Stopping services..."
systemctl stop openclaw-gateway ollama 2>/dev/null || true
systemctl disable openclaw-gateway ollama 2>/dev/null || true

# Remove systemd files
echo "Removing systemd services..."
rm -f /etc/systemd/system/openclaw-gateway.service
rm -f /etc/systemd/system/ollama.service

# Remove cron jobs
echo "Removing cron jobs..."
crontab -l | grep -v "job-agent-healthcheck" | crontab - 2>/dev/null || true

# Remove binaries
echo "Removing binaries..."
rm -f /usr/local/bin/job-agent-healthcheck.sh

# Remove project directory
echo "Removing project files..."
rm -rf /opt/job-agent
rm -rf ~/.openclaw

# Remove tmux sessions
tmux kill-session -t jobagent 2>/dev/null || true

# Reload systemd
systemctl daemon-reload

echo ""
echo "✅ Uninstall complete!"
echo ""
echo "Note: Ollama and Node.js were not removed to preserve other projects."
echo "To remove Ollama: sudo apt remove ollama -y"
echo "To remove Node.js: sudo apt remove nodejs -y"
echo ""
echo "To also remove logs: sudo rm -rf /var/log/job-agent-*.log"
