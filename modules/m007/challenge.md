# Module M007 Challenge

Produce a deployment-ready dossier for a small DApp composed of:

- Oracle NFT policy (from Module M006)
- Oracle validator
- Collection minting policy
- Listing validator (users list NFTs for sale)

## Deliverables

1. **Blueprint summary**
   - For each validator/policy, record the blueprint `title`, `hash`, datum schema, redeemer schema, and constructor indexes.
   - Show how to encode at least one datum and one redeemer for the listing validator in off-chain code (pseudo-code is fine).
2. **Parameter dependency map**
   - Document every parameter (type + meaning + source UTxO/token) and the order they must be provided.
   - Outline the deployment sequence: selecting the UTxO for the oracle NFT, compiling parameterised scripts, generating addresses, and funding them.
3. **Transaction walkthrough**
   - Describe the exact validators/policies invoked when a buyer purchases an NFT:
     - Inputs/outputs involved
     - Datums/redeemers supplied
     - Reference inputs required
     - Tokens minted or burned (if any)
4. **Testing plan**
   - List the integration tests you would run (both on-chain unit tests and off-chain transaction simulations) before mainnet deployment.

Aim for clarity—a teammate should be able to read your notes, reproduce the setup, and build transactions without asking follow-up questions.
