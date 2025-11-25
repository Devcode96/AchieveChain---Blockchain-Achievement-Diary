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

;; #[allow(unchecked_data)]
;; Verify an achievement
(define-public (verify-achievement (achievement-id uint))
    (let
        (
            (achievement (unwrap! (map-get? achievements achievement-id) err-not-found))
            (is-verifier (default-to false (map-get? verifiers tx-sender)))
        )
        (asserts! is-verifier err-unauthorized)
        (asserts! (not (get verified achievement)) err-already-verified)
        ;; #[allow(unchecked_data)]
        (ok (map-set achievements achievement-id
            (merge achievement { verified: true, verifier: (some tx-sender) })
        ))
    )
)

;; #[allow(unchecked_data)]
;; Add a verifier
(define-public (add-verifier (verifier principal))
    (begin
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        ;; #[allow(unchecked_data)]
        (ok (map-set verifiers verifier true))
    )
)

;; #[allow(unchecked_data)]
;; Remove a verifier
(define-public (remove-verifier (verifier principal))
    (begin
        (asserts! (is-eq tx-sender contract-owner) err-owner-only)
        (asserts! (not (is-eq verifier contract-owner)) err-unauthorized)
        ;; #[allow(unchecked_data)]
        (ok (map-delete verifiers verifier))
    )
)

;; #[allow(unchecked_data)]
;; Batch verify achievements
(define-public (batch-verify (achievement-ids (list 10 uint)))
    (begin
        (asserts! (default-to false (map-get? verifiers tx-sender)) err-unauthorized)
        ;; #[allow(unchecked_data)]
        (ok (map verify-achievement-internal achievement-ids))
    )
)

;; #[allow(unchecked_data)]
;; Internal function for batch verification
(define-private (verify-achievement-internal (achievement-id uint))
    (let
        (
            (achievement (unwrap-panic (map-get? achievements achievement-id)))
        )
        ;; #[allow(unchecked_data)]
        (map-set achievements achievement-id
            (merge achievement { verified: true, verifier: (some tx-sender) })
        )
    )
)

;; #[allow(unchecked_data)]
;; Create a milestone
(define-public (create-milestone (title (string-ascii 100)) (target-count uint) (category (string-ascii 50)))
    (let
        (
            (milestone-id (var-get milestone-nonce))
            (current-milestones (default-to (list) (map-get? student-milestones tx-sender)))
        )
        ;; #[allow(unchecked_data)]
        (map-set milestones milestone-id {
            student: tx-sender,
            title: title,
            target-count: target-count,
            current-count: u0,
            completed: false,
            category: category
        })
        ;; #[allow(unchecked_data)]
        (map-set student-milestones tx-sender (unwrap-panic (as-max-len? (append current-milestones milestone-id) u50)))
        (var-set milestone-nonce (+ milestone-id u1))
        (ok milestone-id)
    )
)

;; #[allow(unchecked_data)]
;; Update milestone progress
(define-public (update-milestone-progress (milestone-id uint) (increment uint))
    (let
        (
            (milestone (unwrap! (map-get? milestones milestone-id) err-not-found))
            (new-count (+ (get current-count milestone) increment))
        )
        (asserts! (is-eq tx-sender (get student milestone)) err-unauthorized)
        ;; #[allow(unchecked_data)]
        (ok (map-set milestones milestone-id
            (merge milestone { 
                current-count: new-count,
                completed: (>= new-count (get target-count milestone))
            })
        ))
    )
)

;; #[allow(unchecked_data)]
;; Rate an achievement
(define-public (rate-achievement (achievement-id uint) (rating uint))
    (let
        (
            (achievement (unwrap! (map-get? achievements achievement-id) err-not-found))
        )
        (asserts! (not (is-eq tx-sender (get student achievement))) err-cannot-rate-own)
        (asserts! (and (>= rating u1) (<= rating u5)) err-invalid-rating)
        ;; #[allow(unchecked_data)]
        (map-set achievement-ratings { achievement-id: achievement-id, rater: tx-sender } rating)
        (ok true)
    )
)

;; #[allow(unchecked_data)]
;; Update student statistics
(define-private (update-student-stats (student principal))
    (let
        (
            (achievement-ids (default-to (list) (map-get? student-achievements student)))
            (total-count (len achievement-ids))
            (verified-count (fold count-verified achievement-ids u0))
        )
        ;; #[allow(unchecked_data)]
        (map-set student-stats student {
            total-achievements: total-count,
            verified-achievements: verified-count,
            average-rating: u0
        })
    )
)

;; Helper function to count verified achievements
(define-private (count-verified (achievement-id uint) (acc uint))
    (let
        (
            (achievement (map-get? achievements achievement-id))
        )
        (if (and (is-some achievement) (get verified (unwrap-panic achievement)))
            (+ acc u1)
            acc
        )
    )
)