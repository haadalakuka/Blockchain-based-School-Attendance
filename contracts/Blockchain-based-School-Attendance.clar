(define-constant ERR_UNAUTHORIZED (err u100))
(define-constant ERR_NOT_FOUND (err u101))
(define-constant ERR_ALREADY_EXISTS (err u102))
(define-constant ERR_INVALID_DATE (err u103))
(define-constant ERR_STUDENT_NOT_ENROLLED (err u104))
(define-constant ERR_ATTENDANCE_ALREADY_MARKED (err u105))
(define-constant ERR_INVALID_STATUS (err u106))

(define-data-var contract-owner principal tx-sender)
(define-data-var school-name (string-ascii 100) "Default School")
(define-data-var current-semester (string-ascii 20) "2024-1")

(define-map teachers
    principal
    {
        name: (string-ascii 50),
        subject: (string-ascii 30),
        active: bool,
        registered-at: uint,
    }
)

(define-map students
    principal
    {
        name: (string-ascii 50),
        student-id: (string-ascii 20),
        class: (string-ascii 20),
        enrolled-at: uint,
        active: bool,
    }
)

(define-map class-students
    {
        class: (string-ascii 20),
        student: principal,
    }
    bool
)

(define-map attendance-records
    {
        student: principal,
        date: (string-ascii 10),
        class: (string-ascii 20),
    }
    {
        status: (string-ascii 10),
        marked-by: principal,
        marked-at: uint,
        notes: (string-ascii 100),
    }
)

(define-map daily-attendance-summary
    {
        date: (string-ascii 10),
        class: (string-ascii 20),
    }
    {
        total-students: uint,
        present-count: uint,
        absent-count: uint,
        late-count: uint,
        updated-at: uint,
    }
)

(define-map student-attendance-stats
    principal
    {
        total-days: uint,
        present-days: uint,
        absent-days: uint,
        late-days: uint,
        attendance-rate: uint,
    }
)

(define-read-only (get-contract-owner)
    (var-get contract-owner)
)

(define-read-only (get-school-info)
    {
        name: (var-get school-name),
        semester: (var-get current-semester),
        owner: (var-get contract-owner),
    }
)

(define-public (set-school-name (name (string-ascii 100)))
    (begin
        (asserts! (is-eq tx-sender (var-get contract-owner)) ERR_UNAUTHORIZED)
        (ok (var-set school-name name))
    )
)

(define-public (set-current-semester (semester (string-ascii 20)))
    (begin
        (asserts! (is-eq tx-sender (var-get contract-owner)) ERR_UNAUTHORIZED)
        (ok (var-set current-semester semester))
    )
)

(define-public (register-teacher
        (teacher principal)
        (name (string-ascii 50))
        (subject (string-ascii 30))
    )
    (begin
        (asserts! (is-eq tx-sender (var-get contract-owner)) ERR_UNAUTHORIZED)
        (asserts! (is-none (map-get? teachers teacher)) ERR_ALREADY_EXISTS)
        (ok (map-set teachers teacher {
            name: name,
            subject: subject,
            active: true,
            registered-at: stacks-block-height,
        }))
    )
)

(define-public (deactivate-teacher (teacher principal))
    (begin
        (asserts! (is-eq tx-sender (var-get contract-owner)) ERR_UNAUTHORIZED)
        (let ((teacher-info (unwrap! (map-get? teachers teacher) ERR_NOT_FOUND)))
            (ok (map-set teachers teacher (merge teacher-info { active: false })))
        )
    )
)

(define-public (enroll-student
        (student principal)
        (name (string-ascii 50))
        (student-id (string-ascii 20))
        (class (string-ascii 20))
    )
    (begin
        (asserts!
            (or (is-eq tx-sender (var-get contract-owner)) (is-some (map-get? teachers tx-sender)))
            ERR_UNAUTHORIZED
        )
        (asserts! (is-none (map-get? students student)) ERR_ALREADY_EXISTS)
        (map-set students student {
            name: name,
            student-id: student-id,
            class: class,
            enrolled-at: stacks-block-height,
            active: true,
        })
        (map-set class-students {
            class: class,
            student: student,
        }
            true
        )
        (map-set student-attendance-stats student {
            total-days: u0,
            present-days: u0,
            absent-days: u0,
            late-days: u0,
            attendance-rate: u0,
        })
        (ok true)
    )
)

(define-public (unenroll-student (student principal))
    (begin
        (asserts! (is-eq tx-sender (var-get contract-owner)) ERR_UNAUTHORIZED)
        (let ((student-info (unwrap! (map-get? students student) ERR_NOT_FOUND)))
            (ok (map-set students student (merge student-info { active: false })))
        )
    )
)

