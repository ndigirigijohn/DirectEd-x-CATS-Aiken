# Mint Your First Cardano NFT - Workshop Guide

**Network:** Preview Testnet  
**Time:** 45-60 minutes  
**What you'll create:** A personalized NFT certificate

---

## Prerequisites

- Terminal/Command Prompt
- Text editor
- `cardano-cli` installed
- `cardano-address` installed (for key generation)

**Installation help:**
- cardano-cli: https://developers.cardano.org/docs/get-started/installing-cardano-node
- cardano-address: https://github.com/IntersectMBO/cardano-addresses

---

## Step 1: Generate Your Wallet (5 min)

### Generate Recovery Phrase

```bash
# Create workshop folder
mkdir cardano-nft-workshop
cd cardano-nft-workshop

# Generate 24-word recovery phrase
cardano-address recovery-phrase generate --size 24 > recovery-phrase.txt

# View your words (SAVE THESE SECURELY!)
cat recovery-phrase.txt
```

**⚠️ Important:** These 24 words are your wallet. Keep them safe!

### Derive Keys from Recovery Phrase

```bash
# Generate root private key
cat recovery-phrase.txt | \
  cardano-address key from-recovery-phrase Shelley > root.prv

# Derive payment key (for transactions)
cat root.prv | \
  cardano-address key child 1852H/1815H/0H/0/0 > payment.prv

# Derive stake key (for staking)
cat root.prv | \
  cardano-address key child 1852H/1815H/0H/2/0 > stake.prv

# Generate public keys
cat payment.prv | \
  cardano-address key public --with-chain-code > payment.pub
cat stake.prv | \
  cardano-address key public --with-chain-code > stake.pub
```

### Build Your Address

```bash
# Create Preview testnet address
cardano-address address payment \
    --network-tag testnet \
    --payment-key "$(cat payment.pub)" \
    --stake-key "$(cat stake.pub)" > payment.addr

# View your address
cat payment.addr
# Should start with: addr_test1...
```

### Convert Keys to cardano-cli Format

```bash
# Extract raw key bytes
cat payment.prv | bech32 > payment.prv.bech32
echo "5820$(cat payment.prv.bech32)" | xxd -r -p | tail -c 64 > payment.skey.raw

# Create cardano-cli compatible JSON format
cat > payment.skey <<EOF
{
    "type": "PaymentExtendedSigningKeyShelley_ed25519_bip32",
    "description": "Payment Signing Key",
    "cborHex": "5880$(xxd -p -c 256 payment.skey.raw | tr -d '\n')$(cat payment.prv.bech32)"
}
EOF

echo "✅ Wallet generated!"
echo "Your address: $(cat payment.addr)"
```

---

## Step 2: Get Test ADA (5 min)

You need Preview testnet ADA (tADA) to pay transaction fees.

### Option A: Faucet (Self-Service)

Visit: **https://faucet.preview.world.dev.cardano.org/**

1. Paste your address from `payment.addr`
2. Click "Request funds"
3. Wait ~30 seconds
4. You'll receive 10,000 tADA (test ADA, no real value)

### Option B: From Instructor

Share your address with the instructor:
```bash
cat payment.addr
```

### Verify You Received Funds

```bash
# Check your balance (using helper script provided by instructor)
./get-utxo.sh $(cat payment.addr)

# OR if you have a local node:
cardano-cli query utxo \
    --address $(cat payment.addr) \
    --testnet-magic 2
```

You should see a UTXO with tADA!

---

## Step 3: Prepare Your NFT Image (5 min)

### Upload Image to IPFS Using Pinata

**Option A: Upload Your Own Image**

