;; vote-dapp-stacks
;; Core voting contract for the Vote Battle dApp on Stacks

;; Constants
(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_NOT_AUTHORIZED (err u100))
(define-constant ERR_PROPOSAL_NOT_FOUND (err u101))
(define-constant ERR_ALREADY_VOTED (err u102))
(define-constant ERR_VOTING_CLOSED (err u103))
(define-constant ERR_INVALID_OPTION (err u104))
(define-constant MAX_OPTIONS u10)

;; Data variables
(define-data-var proposal-count uint u0)
(define-data-var total-votes uint u0)

;; Data maps
(define-map proposals uint
  {
    title: (string-utf8 128),
    creator: principal,
    options: (list 10 (string-utf8 64)),
    created-at: uint,
    closed: bool,
  }
)

(define-map option-votes { proposal-id: uint, option-index: uint } uint)

(define-map voter-records { proposal-id: uint, voter: principal } bool)

(define-map user-stats principal
  {
    votes-cast: uint,
    proposals-created: uint,
  }
)

;; Read-only functions
(define-read-only (get-proposal (id uint))
  (ok (map-get? proposals id))
)

(define-read-only (get-proposal-count)
  (ok (var-get proposal-count))
)

(define-read-only (get-total-votes)
  (ok (var-get total-votes))
)

(define-read-only (get-option-votes (proposal-id uint) (option-index uint))
  (ok (default-to u0 (map-get? option-votes { proposal-id: proposal-id, option-index: option-index })))
)

(define-read-only (has-voted (proposal-id uint) (voter principal))
  (ok (default-to false (map-get? voter-records { proposal-id: proposal-id, voter: voter })))
)

(define-read-only (get-user-stats (user principal))
  (ok (default-to
    { votes-cast: u0, proposals-created: u0 }
    (map-get? user-stats user)
  ))
)

;; Public functions
(define-public (create-proposal (title (string-utf8 128)) (options (list 10 (string-utf8 64))))
  (let (
    (id (var-get proposal-count))
    (creator tx-sender)
    (current-stats (default-to
      { votes-cast: u0, proposals-created: u0 }
      (map-get? user-stats creator)
    ))
  )
    (map-set proposals id {
      title: title,
      creator: creator,
      options: options,
      created-at: block-height,
      closed: false,
    })

    (map-set user-stats creator {
      votes-cast: (get votes-cast current-stats),
      proposals-created: (+ (get proposals-created current-stats) u1),
    })

    (var-set proposal-count (+ id u1))
    (ok id)
  )
)

(define-public (vote (proposal-id uint) (option-index uint))
  (let (
    (voter tx-sender)
    (proposal (unwrap! (map-get? proposals proposal-id) ERR_PROPOSAL_NOT_FOUND))
    (already-voted (default-to false (map-get? voter-records { proposal-id: proposal-id, voter: voter })))
    (current-votes (default-to u0 (map-get? option-votes { proposal-id: proposal-id, option-index: option-index })))
    (current-stats (default-to
      { votes-cast: u0, proposals-created: u0 }
      (map-get? user-stats voter)
    ))
  )
    (asserts! (not (get closed proposal)) ERR_VOTING_CLOSED)
    (asserts! (not already-voted) ERR_ALREADY_VOTED)
    (asserts! (< option-index (len (get options proposal))) ERR_INVALID_OPTION)

    (map-set voter-records { proposal-id: proposal-id, voter: voter } true)
    (map-set option-votes { proposal-id: proposal-id, option-index: option-index } (+ current-votes u1))

    (map-set user-stats voter {
      votes-cast: (+ (get votes-cast current-stats) u1),
      proposals-created: (get proposals-created current-stats),
    })

    (var-set total-votes (+ (var-get total-votes) u1))
    (ok true)
  )
)

(define-public (close-proposal (proposal-id uint))
  (let (
    (proposal (unwrap! (map-get? proposals proposal-id) ERR_PROPOSAL_NOT_FOUND))
  )
    (asserts! (is-eq tx-sender (get creator proposal)) ERR_NOT_AUTHORIZED)
    (map-set proposals proposal-id (merge proposal { closed: true }))
    (ok true)
  )
)
