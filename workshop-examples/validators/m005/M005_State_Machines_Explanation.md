# Module M005: State Machines - Code Explanation

## What is a State Machine?

A **state machine** is a validator that tracks changing state over time using the input-output pattern. The current state lives in the input UTxO's datum, and the new state is created in the output UTxO's datum.

**The Pattern:**
```
Input UTxO (State A) → Validator → Output UTxO (State B)
```

The validator ensures the transition from State A to State B follows the rules.

---

## Example 1: Simple Counter

### Code Purpose
Implements a basic counter that can only increment by 1 at a time.

### How It Works
1. **Current State**: Reads `count` from input datum (e.g., `count: 5`)
2. **New State**: Reads `count` from output datum (e.g., `count: 6`)
3. **Validation**: Ensures `new_state.count == current_state.count + 1`

### Real-World Use Cases
- **Donation Tracker**: Track total number of donations to a charity
- **Ticket Counter**: Count tickets sold for an event (one transaction = one ticket)
- **Achievement System**: Track progress milestones (level 1, level 2, etc.)
- **Visit Counter**: Track number of times a service is accessed

### Key Code Snippet
```aiken
// Validate state transition
let Increment = redeemer
new_state.count == current_state.count + 1
```

---

## Example 2: Voting System

### Code Purpose
Manages a voting system with separate yes/no tallies and an unchanging deadline.

### How It Works
1. **State Fields**: `yes_votes`, `no_votes`, `deadline`
2. **Actions**: `VoteYes` increments yes_votes, `VoteNo` increments no_votes
3. **Validation**: Ensures only the correct counter increments and deadline never changes

### Real-World Use Cases
- **DAO Governance**: Community votes on proposals
- **Product Polls**: Users vote on feature requests
- **Election System**: Track votes for candidates
- **Survey Platform**: Collect yes/no responses
- **Approval Process**: Stakeholders approve/reject decisions

### Key Code Snippet
```aiken
VoteYes -> and {
  new_state.yes_votes == current_state.yes_votes + 1,
  new_state.no_votes == current_state.no_votes,  // Unchanged
  new_state.deadline == current_state.deadline,  // Must preserve
}
```

**Security Pattern**: Always validate that unchanging fields (like `deadline`) stay the same!

---

## Example 3: Token Accumulator

### Code Purpose
Tracks accumulated deposits while ensuring the actual ADA value matches the datum state.

### How It Works
1. **State + Value**: Both `total_accumulated` in datum AND actual lovelace in UTxO must increase
2. **Validation**: Ensures state change matches value change: `output_value == input_value + amount`
3. **Owner Protection**: The `owner` field must never change

### Real-World Use Cases
- **Savings Contract**: Accumulate deposits over time before withdrawal
- **Escrow Service**: Track funds held for a transaction
- **Prize Pool**: Accumulate entry fees for a competition
- **Treasury**: Track organization's accumulated funds
- **Staking Rewards**: Accumulate rewards before claiming

### Key Code Snippet
```aiken
let Deposit { amount } = redeemer

and {
  // State updated correctly
  new_state.total_accumulated == current_state.total_accumulated + amount,
  // Value matches state
  output_lovelace == input_lovelace + amount,
  // Owner never changes
  new_state.owner == current_state.owner,
}
```

**Critical Pattern**: Always validate that value changes match state changes!

---

## Example 4: Multi-Stage Task Manager

### Code Purpose
Manages tasks through distinct lifecycle stages: Created → Assigned → Completed

### How It Works
1. **Status Enum**: `Created | Assigned | Completed`
2. **State Transitions**: 
   - `Assign`: Only works from `Created`, sets assignee
   - `Complete`: Only works from `Assigned`, marks completed
3. **Validation**: Prevents invalid transitions (e.g., Created → Completed)

### Real-World Use Cases
- **Freelance Marketplace**: Job posting → worker assigned → work completed
- **Supply Chain**: Ordered → Shipped → Delivered
- **Support Tickets**: Open → In Progress → Resolved
- **Content Workflow**: Draft → Review → Published
- **Loan Process**: Applied → Approved → Disbursed

### Key Code Snippet
```aiken
Assign { worker } ->
  when current_state.status is {
    Created -> and {
      new_state.status == Assigned,
      new_state.assignee == Some(worker),
      // Preserve other fields...
    }
    _ -> False  // Can't assign if not Created
  }
```

**Workflow Pattern**: Use nested `when` to enforce valid transitions based on current state.

---

## Critical Security Patterns

### 1. Field Preservation
Always validate that unchanging fields stay the same:
```aiken
and {
  new_state.owner == current_state.owner,
  new_state.deadline == current_state.deadline,
}
```

### 2. Value Conservation
When state tracks value, ensure they match:
```aiken
output_value == input_value + deposit_amount
```

### 3. Valid Transitions Only
Use state checks to prevent invalid transitions:
```aiken
when current_state.status is {
  Created -> // Only allow certain actions
  Assigned -> // Only allow certain actions
  _ -> False
}
```

---

## Testing Strategy

Each example includes three types of tests:

1. **✅ Valid Transitions**: Correct state changes pass
2. **❌ Invalid Changes**: Wrong state changes fail
3. **❌ Field Tampering**: Attempts to change protected fields fail

**Example Test Pattern:**
```aiken
test test_vote_yes_changes_deadline_fails() fail {
  let current = VotingDatum { yes_votes: 5, no_votes: 3, deadline: 1000 }
  let new = VotingDatum { yes_votes: 6, no_votes: 3, deadline: 2000 }  // Changed!
  
  // This should fail because deadline changed
  voting.spend(Some(current), VoteYes, ...)
}
```

---

## Common Mistakes to Avoid

1. **Forgetting Field Preservation**: Always check that constant fields don't change
2. **Value-State Mismatch**: When tracking value in state, validate both change together
3. **Missing Transition Guards**: Don't allow actions in wrong states
4. **Single-When Clauses**: Use `let` binding instead of `when` with one clause

---

## Quick Reference

| Pattern | When to Use | Example |
|---------|-------------|---------|
| **Simple Counter** | Track incrementing values | Visitor count, donation count |
| **Multi-Field State** | Multiple changing values | Voting, polls, statistics |
| **Value Tracking** | State must match UTxO value | Savings, escrow, treasury |
| **Status Transitions** | Multi-stage workflows | Tasks, orders, tickets |

---

## Next Steps

After mastering these patterns, you can combine them to build complex DApps:
- **Vesting Contract**: Time-based + value tracking + state transitions
- **Auction System**: Bidding state + value validation + deadline enforcement  
- **Crowdfunding**: Accumulator + goal tracking + time constraints
- **Multi-Sig Wallet**: Owner preservation + approval counting + state transitions

**Remember**: State machines are the foundation of sophisticated smart contracts on Cardano! 🚀
