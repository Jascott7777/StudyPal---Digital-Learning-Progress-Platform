;; StudyPal - Digital Learning Progress Platform
;; A blockchain-based platform for study sessions, note sharing,
;; and academic community rewards

;; Contract constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-already-exists (err u102))
(define-constant err-unauthorized (err u103))
(define-constant err-invalid-input (err u104))

;; Token constants
(define-constant token-name "StudyPal Learning Token")
(define-constant token-symbol "SPT")
(define-constant token-decimals u6)
(define-constant token-max-supply u45000000000) ;; 45k tokens with 6 decimals

;; Reward amounts (in micro-tokens)
(define-constant reward-study u1800000) ;; 1.8 SPT
(define-constant reward-notes u2200000) ;; 2.2 SPT
(define-constant reward-milestone u9000000) ;; 9 SPT

;; Data variables
(define-data-var total-supply uint u0)
(define-data-var next-subject-id uint u1)
(define-data-var next-session-id uint u1)

;; Token balances
(define-map token-balances principal uint)

;; Student profiles
(define-map student-profiles
  principal
  {
    username: (string-ascii 24),
    study-field: (string-ascii 16), ;; "science", "math", "history", "language", "arts"
    subjects-studied: uint,
    study-sessions: uint,
    notes-shared: uint,
    student-level: uint, ;; 1-5
    join-date: uint
  }
)

;; Subject registry
(define-map subject-registry
  uint
  {
    subject-name: (string-ascii 32),
    subject-category: (string-ascii 16),
    difficulty-level: uint, ;; 1-5
    study-hours-logged: uint,
    creator: principal,
    active: bool,
    notes-count: uint
  }
)

;; Study sessions
(define-map study-sessions
  uint
  {
    subject-id: uint,
    student: principal,
    session-duration: uint, ;; minutes
    focus-rating: uint, ;; 1-10
    session-notes: (string-ascii 128),
    session-date: uint,
    productive: bool
  }
)

;; Study notes
(define-map study-notes
  { subject-id: uint, note-author: principal }
  {
    note-title: (string-ascii 48),
    note-content: (string-ascii 256),
    note-type: (string-ascii 12), ;; "summary", "formula", "concept", "example"
    helpful-votes: uint,
    note-date: uint
  }
)

;; Student milestones
(define-map student-milestones
  { student: principal, milestone: (string-ascii 12) }
  {
    achievement-date: uint,
    study-hours: uint
  }
)

;; Helper function to get or create profile
(define-private (get-or-create-profile (student principal))
  (match (map-get? student-profiles student)
    profile profile
    {
      username: "",
      study-field: "science",
      subjects-studied: u0,
      study-sessions: u0,
      notes-shared: u0,
      student-level: u1,
      join-date: stacks-block-height
    }
  )
)

;; Token functions
(define-read-only (get-name)
  (ok token-name)
)

(define-read-only (get-symbol)
  (ok token-symbol)
)

(define-read-only (get-decimals)
  (ok token-decimals)
)

(define-read-only (get-balance (user principal))
  (ok (default-to u0 (map-get? token-balances user)))
)

(define-private (mint-tokens (recipient principal) (amount uint))
  (let (
    (current-balance (default-to u0 (map-get? token-balances recipient)))
    (new-balance (+ current-balance amount))
    (new-total-supply (+ (var-get total-supply) amount))
  )
    (asserts! (<= new-total-supply token-max-supply) err-invalid-input)
    (map-set token-balances recipient new-balance)
    (var-set total-supply new-total-supply)
    (ok amount)
  )
)

;; Add subject to registry
(define-public (add-subject (subject-name (string-ascii 32)) (subject-category (string-ascii 16)) (difficulty-level uint))
  (let (
    (subject-id (var-get next-subject-id))
  )
    (asserts! (> (len subject-name) u0) err-invalid-input)
    (asserts! (> (len subject-category) u0) err-invalid-input)
    (asserts! (and (>= difficulty-level u1) (<= difficulty-level u5)) err-invalid-input)
    
    (map-set subject-registry subject-id {
      subject-name: subject-name,
      subject-category: subject-category,
      difficulty-level: difficulty-level,
      study-hours-logged: u0,
      creator: tx-sender,
      active: true,
      notes-count: u0
    })
    
    (var-set next-subject-id (+ subject-id u1))
    (print {action: "subject-added", subject-id: subject-id, creator: tx-sender})
    (ok subject-id)
  )
)

