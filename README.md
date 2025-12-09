# DirectEd x CATS Hackathon Aiken Development Workshops

This repository hosts the self-paced version of the DirectEd x CATS Hackathon Aiken curriculum. It collects the original workshop notes, runnable validator examples, and end-to-end reference projects so learners can progress through the material entirely from GitHub.

## Repository layout

- `modules/` – destination for the simplified markdown lessons (to be populated in upcoming steps).
- `module-content-txts/` – original workshop scripts. Use these while the migration into `modules/` is in progress.
- `workshop-examples/` – pure Aiken validators organised by module. Documentation lives inside the source files as code comments.
- `nft-workshop/` – CLI-driven NFT walkthrough that supports the minting-focused lessons.
- `vesting-example/` – full-stack vesting reference made of a Next.js UI and matching Aiken smart contracts.
- `COURSE.md` – narrative syllabus that summarises every module and points to the most relevant repositories.
- `deploying-cardano-sc/` and other docs – supplementary guides that will eventually move under `docs/`.

## How to navigate the course

1. Read `COURSE.md` to understand the sequencing, tooling expectations, and which example repositories accompany each module.
2. Open the relevant module in `modules/` (or temporarily `module-content-txts/`) and follow the `overview.md` → `hands-on.md` → `challenge.md` flow.
3. Jump into `workshop-examples/` to compile and test the validators discussed in each lesson (`aiken check` works per module folder).
4. Use `nft-workshop/` and `vesting-example/` for larger build-along experiences once you reach the minting and DApp architecture modules.
5. Keep your own notes or solutions inside new branches; the repository is organised so each module can be version-controlled independently.

## Module roadmap

| Module | Focus |
| ------ | ----- |
| [M000 Foundations & setup](COURSE.md#m000-foundations--setup) | Cardano concepts, UTxO vs account model, Aiken tooling, first checks. |
| [M001 First validator](COURSE.md#m001-first-validator) | Anatomy of spending/minting validators, tests, script addresses. |
| [M002 Mock transactions](COURSE.md#m002-mock-transactions) | Building realistic mock transactions to exercise validators. |
| [M003 Validation logic](COURSE.md#m003-validation-logic) | Implementing datum/redeemer checks, signatures, time windows. |
| [M004 Input security](COURSE.md#m004-input-security) | Hardening inputs: double satisfaction, minimum values, datums. |
| [M005 Outputs & state machines](COURSE.md#m005-outputs--state-machines) | Output validation plus building state-machine style contracts. |
| [M006 Minting & NFTs](COURSE.md#m006-minting--nfts) | One-shot policies, oracle tokens, NFT collection patterns. |
| [M007 Blueprints & DApps](COURSE.md#m007-blueprints--dapps) | Blueprint interpretation, schema docs, full DApp architecture. |

## Projects and examples

- `workshop-examples/` – fastest place to experiment with validators per module. Each file contains inline explanations instead of separate docs.
- `nft-workshop/` – extends Modules M002 and M006 by walking through CLI minting flows and on-chain/off-chain coordination.
- `vesting-example/` – pairs a Next.js app with its Aiken contracts to illustrate how Modules M005 and M007 translate into production code.

## Next steps for contributors

- Convert every `.txt` under `module-content-txts/` into simplified markdown under `modules/`.
- Keep documentation for examples inside code comments so validators stay the single source of truth.
- Use `COURSE.md` whenever you need to tweak module descriptions or cross-links—README intentionally stays concise.

Happy building! The issues tab will be used to track migration progress and collect feedback from self-paced learners.

