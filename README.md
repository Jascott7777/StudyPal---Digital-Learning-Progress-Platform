# StudyPal - Digital Learning Progress Platform

A blockchain-based platform built on Stacks that connects students through subject tracking, study session logging, note sharing, and academic community rewards.

## Overview

StudyPal is a decentralized application that rewards students for engaging in productive study habits by logging study sessions, sharing notes, and achieving academic milestones. The platform issues **Learning Tokens (SPT)** as rewards for educational engagement and community contribution.

## Features

### 📚 Core Functionality

- **Student Profiles**: Personalized profiles tracking username, study field, subjects studied, study sessions, notes shared, and student level
- **Subject Registry**: Community-curated database of subjects across various categories with difficulty ratings
- **Study Session Logging**: Track your study sessions with duration, focus ratings, and productivity metrics
- **Note Sharing System**: Share and discover study notes with voting system for helpfulness
- **Milestone System**: Earn special rewards for reaching academic milestones
- **SPT Token Rewards**: Get rewarded for study engagement with blockchain-based tokens

### 🪙 Token Economics

**Token Details:**
- Name: StudyPal Learning Token
- Symbol: SPT
- Decimals: 6
- Max Supply: 45,000 SPT

**Reward Structure:**
- **Study Session**: 1.8 SPT per session
- **Note Sharing**: 2.2 SPT per note contribution
- **Milestone Achievement**: 9.0 SPT per milestone

## Smart Contract Functions

### Public Functions

#### Profile Management

##### `update-username`
```clarity
(update-username (new-username (string-ascii 24)))
```
Update your student username.

##### `update-study-field`
```clarity
(update-study-field (new-study-field (string-ascii 16)))
```
Set your study field: "science", "math", "history", "language", or "arts".

#### Subject Management

##### `add-subject`
```clarity
(add-subject 
  (subject-name (string-ascii 32))
  (subject-category (string-ascii 16))
  (difficulty-level uint))
```
Add a new subject to the registry.

**Parameters:**
- `subject-name`: Name of the subject (max 32 chars)
- `subject-category`: Category classification (max 16 chars)
- `difficulty-level`: Difficulty rating from 1-5

**Returns**: Subject ID (uint)

#### Study Session Logging

##### `log-study-session`
```clarity
(log-study-session
  (subject-id uint)
  (session-duration uint)
  (focus-rating uint)
  (session-notes (string-ascii 128)))
```
Log a study session for a specific subject.

**Parameters:**
- `subject-id`: ID of the subject being studied
- `session-duration`: Duration in minutes
- `focus-rating`: Focus quality from 1-10 (≥6 marks session as productive)
- `session-notes`: Session description or key learnings (max 128 chars)

**Rewards**: 1.8 SPT per session

**Additional Effects:**
- Increases student level based on duration and focus
- Updates total study hours for the subject
- Marks session as productive if focus-rating ≥ 6
- Increments total study session count

#### Note Sharing

##### `share-notes`
```clarity
(share-notes
  (subject-id uint)
  (note-title (string-ascii 48))
  (note-content (string-ascii 256))
  (note-type (string-ascii 12)))
```
Share study notes for a subject.

**Parameters:**
- `subject-id`: Subject the notes relate to
- `note-title`: Title of the notes (max 48 chars)
- `note-content`: Note content (max 256 chars)
- `note-type`: "summary", "formula", "concept", or "example"

**Rewards**: 2.2 SPT per note

**Notes**: Each student can only share one note per subject.

##### `vote-helpful-notes`
```clarity
(vote-helpful-notes (subject-id uint) (note-author principal))
```
Vote notes as helpful. Cannot vote on your own notes.

#### Milestones

##### `claim-milestone`
```clarity
(claim-milestone (milestone (string-ascii 12)))
```
Claim a milestone achievement and receive bonus tokens.

**Available Milestones:**
- `"studious-15"`: Complete 15 study sessions
- `"helper-8"`: Share 8 sets of notes

**Rewards**: 9.0 SPT per milestone

### Read-Only Functions

##### `get-student-profile`
```clarity
(get-student-profile (student principal))
```
Retrieve a student's profile information.

##### `get-subject`
```clarity
(get-subject (subject-id uint))
```
Get details about a specific subject.

##### `get-study-session`
```clarity
(get-study-session (session-id uint))
```
Retrieve information about a logged study session.

##### `get-study-notes`
```clarity
(get-study-notes (subject-id uint) (note-author principal))
```
Get study notes for a subject by a specific author.

##### `get-milestone`
```clarity
(get-milestone (student principal) (milestone (string-ascii 12)))
```
Check if a student has claimed a specific milestone.

##### Token Functions
- `get-name`: Returns token name
- `get-symbol`: Returns token symbol
- `get-decimals`: Returns token decimals
- `get-balance`: Returns token balance for a user

## Data Structures

### Student Profile
```clarity
{
  username: (string-ascii 24),
  study-field: (string-ascii 16),
  subjects-studied: uint,
  study-sessions: uint,
  notes-shared: uint,
  student-level: uint,
  join-date: uint
}
```

