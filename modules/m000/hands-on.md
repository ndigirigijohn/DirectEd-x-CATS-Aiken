# Module M000 Hands-on

Follow these steps in order. Each one builds confidence that your workstation, editor, and Aiken installation behave exactly like the workshop environment.

## 1. Verify tooling

```bash
aiken --version
node --version
npm --version
git --version
```

- Confirm Aiken is ≥ the version used in the workshop (v1.1.7 at the time of writing).
- Node.js ≥ 16.x and npm ≥ 8.x keep `aikup` happy.
- If `aiken` is missing, revisit PATH instructions in `resources.md`.

## 2. Install the VS Code Aiken extension

1. Launch VS Code → Extensions (`Ctrl+Shift+X` / `Cmd+Shift+X`).
2. Search for “Aiken” and install the official extension.
3. Open any `.ak` file to confirm syntax highlighting, hints, and format-on-save.

## 3. Create a sandbox project

```bash
mkdir -p ~/cardano-dev
cd ~/cardano-dev
aiken new workshop-m000
cd workshop-m000
code .
```

- Inspect `aiken.toml`, `lib/`, and `validators/`.
- Note where tests live and how the project mirrors the repo structure later modules will use.

## 4. Write smoke tests

Create `validators/first.ak`:

```text
test always_true() { True }

test basic_math() {
  let x = 2
  let y = 2
  x + y == 4
}
```

Run `aiken check` and confirm both tests pass. Add at least one boolean test and one string equality test to explore the syntax.

## 5. Experiment with traces

Add to the same project:

```text
test with_trace() {
  trace @"Starting trace demo"
  let result = 5 * 5
  trace @"Result calculated"
  result == 25
}
```

Run only the trace-related tests:

```bash
aiken check -m with_trace
```

Observe how trace output helps debug intermediate values.

## 6. Organise multiple files

1. Create `validators/math.ak` with addition, subtraction, multiplication, and division tests.
2. Run the entire suite: `aiken check`.
3. Run only math tests: `aiken check -m math`.

This reinforces how to scope checks to a particular validator file or module.

## 7. Explore repository examples (optional)

```bash
cd ~/cardano-dev
git clone https://github.com/ndigirigijohn/DirectEd-x-CATS-Aiken
cd DirectEd-x-CATS-Aiken/workshop-examples
aiken check -m m000
```

Use these examples purely for reference; your personal sandbox project remains the place for experimentation.
