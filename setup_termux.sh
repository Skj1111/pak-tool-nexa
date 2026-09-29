#!/data/data/com.termux/files/usr/bin/bash
# Termux one-time setup

echo "[*] Updating packages..."
pkg update -y && pkg upgrade -y

echo "[*] Installing base tools..."
pkg install python openjdk-17 wget curl git clang make lua53 nodejs -y

echo "[*] Setting up storage access..."
termux-setup-storage

echo "[*] Installing Python dependencies..."
pip install --upgrade pip
pip install -r requirements.txt

echo "[*] Installing unluac.jar (standard Lua decompiler)..."
mkdir -p ~/tools
wget -O ~/tools/unluac.jar \
  https://github.com/FModel/unluac/releases/latest/download/unluac.jar

echo "[*] Installing LuaJIT decompiler (Node.js)..."
npm install -g node-luajit-decompiler-v2@1.0.7

echo "[+] Setup complete!"
echo "    Run: python tool.py"