### Subject Registry
```clarity
{
  subject-name: (string-ascii 32),
  subject-category: (string-ascii 16),
  difficulty-level: uint,
  study-hours-logged: uint,
  creator: principal,
  active: bool,
  notes-count: uint
}
```

### Study Session
```clarity
{
  subject-id: uint,
  student: principal,
  session-duration: uint,
  focus-rating: uint,
  session-notes: (string-ascii 128),
  session-date: uint,
  productive: bool
}
```

### Study Notes
```clarity
{
  note-title: (string-ascii 48),
  note-content: (string-ascii 256),
  note-type: (string-ascii 12),
  helpful-votes: uint,
  note-date: uint
}
```

## Error Codes

- `u100`: Owner only operation
- `u101`: Resource not found
- `u102`: Resource already exists
- `u103`: Unauthorized operation
- `u104`: Invalid input

## Usage Examples

### Adding a Subject
```clarity
(contract-call? .studypal add-subject
  "Calculus I"
  "math"
  u4)
```

### Logging a Study Session
```clarity
(contract-call? .studypal log-study-session
  u1
  u90
  u8
  "Covered derivatives and chain rule. Made good progress!")
```

### Sharing Notes
```clarity
(contract-call? .studypal share-notes
  u1
  "Derivative Rules Cheat Sheet"
  "Power rule: d/dx[x^n] = nx^(n-1). Product rule: d/dx[uv] = u'v + uv'. Chain rule: d/dx[f(g(x))] = f'(g(x))g'(x)"
  "formula")
```

### Voting on Notes
```clarity
(contract-call? .studypal vote-helpful-notes
  u1
  'ST1PQHQKV0RJXZFY1DGX8MNSNYVE3VGZJSRTPGZGM)
```

### Claiming a Milestone
```clarity
(contract-call? .studypal claim-milestone "studious-15")
```

## Educational Features

### Study Tracking
- **Duration tracking**: Monitors time spent studying
- **Focus ratings**: Self-assessment of study quality (1-10 scale)
- **Productivity markers**: Sessions with focus ≥6 marked as productive
- **Subject hours**: Aggregates total study time per subject

### Gamification Elements
- **Student levels**: Progress based on study duration and focus
- **Milestones**: Achievements for consistent study and note sharing
- **Token rewards**: Economic incentives for educational engagement
- **Helpful votes**: Community recognition for quality notes

### Knowledge Sharing
- **Note categories**: Summary, formula, concept, or example
- **Quality voting**: Community-driven helpfulness ratings
- **One note per subject**: Encourages quality over quantity
- **Subject-organized**: Notes linked to specific subjects

## Development

### Prerequisites
- Clarity CLI
- Stacks blockchain node (for deployment)

### Testing
Test the contract using the Clarity REPL or Clarinet testing framework.

### Testing Focus Areas
- Profile creation and updates
- Subject creation with valid difficulty levels
- Study session logging with various focus ratings
- Note sharing and duplicate prevention
- Helpful voting system
- Milestone requirement validation
- Student level progression algorithm
- Token minting and supply cap
- Edge cases (invalid inputs, inactive subjects, etc.)

### Deployment
Deploy to Stacks mainnet or testnet using the Stacks CLI.

## Use Cases

### For Students
- Track study habits and time investment
- Share and discover study resources
- Earn rewards for consistent learning
- Build verifiable academic engagement record
- Access community-contributed notes

### For Study Groups
- Coordinate subject coverage
- Share specialized notes
- Track collective progress
- Recognize top contributors

### For Educational Institutions
- Monitor student engagement (with consent)
- Identify popular subjects
- Recognize consistent learners
- Build decentralized knowledge base

## Best Practices

### For Effective Use
1. **Log sessions honestly**: Accurate focus ratings help track true progress
2. **Quality notes**: Focus on creating helpful, well-organized notes
3. **Regular engagement**: Consistent sessions build momentum toward milestones
4. **Diverse subjects**: Explore different areas to broaden knowledge
5. **Vote thoughtfully**: Help surface the most valuable notes

### For Community Building
- Review and vote on shared notes
- Add subjects in your areas of expertise
- Share detailed, actionable notes
- Maintain accurate subject difficulty ratings

## Contributing

Contributions are welcome! Areas for improvement:
- Additional milestone types (streak tracking, expertise levels)
- Study group/collaborative features
- Flashcard integration
- Quiz/assessment system
- Study schedule planning
- Peer review system for notes
- Subject prerequisites and learning paths
- Progress analytics and insights
- External resource linking (IPFS for documents)

## Privacy Considerations

All data stored on-chain is public. Consider:
- Usernames are public and permanent
- Study habits are visible to all users
- Note content is fully public
- Use pseudonymous wallets if privacy is a concern

## Comparison with Traditional Learning Platforms

**Advantages:**
- Transparent reward system
- Immutable study record
- No central authority controlling data
- True ownership of contributions
- Economic incentives for participation

**Considerations:**
- All data is public
- Gas fees for transactions
- Requires crypto wallet
- Limited data storage (on-chain constraints)

## License

[Add your license here]

## Community

Join the learning revolution on the blockchain! 📚⛓️

---

*Study hard, share knowledge, grow together!*
