# Module M007 Hands-on

Treat these exercises like a mini deployment rehearsal—each one bridges on-chain validators with off-chain tooling.

## 1. Inspect the blueprint

1. Run `aiken build` in a project that includes both spending and minting validators.
2. Open `plutus.json` and locate:
   - `compiledCode`
   - `hash`
   - datum/redeemer schemas
3. Record constructor indexes for at least one datum and one redeemer type.
4. Translate a schema entry into the equivalent Mesh/Lucid representation (e.g., `alternative` and `fields` structure).

## 2. Generate addresses and policy IDs

1. Use `aiken blueprint address -v path.to.validator.spend` to get a script address.
2. Use `aiken blueprint policy -v path.to.policy.mint` to get a policy ID.
3. Repeat after parameterising the validator (next step) and observe how the hashes change.

## 3. Apply parameters

1. Choose a parameterised validator (state machine, marketplace, etc.).
2. Use Mesh/Lucid helpers or `aiken apply-params` (if available) to supply concrete parameter values.
3. Verify the resulting script hash and address are different per parameter set.
4. Document the exact parameter list (type + source) for deployment.

## 4. Encode datums/redeemers off-chain

1. Pick a complex datum (e.g., state machine state or marketplace listing).
2. Write a short snippet (TypeScript or pseudo-code) that constructs the datum using constructor indexes from the blueprint.
3. Do the same for a redeemer with multiple constructors.
4. Validate the encoding by running tests that deserialize these values on-chain.

## 5. Design a dependency tree

1. Choose a multi-validator scenario (NFT marketplace, staking pool, DAO, etc.).
2. List every validator/policy involved and the parameters each one needs.
3. Draw or describe the deployment order: which UTxO references, policy IDs, or addresses must exist before compiling the next component.
4. Capture this as markdown so teammates can follow the same steps.

## 6. Plan end-to-end transactions

1. For one user action (e.g., buying an NFT), describe:
   - Which validators/minting policies are involved.
   - What datums/redeemers they expect.
   - How reference inputs or tokens connect them.
2. Optionally, prototype the transaction in Mesh/Lucid using the blueprint data you gathered.

By the end of these exercises you should feel comfortable handing `plutus.json` to an off-chain team along with precise instructions on how to use it.
