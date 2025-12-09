# Module M001 – First Validator

**Goal**  
Write, test, and compile your first spending and minting validators so you understand every moving part in a Cardano smart contract.

**Key skills**
- Read and author validator type signatures (datum, redeemer, context).
- Implement “always succeed” patterns before layering real logic.
- Use Vodka/Mocktail helpers to build minimal success and failure tests.
- Compile validators to produce `plutus.json`, derive script addresses, and calculate policy IDs.
- Interpret compiler/test output so you can debug quickly.

**Practice focus**
1. Scaffold a new validator in `workshop-examples/validators/m001` following the template in `hands-on.md`.
2. Add custom datum/redeemer types, wire them into the validator signature, and create simple pattern matches.
3. Write at least one passing and one failing test using the provided mocks.
4. Run `aiken build`, inspect the resulting blueprint, and note the validator hash, script address, or policy ID.

**Move on when**
- You can explain how spending vs minting validators differ and when to choose each.
- Tests run quickly and you’re comfortable editing both the validator and its test suite.
- You can locate the validator entry inside `plutus.json` and map it back to your code.

**Next steps**  
Use `hands-on.md` for a detailed walk-through, then switch to `challenge.md` to extend the validator with custom rules.
