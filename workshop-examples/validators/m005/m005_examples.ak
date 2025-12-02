// =============================================================================
// Module M005 Workshop Examples
// Output Validation and State Machines
// =============================================================================

use aiken/collection/list
use cardano/assets.{from_lovelace, lovelace_of}
use cardano/transaction.{InlineDatum, Output, OutputReference, Transaction}
use cocktail.{outputs_at}
use mocktail.{
  complete, mock_script_address, mock_tx_hash, mock_utxo_ref, mocktail_tx, tx_in,
  tx_in_inline_datum, tx_out, tx_out_inline_datum,
}

// -----------------------------------------------------------------------------
// Example 1: Simple Counter (Exercise 1)
// Demonstrates: Basic state machine with increment operation
// -----------------------------------------------------------------------------

pub type CounterDatum {
  count: Int,
}

pub type CounterAction {
  Increment
}

validator simple_counter {
  spend(
    datum: Option<CounterDatum>,
    redeemer: CounterAction,
    _own_ref: OutputReference,
    self: Transaction,
  ) {
    // Get current state from input
    expect Some(current_state) = datum

    // Get continuing output to our script
    expect [output] = outputs_at(self.outputs, mock_script_address(0, None))

    // Extract new state from output
    expect InlineDatum(new_state_data) = output.datum
    expect new_state: CounterDatum = new_state_data

    // Validate state transition
    let Increment = redeemer
    new_state.count == current_state.count + 1
  }

  else(_) {
    fail
  }
}

// Tests for simple counter
test test_counter_increment_succeeds() {
  let current = CounterDatum { count: 5 }
  let new = CounterDatum { count: 6 }

  let tx =
    mocktail_tx()
      |> tx_in(
          True,
          mock_tx_hash(0),
          0,
          from_lovelace(10_000_000),
          mock_script_address(0, None),
        )
      |> tx_in_inline_datum(True, current)
      |> tx_out(True, mock_script_address(0, None), from_lovelace(10_000_000))
      |> tx_out_inline_datum(True, new)
      |> complete()

  simple_counter.spend(Some(current), Increment, mock_utxo_ref(0, 0), tx)
}

test test_counter_wrong_increment_fails() fail {
  let current = CounterDatum { count: 5 }
  let new = CounterDatum { count: 10 }

  // Wrong! Should be 6
  let tx =
    mocktail_tx()
      |> tx_in(
          True,
          mock_tx_hash(0),
          0,
          from_lovelace(10_000_000),
          mock_script_address(0, None),
        )
      |> tx_in_inline_datum(True, current)
      |> tx_out(True, mock_script_address(0, None), from_lovelace(10_000_000))
      |> tx_out_inline_datum(True, new)
      |> complete()

  simple_counter.spend(Some(current), Increment, mock_utxo_ref(0, 0), tx)
}

// -----------------------------------------------------------------------------
// Example 2: Voting System (Exercise 2)
// Demonstrates: Multi-field state machine with time constraints
// -----------------------------------------------------------------------------

pub type VotingDatum {
  yes_votes: Int,
  no_votes: Int,
  deadline: Int,
}

pub type VotingAction {
  VoteYes
  VoteNo
}

validator voting {
  spend(
    datum: Option<VotingDatum>,
    redeemer: VotingAction,
    _own_ref: OutputReference,
    self: Transaction,
  ) {
    expect Some(current_state) = datum

    // Get continuing output
    expect [output] = outputs_at(self.outputs, mock_script_address(0, None))

    expect InlineDatum(new_state_data) = output.datum
    expect new_state: VotingDatum = new_state_data

    when redeemer is {
      VoteYes -> and {
          // Time check would go here: is_before(self.validity_range, current_state.deadline)
          new_state.yes_votes == current_state.yes_votes + 1,
          new_state.no_votes == current_state.no_votes,
          new_state.deadline == current_state.deadline,
        }

      VoteNo -> and {
          new_state.yes_votes == current_state.yes_votes,
          new_state.no_votes == current_state.no_votes + 1,
          new_state.deadline == current_state.deadline,
        }
    }
  }

  else(_) {
    fail
  }
}

// Tests for voting
test test_vote_yes_succeeds() {
  let current = VotingDatum { yes_votes: 5, no_votes: 3, deadline: 1000 }
  let new = VotingDatum { yes_votes: 6, no_votes: 3, deadline: 1000 }

  let tx =
    mocktail_tx()
      |> tx_in(
          True,
          mock_tx_hash(0),
          0,
          from_lovelace(10_000_000),
          mock_script_address(0, None),
        )
      |> tx_in_inline_datum(True, current)
      |> tx_out(True, mock_script_address(0, None), from_lovelace(10_000_000))
      |> tx_out_inline_datum(True, new)
      |> complete()

  voting.spend(Some(current), VoteYes, mock_utxo_ref(0, 0), tx)
}

