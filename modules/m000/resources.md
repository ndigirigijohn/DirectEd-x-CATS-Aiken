# Module M000 Resources

## Official docs
- Aiken installation: https://aiken-lang.org/installation-instructions
- Aiken language tour: https://aiken-lang.org/language-tour
- Aiken standard library: https://aiken-lang.github.io/stdlib/
- Cardano Developer Portal: https://developers.cardano.org/
- Cardano Improvement Proposals: https://cips.cardano.org/

## Commands & snippets
```bash
# Install aikup and latest Aiken
npm install -g @aiken-lang/aikup
aikup install latest

# Check versions
aiken --version
node --version
npm --version
git --version

# Create and explore a project
aiken new workshop-m000
cd workshop-m000
ls -la
code .

# Run tests
aiken check
aiken check -m math
```

## Troubleshooting quick notes
- **PATH issues** (Linux/macOS): add `export PATH=\"$HOME/.aiken/bin:$PATH\"` to your shell rc file and reload.
- **npm permission errors**: configure a user-level prefix (`npm config set prefix '~/.npm-global'`) instead of using sudo.
- **VS Code extension not activating**: ensure VS Code is up to date, reload the window, and open a `.ak` file to trigger activation.
- **Missing dependencies** inside example repos: run `aiken build` once to fetch packages before `aiken check`.

## Repo references
- `modules/m000/` – the content you’re reading now.
- `workshop-examples/validators/m000/` – canonical sample tests for this module.
- `nft-workshop/` & `vesting-example/` – ignore for now; they’re referenced later but useful if you want to confirm your environment can run larger projects.
