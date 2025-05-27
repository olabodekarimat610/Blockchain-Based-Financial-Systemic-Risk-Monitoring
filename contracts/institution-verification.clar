;; Institution Verification Contract
;; Validates and manages financial entities in the system

(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_UNAUTHORIZED (err u100))
(define-constant ERR_INSTITUTION_EXISTS (err u101))
(define-constant ERR_INSTITUTION_NOT_FOUND (err u102))
(define-constant ERR_INVALID_STATUS (err u103))

;; Institution status types
(define-constant STATUS_PENDING u0)
(define-constant STATUS_VERIFIED u1)
(define-constant STATUS_SUSPENDED u2)
(define-constant STATUS_REVOKED u3)

;; Data structure for financial institutions
(define-map institutions
  { institution-id: uint }
  {
    name: (string-ascii 100),
    institution-type: (string-ascii 50),
    regulator: (string-ascii 100),
    status: uint,
    verification-date: uint,
    risk-tier: uint
  }
)

(define-map institution-principals
  { principal: principal }
  { institution-id: uint }
)

(define-data-var next-institution-id uint u1)

;; Register a new financial institution
(define-public (register-institution
  (name (string-ascii 100))
  (institution-type (string-ascii 50))
  (regulator (string-ascii 100))
  (risk-tier uint))
  (let ((institution-id (var-get next-institution-id)))
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)
    (asserts! (is-none (map-get? institution-principals { principal: tx-sender })) ERR_INSTITUTION_EXISTS)

    (map-set institutions
      { institution-id: institution-id }
      {
        name: name,
        institution-type: institution-type,
        regulator: regulator,
        status: STATUS_PENDING,
        verification-date: block-height,
        risk-tier: risk-tier
      }
    )

    (map-set institution-principals
      { principal: tx-sender }
      { institution-id: institution-id }
    )

    (var-set next-institution-id (+ institution-id u1))
    (ok institution-id)
  )
)

;; Verify an institution
(define-public (verify-institution (institution-id uint))
  (let ((institution (unwrap! (map-get? institutions { institution-id: institution-id }) ERR_INSTITUTION_NOT_FOUND)))
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_UNAUTHORIZED)

    (map-set institutions
      { institution-id: institution-id }
      (merge institution { status: STATUS_VERIFIED, verification-date: block-height })
    )
    (ok true)
  )
)

;; Get institution details
(define-read-only (get-institution (institution-id uint))
  (map-get? institutions { institution-id: institution-id })
)

;; Check if institution is verified
(define-read-only (is-institution-verified (institution-id uint))
  (match (map-get? institutions { institution-id: institution-id })
    institution (is-eq (get status institution) STATUS_VERIFIED)
    false
  )
)

;; Get institution ID by principal
(define-read-only (get-institution-by-principal (principal-addr principal))
  (map-get? institution-principals { principal: principal-addr })
)
