;; AchieveChain - Blockchain-based Achievement Diary
;; Tracks and verifies student progress securely

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-unauthorized (err u102))
(define-constant err-already-verified (err u103))
(define-constant err-invalid-category (err u104))
(define-constant err-already-exists (err u105))
(define-constant err-invalid-rating (err u106))
(define-constant err-cannot-rate-own (err u107))

;; Data Variables
(define-data-var achievement-nonce uint u0)
(define-data-var milestone-nonce uint u0)
(define-data-var total-verified uint u0)

;; Data Maps
(define-map achievements
    uint
    {
        student: principal,
        title: (string-ascii 100),
        description: (string-ascii 256),
        category: (string-ascii 50),
        timestamp: uint,
        verified: bool,
        verifier: (optional principal),
        rating: uint
    }
)

(define-map student-achievements
    principal
    (list 100 uint)
)

(define-map verifiers
    principal
    bool
)

(define-map categories
    (string-ascii 50)
    uint
)

(define-map milestones
    uint
    {
        student: principal,
        title: (string-ascii 100),
        target-count: uint,
        current-count: uint,
        completed: bool,
        category: (string-ascii 50)
    }
)

(define-map student-milestones
    principal
    (list 50 uint)
)

(define-map achievement-ratings
    { achievement-id: uint, rater: principal }
    uint
)

(define-map student-stats
    principal
    {
        total-achievements: uint,
        verified-achievements: uint,
        average-rating: uint
    }
)

;; Initialize contract owner as verifier
(map-set verifiers contract-owner true)