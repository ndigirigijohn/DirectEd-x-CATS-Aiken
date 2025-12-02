# cardano-cli Installation Guide

Quick guide to install `cardano-cli` for Cardano NFT development.

---

## Linux (Ubuntu/Debian)

### Download Pre-built Binary

```bash
# Download latest release
wget https://github.com/IntersectMBO/cardano-node/releases/download/8.9.0/cardano-node-8.9.0-linux.tar.gz

# Extract
tar -xzf cardano-node-8.9.0-linux.tar.gz

# Move to system PATH
sudo mv cardano-cli /usr/local/bin/
sudo mv cardano-node /usr/local/bin/

# Verify installation
cardano-cli --version
```

**Expected output:**
```
cardano-cli 8.9.0 - linux-x86_64 - ghc-8.10
```

✅ **You're ready!**

---

## macOS

### Option 1: Homebrew (Recommended)

```bash
# Install Homebrew if not installed
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# Install cardano-cli
brew install cardano-cli

# Verify
cardano-cli --version
```

### Option 2: Download Binary

```bash
# Download
wget https://github.com/IntersectMBO/cardano-node/releases/download/8.9.0/cardano-node-8.9.0-macos.tar.gz

# Extract
tar -xzf cardano-node-8.9.0-macos.tar.gz

# Move to PATH
sudo mv cardano-cli /usr/local/bin/
sudo mv cardano-node /usr/local/bin/

# Verify
cardano-cli --version
```

✅ **You're ready!**

---

## Windows

### Option 1: WSL (Windows Subsystem for Linux) - RECOMMENDED

**Why WSL?** Best compatibility with Cardano tools and all workshop commands work as-is.

#### Step 1: Install WSL

Open **PowerShell as Administrator**:
```powershell
wsl --install
```

Restart your computer when prompted.

#### Step 2: Open Ubuntu

Search for "Ubuntu" in Start menu and open it.

Create username and password when prompted.

#### Step 3: Install cardano-cli

```bash
# Update system
sudo apt update

# Download cardano-cli
wget https://github.com/IntersectMBO/cardano-node/releases/download/8.9.0/cardano-node-8.9.0-linux.tar.gz

# Extract
tar -xzf cardano-node-8.9.0-linux.tar.gz

# Move to PATH
sudo mv cardano-cli /usr/local/bin/
sudo mv cardano-node /usr/local/bin/

# Verify
cardano-cli --version
```

✅ **You're ready!**

**Working with files:**
- Your Windows `C:\` drive is at `/mnt/c/` in WSL
- Example: `/mnt/c/Users/YourName/Documents/`

---

### Option 2: Native Windows Binary

#### Step 1: Download

Visit: https://github.com/IntersectMBO/cardano-node/releases

Download: `cardano-node-8.9.0-win64.zip`

#### Step 2: Extract

Extract to `C:\cardano\` (or any folder you prefer)

#### Step 3: Add to PATH

1. Press `Win + X` → **System**
2. Click **Advanced system settings**
3. Click **Environment Variables**
4. Under "System variables", find **Path**
5. Click **Edit** → **New**
6. Add: `C:\cardano`
7. Click **OK** on all dialogs

#### Step 4: Verify

Open **new** Command Prompt or PowerShell:
```cmd
cardano-cli --version
```

✅ **You're ready!**

---

### Option 3: Demeter.run (No Installation)

**Best for:** Quick start, workshops, no installation hassles

1. Go to: https://demeter.run
2. Sign up (free tier available)
3. Create workspace
4. Select "Cardano" template
5. Open terminal in browser

✅ **cardano-cli pre-installed!**

---

## Verify Installation

After installation, test with:

```bash
# Check version
cardano-cli --version

# Check help
cardano-cli --help

# Generate test keys (optional)
cardano-cli address key-gen \
    --verification-key-file test.vkey \
    --signing-key-file test.skey

# Clean up
rm test.vkey test.skey
```

If all commands work, you're ready for the workshop!

---

## Additional Tools (Optional)

### cardano-address

Used for generating recovery phrases:

```bash
# Linux/macOS
wget https://github.com/IntersectMBO/cardano-addresses/releases/download/3.12.0/cardano-addresses-3.12.0-linux64.tar.gz

tar -xzf cardano-addresses-3.12.0-linux64.tar.gz

sudo mv bin/cardano-address /usr/local/bin/

# Verify
cardano-address --version
```

---

## Troubleshooting

### "Command not found"

**Linux/Mac:**
```bash
# Check if in PATH
which cardano-cli

# If not found, add to PATH manually
export PATH=$PATH:/usr/local/bin

# Make permanent (add to ~/.bashrc or ~/.zshrc)
echo 'export PATH=$PATH:/usr/local/bin' >> ~/.bashrc
source ~/.bashrc
```

**Windows:**
- Restart terminal after adding to PATH
- Ensure you added correct directory
- Run as Administrator if needed

### "Permission denied"

```bash
# Make executable
chmod +x /usr/local/bin/cardano-cli

# Or use sudo
sudo chmod +x /usr/local/bin/cardano-cli
```

### "Library not found" (Linux)

```bash
# Install dependencies
sudo apt-get update
sudo apt-get install -y \
    libsodium-dev \
    libgmp-dev \
    libssl-dev \
    libtinfo-dev
```

---

## Quick Reference

**Latest releases:**
https://github.com/IntersectMBO/cardano-node/releases

**Documentation:**
https://developers.cardano.org/docs/get-started/installing-cardano-node

**Community support:**
- Cardano Forum: https://forum.cardano.org
- Cardano Stack Exchange: https://cardano.stackexchange.com

---

## What's Next?

Once installed, you're ready to:
- Generate wallets
- Mint NFTs
- Build transactions
- Deploy smart contracts

Proceed to the **NFT Workshop Guide** to mint your first NFT!

---

*Installation Guide v1.0 - Updated December 2025*