test test_vote_no_succeeds() {
  let current = VotingDatum { yes_votes: 5, no_votes: 3, deadline: 1000 }
  let new = VotingDatum { yes_votes: 5, no_votes: 4, deadline: 1000 }

  let tx =
    mocktail_tx()
      |> tx_in(
          True,
          mock_tx_hash(0),
          0,
          from_lovelace(10_000_000),
          mock_script_address(0, None),
        )
      |> tx_in_inline_datum(True, current)
      |> tx_out(True, mock_script_address(0, None), from_lovelace(10_000_000))
      |> tx_out_inline_datum(True, new)
      |> complete()

  voting.spend(Some(current), VoteNo, mock_utxo_ref(0, 0), tx)
}

test test_vote_yes_changes_deadline_fails() fail {
  let current = VotingDatum { yes_votes: 5, no_votes: 3, deadline: 1000 }
  let new = VotingDatum { yes_votes: 6, no_votes: 3, deadline: 2000 }

  // Changed deadline!
  let tx =
    mocktail_tx()
      |> tx_in(
          True,
          mock_tx_hash(0),
          0,
          from_lovelace(10_000_000),
          mock_script_address(0, None),
        )
      |> tx_in_inline_datum(True, current)
      |> tx_out(True, mock_script_address(0, None), from_lovelace(10_000_000))
      |> tx_out_inline_datum(True, new)
      |> complete()

  voting.spend(Some(current), VoteYes, mock_utxo_ref(0, 0), tx)
}

// -----------------------------------------------------------------------------
// Example 3: Token Accumulator (Exercise 3)
// Demonstrates: Value tracking alongside state changes
// -----------------------------------------------------------------------------

pub type AccumulatorDatum {
  owner: ByteArray,
  total_accumulated: Int,
}

pub type AccumulatorAction {
  Deposit { amount: Int }
}

validator accumulator {
  spend(
    datum: Option<AccumulatorDatum>,
    redeemer: AccumulatorAction,
    own_ref: OutputReference,
    self: Transaction,
  ) {
    expect Some(current_state) = datum

    // Get input value
    expect Some(own_input) =
      list.find(self.inputs, fn(input) { input.output_reference == own_ref })
    let input_lovelace = lovelace_of(own_input.output.value)

    // Get continuing output
    expect [output] = outputs_at(self.outputs, mock_script_address(0, None))

    expect InlineDatum(new_state_data) = output.datum
    expect new_state: AccumulatorDatum = new_state_data

    let output_lovelace = lovelace_of(output.value)

    // Extract amount from redeemer
    let Deposit { amount } = redeemer

    and {
      // State updated
      new_state.total_accumulated == current_state.total_accumulated + amount,
      // Value increased
      output_lovelace == input_lovelace + amount,
      // Owner preserved
      new_state.owner == current_state.owner,
    }
  }

  else(_) {
    fail
  }
}