(define-public (mark-attendance
        (student principal)
        (date (string-ascii 10))
        (class (string-ascii 20))
        (status (string-ascii 10))
        (notes (string-ascii 100))
    )
    (let (
            (teacher-info (unwrap! (map-get? teachers tx-sender) ERR_UNAUTHORIZED))
            (student-info (unwrap! (map-get? students student) ERR_STUDENT_NOT_ENROLLED))
            (attendance-key {
                student: student,
                date: date,
                class: class,
            })
        )
        (asserts! (get active teacher-info) ERR_UNAUTHORIZED)
        (asserts! (get active student-info) ERR_STUDENT_NOT_ENROLLED)
        (asserts! (is-eq (get class student-info) class) ERR_UNAUTHORIZED)
        (asserts!
            (or
                (is-eq status "present")
                (is-eq status "absent")
                (is-eq status "late")
            )
            ERR_INVALID_STATUS
        )
        (asserts! (is-none (map-get? attendance-records attendance-key))
            ERR_ATTENDANCE_ALREADY_MARKED
        )

        (begin
            (map-set attendance-records attendance-key {
                status: status,
                marked-by: tx-sender,
                marked-at: stacks-block-height,
                notes: notes,
            })
            (unwrap-panic (update-student-stats student status))
            (unwrap-panic (update-daily-summary date class))
            (ok true)
        )
    )
)

(define-private (update-student-stats
        (student principal)
        (status (string-ascii 10))
    )
    (let (
            (current-stats (default-to {
                total-days: u0,
                present-days: u0,
                absent-days: u0,
                late-days: u0,
                attendance-rate: u0,
            }
                (map-get? student-attendance-stats student)
            ))
            (new-total (+ (get total-days current-stats) u1))
            (new-present (if (is-eq status "present")
                (+ (get present-days current-stats) u1)
                (get present-days current-stats)
            ))
            (new-absent (if (is-eq status "absent")
                (+ (get absent-days current-stats) u1)
                (get absent-days current-stats)
            ))
            (new-late (if (is-eq status "late")
                (+ (get late-days current-stats) u1)
                (get late-days current-stats)
            ))
            (new-rate (if (> new-total u0)
                (/ (* new-present u100) new-total)
                u0
            ))
        )
        (ok (map-set student-attendance-stats student {
            total-days: new-total,
            present-days: new-present,
            absent-days: new-absent,
            late-days: new-late,
            attendance-rate: new-rate,
        }))
    )
)

(define-private (update-daily-summary
        (date (string-ascii 10))
        (class (string-ascii 20))
    )
    (let (
            (summary-key {
                date: date,
                class: class,
            })
            (current-summary (default-to {
                total-students: u0,
                present-count: u0,
                absent-count: u0,
                late-count: u0,
                updated-at: u0,
            }
                (map-get? daily-attendance-summary summary-key)
            ))
        )
        (ok (map-set daily-attendance-summary summary-key
            (merge current-summary { updated-at: stacks-block-height })
        ))
    )
)

(define-read-only (get-teacher-info (teacher principal))
    (map-get? teachers teacher)
)

(define-read-only (get-student-info (student principal))
    (map-get? students student)
)

(define-read-only (get-attendance-record
        (student principal)
        (date (string-ascii 10))
        (class (string-ascii 20))
    )
    (map-get? attendance-records {
        student: student,
        date: date,
        class: class,
    })
)

(define-read-only (get-student-stats (student principal))
    (map-get? student-attendance-stats student)
)

(define-read-only (get-daily-summary
        (date (string-ascii 10))
        (class (string-ascii 20))
    )
    (map-get? daily-attendance-summary {
        date: date,
        class: class,
    })
)

(define-read-only (is-student-enrolled
        (student principal)
        (class (string-ascii 20))
    )
    (default-to false
        (map-get? class-students {
            class: class,
            student: student,
        })
    )
)

(define-public (bulk-mark-attendance
        (student-list (list 50 principal))
        (date (string-ascii 10))
        (class (string-ascii 20))
        (statuses (list 50 (string-ascii 10)))
    )
    (let ((teacher-info (unwrap! (map-get? teachers tx-sender) ERR_UNAUTHORIZED)))
        (asserts! (get active teacher-info) ERR_UNAUTHORIZED)
        (asserts! (is-eq (len student-list) (len statuses)) ERR_INVALID_STATUS)
        (ok (map bulk-mark-single student-list statuses date class))
    )
)

(define-private (bulk-mark-single
        (student principal)
        (status (string-ascii 10))
        (date (string-ascii 10))
        (class (string-ascii 20))
    )
    (match (mark-attendance student date class status "")
        success
        true
        error
        false
    )
)

(define-public (generate-attendance-report
        (class (string-ascii 20))
        (start-date (string-ascii 10))
        (end-date (string-ascii 10))
    )
    (begin
        (asserts!
            (or (is-eq tx-sender (var-get contract-owner)) (is-some (map-get? teachers tx-sender)))
            ERR_UNAUTHORIZED
        )
        (ok {
            class: class,
            period: {
                start: start-date,
                end: end-date,
            },
            generated-by: tx-sender,
            generated-at: stacks-block-height,
        })
    )
)
