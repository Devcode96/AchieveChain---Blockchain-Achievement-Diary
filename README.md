# AchieveChain - Blockchain Achievement Diary

A decentralized achievement tracking system that securely records and verifies student progress on the blockchain.

## Features

- Immutable achievement recording
- Trusted verifier system for achievement validation
- Student achievement history tracking
- Timestamped progress milestones

## Smart Contract Functions

### Public Functions

- `record-achievement` - Record a new student achievement
- `verify-achievement` - Verify an achievement (verifiers only)
- `add-verifier` - Add trusted verifier (owner only)

### Read-Only Functions

- `get-achievement` - Retrieve achievement details
- `get-student-achievements` - Get all achievements for a student
- `is-verifier` - Check verifier status
- `get-achievement-count` - Get total achievements recorded

## Usage

Students record their achievements on-chain, and authorized verifiers can validate them to create a trustworthy progress diary.

## Technology Stack

- Stacks Blockchain
- Clarity Smart Contracts