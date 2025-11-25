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