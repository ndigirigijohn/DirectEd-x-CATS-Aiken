# Course overview

Use this document as the narrative guide for the DirectEd x CATS Hackathon Aiken Workshops. Each section summarises the intent of a module, highlights the main technical skills, and points you to the repositories you should explore once the lesson is complete.

## Program snapshot

- **Duration**: 9 Nov – 16 Dec 2025, twice-weekly 2‑hour sessions.
- **Audience**: Entry-level Cardano developers located across Abuja, Kigali, and Addis Ababa (self-paced learners can follow the same flow from GitHub).
- **Format**: First hour for concepts, second hour for hands-on work, demos, and Q&A.
- **Learning approach**: Review material before each session, complete the guided challenges afterwards, lean on provided examples, and bring questions to office hours or Discord.

## Support & success habits

- Weekly office hours (Discord) focus on code review, debugging, and architecture Q&A.
- Peer channels stay open for asynchronous troubleshooting and progress check-ins.
- Best practices: start early, code a little every day, document decisions, collaborate often, and read examples thoroughly before attempting new challenges.

## Recommended tooling

- Development: [Aiken](https://aiken-lang.org/), [VS Code](https://code.visualstudio.com/), [Git](https://git-scm.com/).
- Testing: [Vodka / Mocktail](https://github.com/sidan-lab/vodka), [Aiken stdlib](https://aiken-lang.github.io/stdlib/).
- Transaction building: [Mesh SDK](https://meshjs.dev/), [Lucid Evolution](https://anastasia-labs.github.io/lucid-evolution/).
- Documentation: [Cardano Developers](https://developers.cardano.org/), [Cardano CIPs](https://cips.cardano.org/).

## Completion outcomes

Finishing all eight modules and challenges means you will have:

- Set up a full Aiken smart-contract environment.
- Written, tested, and compiled multiple spending and minting validators.
- Built state machines plus NFT minting systems.
- Designed multi-validator DApp architectures and deployment plans.
- Documented schemas and integration details straight from the blueprint.
- Prepared a portfolio of Cardano projects ready for further iteration.

## How to read this file

- Start with the module you are currently studying and skim the summary to understand its scope.
- Check the “Projects and examples” references to see which repositories reinforce the topic.
- When you revisit a module, treat this file as the quick reminder of what the challenges should cover.

## M000 Foundations & setup

Kick off by learning the differences between Cardano’s EUTxO accounting model and account-based chains, how native assets behave, and why functional programming aligns well with on-chain validation. This module walks you through installing the Aiken toolchain, configuring VS Code, cloning the repositories in this monorepo, and running `aiken check` for the first time so the rest of the course has a solid environment to build on.

## M001 First validator

With the tools ready, you create the first spending and minting validators. The focus is on understanding validator type signatures, how datum and redeemer values flow through a transaction, how to write “always succeed” safety nets, and how to add meaningful tests. You conclude by compiling validators, inspecting the generated `plutus.json`, and deriving script addresses or policy IDs.

## M002 Mock transactions

Realistic tests require realistic transactions. This module shows how to assemble mock spending, locking, and minting transactions using Vodka/Mocktail helpers. You learn how to model inputs, outputs, signers, and minting values so that every validator is exercised with both success and failure cases before touching the blockchain.

## M003 Validation logic

Here you layer actual decision making into validators: matching redeemer constructors, comparing datum fields, verifying specific signatories, inspecting reference inputs, and enforcing validity intervals. The aim is to combine multiple checks so the validator reflects complete business rules rather than isolated conditions.

## M004 Input security

Inputs are a common source of vulnerabilities, so this module deep-dives into filtering transaction inputs by script address, extracting inline datums, verifying lovelace or token minimums, and preventing double-satisfaction attacks. You also learn reliable patterns for dealing with multi-asset values inside input inspection loops.

## M005 Outputs & state machines

Outputs finish the other half of the transaction story. After validating outputs by address and datum, you evolve the technique into a state machine: initialise state, transition through actions via redeemers, and close out safely. Typical examples include counters, governance flows, and vesting schedules—each driven by consistent input/output relationships.

## M006 Minting & NFTs

Switch gears to minting policies. You implement one-shot policies using `OutputReference`, design oracle/reference tokens for managing collection state, and build collection policies that mint NFTs with unique token names. Burn logic, quantity checks, and parameterised policies are covered so you can produce a complete NFT system.

## M007 Blueprints & DApps

The final module explains how compiled validators surface in `plutus.json`, how datum/redeemer schemas map to off-chain code, and how constructor indexes help transaction builders pick the right redeemer. You close the course by designing multi-validator DApp architectures, documenting parameters, and outlining deployment procedures for production readiness.

## Projects and examples

- `workshop-examples/` – Contains the validator code that mirrors each module. Because documentation stays inside the `.ak` files, read the comments as you study.
- `nft-workshop/` – Supplements Modules M002 and M006 with a Cardano CLI-based NFT minting workflow plus supporting notes.
- `vesting-example/` – Couples a Next.js interface with its Aiken validators to demonstrate the state-machine and blueprint concepts from Modules M005 and M007.

Use this outline together with the upcoming `modules/` directory to track progress, plan challenges, and connect each lesson with hands-on repositories.