// Tests for accumulator
test test_accumulator_deposit_succeeds() {
  let current =
    AccumulatorDatum { owner: #"aabbcc", total_accumulated: 10_000_000 }
  let new = AccumulatorDatum { owner: #"aabbcc", total_accumulated: 15_000_000 }

  let tx =
    mocktail_tx()
      |> tx_in(
          True,
          mock_tx_hash(0),
          0,
          from_lovelace(10_000_000),
          mock_script_address(0, None),
        )
      |> tx_in_inline_datum(True, current)
      |> tx_out(True, mock_script_address(0, None), from_lovelace(15_000_000))
      |> tx_out_inline_datum(True, new)
      |> complete()

  accumulator.spend(
    Some(current),
    Deposit { amount: 5_000_000 },
    mock_utxo_ref(0, 0),
    tx,
  )
}

test test_accumulator_value_mismatch_fails() fail {
  let current =
    AccumulatorDatum { owner: #"aabbcc", total_accumulated: 10_000_000 }
  let new = AccumulatorDatum { owner: #"aabbcc", total_accumulated: 15_000_000 }

  let tx =
    mocktail_tx()
      |> tx_in(
          True,
          mock_tx_hash(0),
          0,
          from_lovelace(10_000_000),
          mock_script_address(0, None),
        )
      |> tx_in_inline_datum(True, current)
      // Value doesn't match state!
      |> tx_out(True, mock_script_address(0, None), from_lovelace(12_000_000))
      |> tx_out_inline_datum(True, new)
      |> complete()

  accumulator.spend(
    Some(current),
    Deposit { amount: 5_000_000 },
    mock_utxo_ref(0, 0),
    tx,
  )
}

test test_accumulator_owner_change_fails() fail {
  let current =
    AccumulatorDatum { owner: #"aabbcc", total_accumulated: 10_000_000 }
  let new = AccumulatorDatum { owner: #"ddeeff", total_accumulated: 15_000_000 }

  // Owner changed!
  let tx =
    mocktail_tx()
      |> tx_in(
          True,
          mock_tx_hash(0),
          0,
          from_lovelace(10_000_000),
          mock_script_address(0, None),
        )
      |> tx_in_inline_datum(True, current)
      |> tx_out(True, mock_script_address(0, None), from_lovelace(15_000_000))
      |> tx_out_inline_datum(True, new)
      |> complete()

  accumulator.spend(
    Some(current),
    Deposit { amount: 5_000_000 },
    mock_utxo_ref(0, 0),
    tx,
  )
}

// -----------------------------------------------------------------------------
// Example 4: Multi-Stage State Machine (Exercise 4)
// Demonstrates: Complex state transitions with multiple stages
// -----------------------------------------------------------------------------

pub type TaskStatus {
  Created
  Assigned
  Completed
}

pub type TaskDatum {
  creator: ByteArray,
  assignee: Option<ByteArray>,
  status: TaskStatus,
  reward: Int,
}

pub type TaskAction {
  Assign { worker: ByteArray }
  Complete
}

validator task_manager {
  spend(
    datum: Option<TaskDatum>,
    redeemer: TaskAction,
    _own_ref: OutputReference,
    self: Transaction,
  ) {
    expect Some(current_state) = datum

    // Get continuing output
    expect [output] = outputs_at(self.outputs, mock_script_address(0, None))

    expect InlineDatum(new_state_data) = output.datum
    expect new_state: TaskDatum = new_state_data

    when redeemer is {
      Assign { worker } ->
        when current_state.status is {
          Created -> and {
              new_state.status == Assigned,
              new_state.assignee == Some(worker),
              new_state.creator == current_state.creator,
              new_state.reward == current_state.reward,
            }
          _ -> False
        }

      Complete ->
        when current_state.status is {
          Assigned -> and {
              new_state.status == Completed,
              // In real implementation, would check payment to assignee
              new_state.assignee == current_state.assignee,
              new_state.creator == current_state.creator,
            }
          _ -> False
        }
    }
  }

  else(_) {
    fail
  }
}

// Tests for task manager
test test_task_assign_succeeds() {
  let current =
    TaskDatum {
      creator: #"aabbccdd",
      assignee: None,
      status: Created,
      reward: 10_000_000,
    }
  let new =
    TaskDatum {
      creator: #"aabbccdd",
      assignee: Some(#"eeff0011"),
      status: Assigned,
      reward: 10_000_000,
    }

  let tx =
    mocktail_tx()
      |> tx_in(
          True,
          mock_tx_hash(0),
          0,
          from_lovelace(10_000_000),
          mock_script_address(0, None),
        )
      |> tx_in_inline_datum(True, current)
      |> tx_out(True, mock_script_address(0, None), from_lovelace(10_000_000))
      |> tx_out_inline_datum(True, new)
      |> complete()

  task_manager.spend(
    Some(current),
    Assign { worker: #"eeff0011" },
    mock_utxo_ref(0, 0),
    tx,
  )
}

test test_task_complete_succeeds() {
  let current =
    TaskDatum {
      creator: #"aabbccdd",
      assignee: Some(#"eeff0011"),
      status: Assigned,
      reward: 10_000_000,
    }
  let new =
    TaskDatum {
      creator: #"aabbccdd",
      assignee: Some(#"eeff0011"),
      status: Completed,
      reward: 10_000_000,
    }

  let tx =
    mocktail_tx()
      |> tx_in(
          True,
          mock_tx_hash(0),
          0,
          from_lovelace(10_000_000),
          mock_script_address(0, None),
        )
      |> tx_in_inline_datum(True, current)
      |> tx_out(True, mock_script_address(0, None), from_lovelace(10_000_000))
      |> tx_out_inline_datum(True, new)
      |> complete()

  task_manager.spend(Some(current), Complete, mock_utxo_ref(0, 0), tx)
}

test test_task_complete_from_created_fails() fail {
  let current =
    TaskDatum {
      creator: #"aabbccdd",
      assignee: None,
      status: Created,
      reward: 10_000_000,
    }
  let new =
    TaskDatum {
      creator: #"aabbccdd",
      assignee: None,
      status: Completed,
      reward: 10_000_000,
    }

  let tx =
    mocktail_tx()
      |> tx_in(
          True,
          mock_tx_hash(0),
          0,
          from_lovelace(10_000_000),
          mock_script_address(0, None),
        )
      |> tx_in_inline_datum(True, current)
      |> tx_out(True, mock_script_address(0, None), from_lovelace(10_000_000))
      |> tx_out_inline_datum(True, new)
      |> complete()

  // Can't go from Created directly to Completed!
  task_manager.spend(Some(current), Complete, mock_utxo_ref(0, 0), tx)
}
// =============================================================================
// Summary:
// 
// These examples demonstrate:
// 1. Simple counter state machine with increment operation
// 2. Voting system with multi-field state and field preservation
// 3. Token accumulator tracking both state and value changes
// 4. Multi-stage state machine with status transitions
// 
// Key State Machine Patterns:
// - Extract input datum (current state)
// - Extract output datum (new state)
// - Validate state transition based on action
// - Preserve unchanging fields
// - Track value changes alongside state changes
// 
// Test Results:
// - All valid state transitions pass
// - Invalid transitions fail
// - Field preservation enforced
// - Value conservation validated
// =============================================================================