;; Log study session
(define-public (log-study-session (subject-id uint) (session-duration uint) (focus-rating uint) (session-notes (string-ascii 128)))
  (let (
    (session-id (var-get next-session-id))
    (subject (unwrap! (map-get? subject-registry subject-id) err-not-found))
    (profile (get-or-create-profile tx-sender))
  )
    (asserts! (get active subject) err-invalid-input)
    (asserts! (> session-duration u0) err-invalid-input)
    (asserts! (and (>= focus-rating u1) (<= focus-rating u10)) err-invalid-input)
    
    (map-set study-sessions session-id {
      subject-id: subject-id,
      student: tx-sender,
      session-duration: session-duration,
      focus-rating: focus-rating,
      session-notes: session-notes,
      session-date: stacks-block-height,
      productive: (>= focus-rating u6)
    })
    
    ;; Update subject hours
    (map-set subject-registry subject-id
      (merge subject {study-hours-logged: (+ (get study-hours-logged subject) (/ session-duration u60))})
    )
    
    ;; Update profile
    (map-set student-profiles tx-sender
      (merge profile {
        study-sessions: (+ (get study-sessions profile) u1),
        student-level: (+ (get student-level profile) (/ (+ session-duration focus-rating) u100))
      })
    )
    
    ;; Award study tokens
    (try! (mint-tokens tx-sender reward-study))
    
    (var-set next-session-id (+ session-id u1))
    (print {action: "study-session-logged", session-id: session-id, subject-id: subject-id})
    (ok session-id)
  )
)

;; Share study notes
(define-public (share-notes (subject-id uint) (note-title (string-ascii 48)) (note-content (string-ascii 256)) (note-type (string-ascii 12)))
  (let (
    (subject (unwrap! (map-get? subject-registry subject-id) err-not-found))
    (profile (get-or-create-profile tx-sender))
  )
    (asserts! (get active subject) err-invalid-input)
    (asserts! (> (len note-title) u0) err-invalid-input)
    (asserts! (> (len note-content) u0) err-invalid-input)
    (asserts! (is-none (map-get? study-notes {subject-id: subject-id, note-author: tx-sender})) err-already-exists)
    
    (map-set study-notes {subject-id: subject-id, note-author: tx-sender} {
      note-title: note-title,
      note-content: note-content,
      note-type: note-type,
      helpful-votes: u0,
      note-date: stacks-block-height
    })
    
    ;; Update subject notes count
    (map-set subject-registry subject-id
      (merge subject {notes-count: (+ (get notes-count subject) u1)})
    )
    
    ;; Update profile
    (map-set student-profiles tx-sender
      (merge profile {notes-shared: (+ (get notes-shared profile) u1)})
    )
    
    ;; Award notes tokens
    (try! (mint-tokens tx-sender reward-notes))
    
    (print {action: "notes-shared", subject-id: subject-id, note-author: tx-sender})
    (ok true)
  )
)

;; Vote on notes helpfulness
(define-public (vote-helpful-notes (subject-id uint) (note-author principal))
  (let (
    (notes (unwrap! (map-get? study-notes {subject-id: subject-id, note-author: note-author}) err-not-found))
  )
    (asserts! (not (is-eq tx-sender note-author)) err-unauthorized)
    
    (map-set study-notes {subject-id: subject-id, note-author: note-author}
      (merge notes {helpful-votes: (+ (get helpful-votes notes) u1)})
    )
    
    (print {action: "notes-voted-helpful", subject-id: subject-id, note-author: note-author})
    (ok true)
  )
)

;; Update study field
(define-public (update-study-field (new-study-field (string-ascii 16)))
  (let (
    (profile (get-or-create-profile tx-sender))
  )
    (asserts! (> (len new-study-field) u0) err-invalid-input)
    
    (map-set student-profiles tx-sender (merge profile {study-field: new-study-field}))
    
    (print {action: "study-field-updated", student: tx-sender, field: new-study-field})
    (ok true)
  )
)

;; Claim milestone
(define-public (claim-milestone (milestone (string-ascii 12)))
  (let (
    (profile (get-or-create-profile tx-sender))
  )
    (asserts! (is-none (map-get? student-milestones {student: tx-sender, milestone: milestone})) err-already-exists)
    
    ;; Check milestone requirements
    (let (
      (milestone-met
        (if (is-eq milestone "studious-15") (>= (get study-sessions profile) u15)
        (if (is-eq milestone "helper-8") (>= (get notes-shared profile) u8)
        false)))
    )
      (asserts! milestone-met err-unauthorized)
      
      ;; Record milestone
      (map-set student-milestones {student: tx-sender, milestone: milestone} {
        achievement-date: stacks-block-height,
        study-hours: (* (get study-sessions profile) u2)
      })
      
      ;; Award milestone tokens
      (try! (mint-tokens tx-sender reward-milestone))
      
      (print {action: "milestone-claimed", student: tx-sender, milestone: milestone})
      (ok true)
    )
  )
)

;; Update username
(define-public (update-username (new-username (string-ascii 24)))
  (let (
    (profile (get-or-create-profile tx-sender))
  )
    (asserts! (> (len new-username) u0) err-invalid-input)
    (map-set student-profiles tx-sender (merge profile {username: new-username}))
    (print {action: "username-updated", student: tx-sender})
    (ok true)
  )
)

;; Read-only functions
(define-read-only (get-student-profile (student principal))
  (map-get? student-profiles student)
)

(define-read-only (get-subject (subject-id uint))
  (map-get? subject-registry subject-id)
)

(define-read-only (get-study-session (session-id uint))
  (map-get? study-sessions session-id)
)

(define-read-only (get-study-notes (subject-id uint) (note-author principal))
  (map-get? study-notes {subject-id: subject-id, note-author: note-author})
)

(define-read-only (get-milestone (student principal) (milestone (string-ascii 12)))
  (map-get? student-milestones {student: student, milestone: milestone})
)