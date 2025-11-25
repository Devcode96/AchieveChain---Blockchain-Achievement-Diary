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

;; #[allow(unchecked_data)]
;; Record a new achievement
(define-public (record-achievement (title (string-ascii 100)) (description (string-ascii 256)) (category (string-ascii 50)))
    (let
        (
            (achievement-id (var-get achievement-nonce))
            (current-achievements (default-to (list) (map-get? student-achievements tx-sender)))
            (category-count (default-to u0 (map-get? categories category)))
        )
        ;; #[allow(unchecked_data)]
        (map-set achievements achievement-id {
            student: tx-sender,
            title: title,
            description: description,
            category: category,
            timestamp: stacks-block-height,
            verified: false,
            verifier: none,
            rating: u0
        })
        ;; #[allow(unchecked_data)]
        (map-set student-achievements tx-sender (unwrap-panic (as-max-len? (append current-achievements achievement-id) u100)))
        ;; #[allow(unchecked_data)]
        (map-set categories category (+ category-count u1))
        (var-set achievement-nonce (+ achievement-id u1))
        (update-student-stats tx-sender)
        (ok achievement-id)
    )
)

;; #[allow(unchecked_data)]
;; Update achievement description
(define-public (update-achievement (achievement-id uint) (new-description (string-ascii 256)))
    (let
        (
            (achievement (unwrap! (map-get? achievements achievement-id) err-not-found))
        )
        (asserts! (is-eq tx-sender (get student achievement)) err-unauthorized)
        (asserts! (not (get verified achievement)) err-already-verified)
        ;; #[allow(unchecked_data)]
        (ok (map-set achievements achievement-id
            (merge achievement { description: new-description })
        ))
    )
)

;; #[allow(unchecked_data)]
;; Delete unverified achievement
(define-public (delete-achievement (achievement-id uint))
    (let
        (
            (achievement (unwrap! (map-get? achievements achievement-id) err-not-found))
        )
        (asserts! (is-eq tx-sender (get student achievement)) err-unauthorized)
        (asserts! (not (get verified achievement)) err-already-verified)
        ;; #[allow(unchecked_data)]
        (ok (map-delete achievements achievement-id))
    )
)