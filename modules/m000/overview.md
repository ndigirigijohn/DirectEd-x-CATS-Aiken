# Module M000 – Foundations & Setup

**Goal**  
Understand Cardano’s extended UTxO (EUTxO) model and prepare a complete Aiken development workstation so every later module can focus on contracts instead of tooling.

**Key skills**
- Compare EUTxO and account-based accounting models and explain how native assets fit into UTxOs.
- Navigate Cardano documentation (CIPs, developer portal, wallet references) to answer architectural questions.
- Install Aiken with `aikup`, configure VS Code extensions, and verify your toolchain.
- Clone this repository, inspect the folder structure, and run `aiken check` in at least one example.
- Capture environment notes so you can reproduce the setup on another machine.

**Practice focus**
1. Follow the platform setup checklist in `hands-on.md`—package manager, git, VS Code, `aiken`.
2. Configure editor support (syntax highlighting, formatter, linting) and test that diagnostics fire on a sample validator.
3. Run `aikup` to install dependencies, then execute `aiken check` inside `workshop-examples/validators/m000`.
4. Record wallet, CLI, and cardano-node references you might reuse later.

**Move on when**
- You can articulate the difference between inputs/outputs in EUTxO and balances in an account model.
- Aiken commands run without errors and VS Code recognises `.ak` files.
- You have a local clone of this repository plus any required environment variables written down.

**Next steps**  
Continue with the guided exercises in `hands-on.md`, then attempt the `challenge.md` task once your toolchain feels reliable.
