# Module M007 – Blueprints & DApp Architecture

This capstone module glues everything together. You’ll learn how compiled validators surface inside `plutus.json`, how off-chain code consumes datum/redeemer schemas, and how to design multi-validator systems (marketplaces, staking pools, DAOs) with clear parameter flows and deployment plans.

## Core concepts

- **Blueprint anatomy** – `plutus.json` stores compiled code, hashes, and JSON schemas. Constructor indexes exposed here drive redeemer/datum encoding for Mesh, Lucid, and other builders.
- **Off-chain mapping** – Generate script addresses and policy IDs from blueprint hashes, apply parameters before deployment, and convert Aiken types into off-chain data structures (bytes, ints, lists).
- **Parameter dependency trees** – Document how oracle policies, validators, and collection contracts reference one another so deployments happen in the right order.
- **Multi-validator patterns** – Combine oracle + consumer, listing + offer, staking + rewards, and governance + treasury validators where transactions carry state between them via inputs, outputs, or reference inputs.
- **Production readiness** – Consider initialization scripts, upgrade paths, cost optimisation, and test strategies for complex ecosystems.

## Learning checkpoints

1. Open `plutus.json`, locate a validator entry, and map its schema to an off-chain representation.
2. Apply parameters to a validator, regenerate the script address, and explain why changing parameters changes the hash.
3. Design a dependency graph for an oracle-driven NFT marketplace (oracle policy → oracle validator → collection policy → listing validator).
4. Plan deployment + initialization steps (UTxO selection, parameter capture, blueprint distribution) and capture them in documentation.

## When to move on

- You can read any blueprint entry and immediately tell an off-chain engineer how to encode the datum/redeemer.
- Parameterised validators no longer feel mysterious—you know when to apply parameters and how to version them.
- Your architecture diagrams include validators, policies, tokens, reference inputs, and data flows, with notes about who deploys/configures each part.

Use `hands-on.md` to practice blueprint inspection, off-chain serialization, and system design exercises, then tackle `challenge.md` to produce a small but realistic multi-validator architecture plan.
