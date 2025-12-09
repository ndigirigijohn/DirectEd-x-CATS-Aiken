# Module M003 – Validation Logic

**Goal**  
Move beyond “always succeed” validators by adding real business logic that inspects redeemers, datums, signatures, reference inputs, and time windows.

**Key skills**
- Pattern-match on redeemer constructors and compare datum fields.
- Parameterise validators so you can reuse logic with different constants.
- Look up required signatories (`tx.required_signers`) and enforce access control.
- Read validity intervals and POSIX times to restrict when transactions may execute.
- Combine multiple checks into clear helper functions that fail with meaningful messages.

**Practice focus**
1. Start with a working validator from Module M001 and identify the rules it should enforce.
2. Implement helper functions for datum/redeemer validation, signature checks, and optional reference inputs.
3. Add guard clauses around validity ranges or slot-based windows.
4. Expand the associated tests so each rule is proven independently before combining them.

**Move on when**
- You can explain which pieces of `tx` are available to the validator and how to query them safely.
- Validators remain readable even after adding multiple checks (helpers, descriptive errors).
- Tests fail for the right reason whenever you tweak datum, redeemer, signatures, or time.

**Next steps**  
Use `hands-on.md` to layer these patterns step by step, then complete the scenario in `challenge.md` to create a fully validated contract.
