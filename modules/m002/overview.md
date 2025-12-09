# Module M002 – Mock Transactions

**Goal**  
Model real Cardano transactions in tests so every validator you build can be exercised with believable inputs, outputs, and minting operations before touching the blockchain.

**Key skills**
- Break down the structure of a transaction (inputs, outputs, minting, signers, validity range).
- Use Mocktail utilities to create spending, locking, and minting transactions.
- Add inline datums to outputs and craft redeemers that unlock them.
- Simulate multi-asset values and token bundles inside test scenarios.
- Document transaction flows so future readers know what each mock is proving.

**Practice focus**
1. Start from the templates in `hands-on.md` to assemble a base transaction and progressively add inputs/outputs.
2. Write a locking transaction that pushes funds to a validator address with an inline datum.
3. Create the matching unlocking transaction that spends the output using a redeemer.
4. Extend the same pattern to mint multiple NFTs and verify the resulting token quantities.

**Move on when**
- You can explain which parts of a transaction a validator can inspect and how to mock them.
- Your tests cover both the “happy path” and at least one failure path using the same validator.
- You feel comfortable reusing helper functions to avoid copy/pasting transaction scaffolding.

**Next steps**  
Follow the practical walkthrough in `hands-on.md`, then tackle the scenario described in `challenge.md` to cement these patterns.