1. Visit: **https://pinata.cloud**
2. Sign up for free account (if you don't have one)
3. Click **"Upload"** → **"File"**
4. Select your image (PNG, JPG, GIF - certificate, art, or photo)
5. Click **"Upload"**
6. Wait for upload to complete (~10 seconds)
7. Copy the **CID** from the file list

**Your CID will look like:**
- `QmYjtig7VJQ6XsnUjqqJvj7QaMcCAwtrgNdahSiFofrE7o` (CIDv0 - starts with `Qm`)
- `bafybeibm2ocdg7qbhu2mgnn6ntdc265gd2rkrg6pnokqwogceyrsphef4m` (CIDv1 - starts with `bafy`)

**Both formats work perfectly!**

**Construct your IPFS URL:**
```
ipfs://YOUR_CID_HERE
```

**Example:**
```
ipfs://bafybeibm2ocdg7qbhu2mgnn6ntdc265gd2rkrg6pnokqwogceyrsphef4m
```

**Test your image in browser:**
```
https://gateway.pinata.cloud/ipfs/YOUR_CID
https://ipfs.io/ipfs/YOUR_CID
```

Paste either URL in browser to verify your image loads correctly.

---

**Option B: Use Workshop Image (Pre-uploaded)**

Instructor will provide a pre-uploaded certificate image:
```
ipfs://bafybeibm2ocdg7qbhu2mgnn6ntdc265gd2rkrg6pnokqwogceyrsphef4m
```

**Use this if you want to skip the upload step and get to minting faster!**

---

## Step 4: Create Minting Policy (10 min)

### Generate Policy Keys

```bash
# Generate policy key pair
cardano-cli address key-gen \
    --verification-key-file policy.vkey \
    --signing-key-file policy.skey

# Get key hash
cardano-cli address key-hash \
    --payment-verification-key-file policy.vkey > policy.hash

cat policy.hash
```

### Get Current Slot and Calculate Deadline

```bash
# Get current slot (using helper script)
CURRENT_SLOT=$(./get-tip.sh)
echo "Current slot: $CURRENT_SLOT"

# Add 1 hour (3600 slots)
DEADLINE=$((CURRENT_SLOT + 3600))
echo "Deadline slot: $DEADLINE"
```

**Note:** After this slot, no more NFTs can be minted with this policy (creates scarcity).

### Create Policy Script

```bash
# Create policy.script file
cat > policy.script <<EOF
{
  "type": "all",
  "scripts": [
    {
      "type": "sig",
      "keyHash": "$(cat policy.hash)"
    },
    {
      "type": "before",
      "slot": $DEADLINE
    }
  ]
}
EOF
```

**What this means:**
- Only you can mint (signature required)
- Only before deadline slot (time lock)

### Generate Policy ID

```bash
cardano-cli transaction policyid \
    --script-file policy.script > policy.id

echo "Your Policy ID:"
cat policy.id
```

This unique ID identifies your NFT collection!

---

## Step 5: Create NFT Metadata (5 min)

```bash
# Create metadata.json with your details
POLICY_ID=$(cat policy.id)

cat > metadata.json <<EOF
{
  "721": {
    "$POLICY_ID": {
      "WorkshopNFT": {
        "name": "Cardano NFT Workshop Certificate",
        "image": "ipfs://YOUR_IPFS_HASH_HERE",
        "description": "My first NFT minted on Cardano Preview testnet",
        "attributes": {
          "participant": "YOUR_NAME",
          "date": "December 2025",
          "workshop": "Cardano NFT Basics",
          "network": "Preview Testnet"
        }
      }
    }
  }
}
EOF
```

**Customize:**
- Replace `YOUR_IPFS_HASH_HERE` with your IPFS hash
- Replace `YOUR_NAME` with your actual name

**Verify:**
```bash
cat metadata.json
```

---

## Step 6: Build Minting Transaction (10 min)

### Get Your UTXO

```bash
# Query your UTXOs
./get-utxo.sh $(cat payment.addr)

# You'll see something like:
# TxHash                                 TxIx  Amount
# abc123...                              0     10000000 lovelace
```

**Copy the TxHash#TxIx** (e.g., `abc123...#0`)

### Build the Transaction

```bash
# Set your UTXO
TX_IN="YOUR_TXHASH#TXIX"

# Build minting transaction
cardano-cli transaction build \
    --testnet-magic 2 \
    --tx-in $TX_IN \
    --tx-out "$(cat payment.addr)+2000000 + 1 $(cat policy.id).WorkshopNFT" \
    --mint "1 $(cat policy.id).WorkshopNFT" \
    --mint-script-file policy.script \
    --metadata-json-file metadata.json \
    --invalid-hereafter $DEADLINE \
    --change-address $(cat payment.addr) \
    --out-file mint.raw

echo "✅ Transaction built!"
```

**What's happening:**
- `--tx-in`: Input UTXO paying for fees
- `--tx-out`: Output with NFT + 2 ADA (min required with NFT)
- `--mint`: Creating 1 token named "WorkshopNFT"
- `--mint-script-file`: Policy rules
- `--metadata-json-file`: NFT information
- `--invalid-hereafter`: Must submit before deadline
- `--change-address`: Where leftover ADA goes

---

## Step 7: Sign the Transaction (5 min)

```bash
cardano-cli transaction sign \
    --tx-body-file mint.raw \
    --signing-key-file payment.skey \
    --signing-key-file policy.skey \
    --testnet-magic 2 \
    --out-file mint.signed

echo "✅ Transaction signed!"
```

**Why two signatures?**
- `payment.skey`: Authorizes spending your ADA
- `policy.skey`: Authorizes minting under your policy

---

## Step 8: Submit to Blockchain! (5 min)

```bash
# Submit using helper script
./submit-tx.sh mint.signed

# OR if using cardano-cli with local node:
cardano-cli transaction submit \
    --testnet-magic 2 \
    --tx-file mint.signed
```

**Wait 20-30 seconds** for blockchain confirmation...

### Verify Your NFT

```bash
# Check your address again
./get-utxo.sh $(cat payment.addr)

# You should now see:
# ... + 1 <POLICY_ID>.WorkshopNFT
```

🎉 **Congratulations! You've minted your first NFT!**

---

## Step 9: View Your NFT

### Option A: View in Browser Wallet (Recommended)

Import your recovery phrase to see the NFT visually:

**Eternl Wallet:**
1. Install Eternl browser extension
2. Click "Restore Wallet"
3. Enter your 24 words from `recovery-phrase.txt`
4. Switch to Preview testnet (Settings → Network → Preview)
5. View your NFT in the "NFT" tab!

**Nami/Lace Wallet:**
- Similar process: Restore → Enter 24 words → Switch to Preview

### Option B: View on Blockchain Explorer

**Preview Testnet Explorers:**

1. **CardanoScan:** https://preview.cardanoscan.io
   - Search your address or policy ID
   - View transaction details
   - See NFT metadata

2. **Cexplorer:** https://preview.cexplorer.io
   - Search your policy ID
   - View all tokens under policy
   - Detailed transaction info

**What to search:**
```bash
# Your address
cat payment.addr

# Your policy ID
cat policy.id

# Transaction hash (from submit output)
```

---

## Understanding Your Files

```
cardano-nft-workshop/
├── recovery-phrase.txt      # 24 words - KEEP SAFE!
├── root.prv                 # Root private key
├── payment.prv              # Payment private key
├── payment.pub              # Payment public key
├── payment.skey             # CLI signing key
├── payment.addr             # Your address
├── stake.prv                # Stake private key
├── stake.pub                # Stake public key
├── policy.vkey              # Policy verification key
├── policy.skey              # Policy signing key - KEEP SAFE!
├── policy.hash              # Policy key hash
├── policy.script            # Minting policy rules
├── policy.id                # Your unique policy ID
├── metadata.json            # NFT metadata (CIP-25)
├── mint.raw                 # Unsigned transaction
└── mint.signed              # Signed transaction
```

**🔒 Keep secure:**
- `recovery-phrase.txt` - Can restore entire wallet
- `payment.skey` - Can spend your ADA
- `policy.skey` - Can mint more NFTs (until deadline)

---

## Next Steps

### Transfer NFT to Another Address

```bash
# Build transfer transaction
cardano-cli transaction build \
    --testnet-magic 2 \
    --tx-in <UTXO_WITH_NFT> \
    --tx-out "RECIPIENT_ADDRESS+2000000 + 1 $(cat policy.id).WorkshopNFT" \
    --change-address $(cat payment.addr) \
    --out-file transfer.raw

# Sign and submit
cardano-cli transaction sign \
    --tx-body-file transfer.raw \
    --signing-key-file payment.skey \
    --testnet-magic 2 \
    --out-file transfer.signed

./submit-tx.sh transfer.signed
```

### Mint More NFTs (Before Deadline)

```bash
# Just change the asset name and metadata
# Build similar transaction with:
# --mint "1 $(cat policy.id).WorkshopNFT002"
```

### Lock Your Policy (After Minting Complete)

Once the deadline slot passes, your policy is **automatically locked forever**. No one can mint more NFTs with this policy ID!

---

## Troubleshooting

### Error: "Missing required signers"
- Make sure you're signing with both `payment.skey` AND `policy.skey`

### Error: "Slot number too late"
- Your deadline has passed. Create a new policy with a later deadline.

### Error: "Not enough ADA"
- Request more tADA from faucet
- Remember: NFTs require ~2 ADA minimum in the UTXO

### Error: "Transaction too large"
- Metadata is too big. Simplify your JSON or reduce attribute count.

### Can't see NFT in wallet
1. Make sure wallet is on Preview testnet
2. Wait ~1 minute for wallet to sync
3. Check in "NFT" or "Tokens" tab
4. Verify transaction on explorer first

### Invalid UTXO reference
- Your UTXO was already spent
- Query UTXOs again: `./get-utxo.sh $(cat payment.addr)`
- Use a different UTXO

---

## Key Concepts Learned

✅ **Native Assets** - NFTs on Cardano don't need smart contracts for basic operations  
✅ **Policy ID** - Unique identifier for your NFT collection  
✅ **Minting Policy** - Rules for who can mint and when  
✅ **Time Locks** - Create scarcity by locking minting after deadline  
✅ **CIP-25** - Metadata standard for NFTs  
✅ **IPFS** - Decentralized storage for images  
✅ **UTXOs** - Cardano's accounting model  
✅ **Testnet** - Safe environment for learning  

---

## Resources

**Documentation:**
- Cardano Docs: https://docs.cardano.org
- CIP-25 Standard: https://cips.cardano.org/cips/cip25/
- cardano-cli Guide: https://developers.cardano.org

**Tools:**
- Preview Faucet: https://faucet.preview.world.dev.cardano.org/
- IPFS Upload: https://nft.storage
- Preview Explorer: https://preview.cardanoscan.io

**Community:**
- Cardano Forum: https://forum.cardano.org
- Cardano Stack Exchange: https://cardano.stackexchange.com
- Discord: Various project servers

---

## Security Reminders

⚠️ **This is Preview Testnet:**
- Test ADA has NO real value
- Safe for learning and experimentation
- Different from mainnet

⚠️ **NEVER:**
- Share your recovery phrase or private keys
- Use testnet keys on mainnet
- Export keys from mainnet wallets for practice

✅ **DO:**
- Keep your recovery phrase secure
- Delete testnet keys after workshop (or keep for continued learning)
- Practice on testnet before going to mainnet

---

## Congratulations! 🎉

You've successfully:
- Generated a Cardano wallet
- Funded it with testnet ADA
- Created a minting policy
- Uploaded to IPFS
- Minted an NFT following CIP-25
- Verified on the blockchain

You now understand the fundamentals of NFTs on Cardano and can build upon this knowledge to create your own projects!

**Share your success:**
- Post your NFT on social media
- Join Cardano developer communities
- Help others learn

---

*Workshop Guide v1.0 - Preview Testnet*  
*Questions? Ask your instructor!*
