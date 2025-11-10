(define-constant ERR_NOT_OWNER (err u100))
(define-constant ERR_OWNER_NOT_INITIALIZED (err u101))
(define-constant ERR_ALREADY_INITIALIZED (err u102))
(define-constant ERR_UNAUTHORIZED (err u103))
(define-constant ERR_NOT_FOUND (err u104))

(define-data-var contract-owner (optional principal) none)

(define-map class-teachers 
    {
        class-id: (string-ascii 20),
        teacher: principal,
    }
    {
        enabled: bool,
    }
)

(define-public (initialize-owner (owner principal))
    (begin
        (asserts! (is-none (var-get contract-owner)) ERR_ALREADY_INITIALIZED)
        (ok (var-set contract-owner (some owner)))
    )
)

(define-public (authorize-teacher (class-id (string-ascii 20)) (teacher principal))
    (let ((owner (unwrap! (var-get contract-owner) ERR_OWNER_NOT_INITIALIZED)))
        (asserts! (is-eq tx-sender owner) ERR_NOT_OWNER)
        (ok (map-set class-teachers 
            { class-id: class-id, teacher: teacher }
            { enabled: true }
        ))
    )
)

(define-public (revoke-teacher (class-id (string-ascii 20)) (teacher principal))
    (let ((owner (unwrap! (var-get contract-owner) ERR_OWNER_NOT_INITIALIZED)))
        (asserts! (is-eq tx-sender owner) ERR_NOT_OWNER)
        (ok (map-set class-teachers 
            { class-id: class-id, teacher: teacher }
            { enabled: false }
        ))
    )
)

(define-read-only (is-teacher-authorized (class-id (string-ascii 20)) (teacher principal))
    (default-to false
        (get enabled 
            (map-get? class-teachers 
                { class-id: class-id, teacher: teacher }
            )
        )
    )
)

(define-read-only (get-contract-owner)
    (var-get contract-owner)
)

(define-public (mark-attendance-authorized
        (student principal)
        (date (string-ascii 10))
        (class (string-ascii 20))
        (status (string-ascii 10))
        (notes (string-ascii 100))
    )
    (begin
        (asserts! (is-teacher-authorized class tx-sender) ERR_UNAUTHORIZED)
        (contract-call? .Blockchain-based-School-Attendance mark-attendance student date class status notes)
    )
)