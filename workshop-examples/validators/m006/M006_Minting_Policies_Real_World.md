# Module M006: Minting Policies & NFT Oracles – Real-World Guide

This module dives into minting policies, one-shot NFTs, oracle patterns, and collection flows. Below you'll find practical stories from the m006 code plus the exact validation logic that makes them safe.

---

## 1. Authorized Minting – “Artist-Only NFTs”

**Story:** Noor wants only her wallet to mint limited-edition art tokens. Unauthorized accounts must fail when trying to mint or burn.

**Validator:** `simple_authorized_mint`

**Key Pattern:** Require a signature + check minted quantities.

```aiken
let signed = key_signed(self.extra_signatories, authorized_key)
let tokens = assets.tokens(self.mint, policy_id)

SimpleMint ->
  signed &&
  list.all(tokens |> dict.values(), fn(q) { q > 0 })

SimpleBurn ->
  signed &&
  list.all(tokens |> dict.values(), fn(q) { q < 0 })
```

**Uses:**
- Artist-owned policies
- “Burn only if artist approves”
- Emergency shutoff controlled by a single key

---

## 2. One-Shot NFTs – “Golden Ticket”

**Story:** A festival issues a single “Golden Ticket” per raffle entry. The script must ensure each ticket is minted exactly once.

**Validator:** `one_shot_nft`

**Key Pattern:** Require a specific UTxO reference, ensuring one-time mint.

```aiken
let has_utxo =
  list.any(self.inputs, fn(input) { input.output_reference == utxo_ref })

expect [Pair(_, quantity)] = tokens |> dict.to_pairs()

has_utxo && quantity == 1
```

**Uses:**
- KYC-approved single mint
- Admin “badge” minted once then burned later
- Oracle NFTs used as on-chain identity

---

## 3. Named NFTs with Prefix – “Collection Branding”

**Story:** A studio wants all token names to begin with `MyCoolNFT_`. Any deviation gets rejected.

**Validator:** `named_nft`

**Key Pattern:** Byte-array prefix validation.

```aiken
let prefix_length = bytearray.length(params.required_prefix)
let token_prefix = bytearray.take(token_name, prefix_length)

token_prefix == params.required_prefix
```

**Uses:**
- Enforcing naming standards (`GameItem_001`, `GameItem_002`, …)
- Preventing counterfeit series
- Guaranteeing human-readable identifiers

---

## 4. Oracle NFT – “Single Source of Truth”

**Story:** Before launching an oracle validator, we mint exactly one reference NFT locked inside the oracle script. Later, burning it shuts the oracle down.

**Validator:** `oracle_nft`

**Key Pattern:** UTxO-gated mint for empty-name token.

```aiken
expect [Pair(token_name, quantity)] = tokens |> dict.to_pairs()

has_utxo && token_name == "" && quantity == 1
```

**Uses:**
- Oracle reference tokens
- Capability tokens (only contract with NFT may update data)
- DAO keys for admin powers

---

## 5. Mini Oracle Validator – “Up-Only Counter”

**Story:** A lightweight oracle tracks a public counter (like number of claims). It must:
1. Allow only one script input
2. Preserve the NFT + value
3. Increment the counter by exactly one

**Validator:** `mini_oracle`

**Key Pattern:** Asserting single script input/output + state increment.

```aiken
expect [_single_input] = script_inputs
expect [continuing_output] = outputs_to_self
expect InlineDatum(new_state_data) = continuing_output.datum
expect new_state: MiniOracleDatum = new_state_data

let count_incremented = new_state.count == current_state.count + 1
let value_preserved = continuing_output.value == own_input.output.value
```

**Uses:**
- Punch-card loyalty counters
- Simple data feeds with monotonic updates
- Rate-limited consumption (e.g., first-come-first-served counters)

---

## 6. Full Oracle Validator – “Metered Minting Service”

**Story:** The oracle sells “collection mint slots” for 5 ADA each. Requirements:
1. Only one script input/output
2. State fields (price, fee address) never change
3. Fee output pays the oracle admin address
4. Oracle NFT stays locked

**Validator:** `oracle_validator`

**Core Checks:**

```aiken
let count_incremented = new_state.count == current_state.count + 1
let price_unchanged = new_state.lovelace_price == current_state.lovelace_price
let fee_paid =
  list.any(self.outputs, fn(output) {
    output.address == current_state.fee_address &&
    assets.lovelace_of(output.value) >= current_state.lovelace_price
  })

let value_unchanged = continuing_output.value == own_input.output.value
```

**Uses:**
- Pay-to-mint gatekeepers
- Rate-controlled APIs (each mint costs stable fee)
- Admin-controlled shutdown via `StopOracle`

---

## 7. Collection Mint Policy – “Series with Sequential IDs”

**Story:** A minting policy reads the oracle reference input to fetch the current counter and enforces token names such as `GenesisNFT (3)`, `GenesisNFT (4)`, etc.

**Validator:** `collection_nft`

**Key Steps:**
1. **Find oracle reference input** carrying the NFT.
2. **Load oracle datum** via inline data to read the counter.
3. **Require exactly one mint** for this policy.
4. **Verify token name** matches `collection_name ++ " (" ++ counter ++ ")"`.

```aiken
expect Some(oracle_input) = list.find(self.reference_inputs, ...)
expect InlineDatum(oracle_datum_data) = oracle_input.output.datum
let current_count = oracle_datum.count

expect [Pair(token_name, quantity)] = minted |> dict.to_pairs()
expect quantity == 1

token_name == make_token_name(params.collection_name, current_count)
```

**Uses:**
- Oracle-driven collections (sequential numbering)
- Guaranteed unique metadata per mint
- Enforcing “mint exactly one per purchase” flows

---

## Testing Strategy Recap

Every validator ships with:
- ✅ Success tests (expected behavior)
- ❌ Failure tests for missing signatures, wrong prefixes, missing reference inputs, insufficient fees, etc.

This verifies both **happy paths** and **guardrails**. For example:

- `test_collection_nft_without_oracle_fails` proves the policy rejects minting when the oracle reference input is missing.
- `test_oracle_insufficient_fee_fails` shows incomplete fee payments halt the oracle.
- `test_one_shot_mint_multiple_tokens_fails` ensures one-shot policies reject multi-mint attempts.

---

## Cheat Sheet

| Pattern | Validator | Why it matters |
| --- | --- | --- |
| Authorized Minting | `simple_authorized_mint` | Protects mint/burn with signatures |
| UTxO-Gated NFT | `one_shot_nft` / `oracle_nft` | Guarantees single mint per reference |
| Naming Rules | `named_nft` | Enforces brand or metadata structure |
| Oracle Counter | `mini_oracle` | Ensures state increments & value locks |
| Fee-Gated Oracle | `oracle_validator` | Monetizes mint slots, allows shutdown |
| Oracle-Driven Collection | `collection_nft` | Sequential naming tied to oracle state |

---

## Next Steps

Once you understand these patterns, you can:
- **Chain policies together** (oracle validator + collection minter)
- **Add metadata outputs** (CIP-25) to the minted NFT
- **Tie in royalties** (CIP-27) when building marketplaces
- **Integrate reference scripts** for lower transaction costs

Minting policies are *stateless*, so complex flows use **oracles + reference inputs** to “borrow” state. Module M006 is your toolkit for those richer NFT experiences.

