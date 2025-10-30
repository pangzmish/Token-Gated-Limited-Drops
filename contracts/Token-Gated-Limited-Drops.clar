;; Token-Gated Limited Drops
;; Exclusive clothing drops accessible only to NFT holders

;; Constants
(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_OWNER_ONLY (err u100))
(define-constant ERR_NOT_FOUND (err u101))
(define-constant ERR_UNAUTHORIZED (err u102))
(define-constant ERR_INSUFFICIENT_FUNDS (err u103))
(define-constant ERR_DROP_INACTIVE (err u104))
(define-constant ERR_DROP_SOLD_OUT (err u105))
(define-constant ERR_PURCHASE_LIMIT_EXCEEDED (err u106))
(define-constant ERR_INVALID_NFT_CONTRACT (err u107))
(define-constant ERR_DROP_NOT_STARTED (err u108))
(define-constant ERR_DROP_ENDED (err u109))
(define-constant ERR_ALREADY_PURCHASED (err u110))
(define-constant ERR_NOT_WHITELISTED (err u111))

;; Data Variables
(define-data-var next-drop-id uint u1)
(define-data-var contract-paused bool false)

;; Data Maps
(define-map drops
  uint
  {
    name: (string-ascii 50),
    description: (string-ascii 200),
    price: uint,
    total-supply: uint,
    sold-count: uint,
    start-block: uint,
    end-block: uint,
    max-per-user: uint,
    nft-contract: principal,
    is-active: bool,
    creator: principal
  }
)

(define-map user-purchases
  { drop-id: uint, user: principal }
  uint
)

(define-map nft-holder-verified
  { user: principal, nft-contract: principal }
  bool
)

(define-map drop-earnings
  uint
  uint
)

(define-map drop-whitelist
  { drop-id: uint, user: principal }
  bool
)

(define-map drop-whitelist-enabled
  uint
  bool
)

;; NFT Trait
(define-trait nft-trait
  (
    (get-owner (uint) (response (optional principal) uint))
    (get-balance (principal) (response uint uint))
  )
)

;; Public Functions

(define-public (create-drop
  (name (string-ascii 50))
  (description (string-ascii 200))
  (price uint)
  (total-supply uint)
  (start-block uint)
  (end-block uint)
  (max-per-user uint)
  (nft-contract principal)
)
  (let
    (
      (drop-id (var-get next-drop-id))
    )
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_OWNER_ONLY)
    (asserts! (> total-supply u0) (err u200))
    (asserts! (> max-per-user u0) (err u201))
    (asserts! (> end-block start-block) (err u202))
    (asserts! (>= start-block stacks-block-height) (err u203))
    
    (map-set drops drop-id {
      name: name,
      description: description,
      price: price,
      total-supply: total-supply,
      sold-count: u0,
      start-block: start-block,
      end-block: end-block,
      max-per-user: max-per-user,
      nft-contract: nft-contract,
      is-active: true,
      creator: tx-sender
    })
    
    (var-set next-drop-id (+ drop-id u1))
    (ok drop-id)
  )
)

(define-public (purchase-item (drop-id uint) (quantity uint))
  (let
    (
      (drop (unwrap! (map-get? drops drop-id) ERR_NOT_FOUND))
      (current-purchases (default-to u0 (map-get? user-purchases { drop-id: drop-id, user: tx-sender })))
      (total-cost (* (get price drop) quantity))
      (new-purchase-count (+ current-purchases quantity))
      (new-sold-count (+ (get sold-count drop) quantity))
      (whitelist-enabled (default-to false (map-get? drop-whitelist-enabled drop-id)))
    )
    (asserts! (not (var-get contract-paused)) (err u300))
    (asserts! (get is-active drop) ERR_DROP_INACTIVE)
    (asserts! (>= stacks-block-height (get start-block drop)) ERR_DROP_NOT_STARTED)
    (asserts! (<= stacks-block-height (get end-block drop)) ERR_DROP_ENDED)
    (asserts! (<= new-sold-count (get total-supply drop)) ERR_DROP_SOLD_OUT)
    (asserts! (<= new-purchase-count (get max-per-user drop)) ERR_PURCHASE_LIMIT_EXCEEDED)
    (asserts! (> quantity u0) (err u301))
    
    (if whitelist-enabled
      (asserts! (default-to false (map-get? drop-whitelist { drop-id: drop-id, user: tx-sender })) ERR_NOT_WHITELISTED)
      true
    )
    
    (try! (verify-nft-holder tx-sender (get nft-contract drop)))
    
    (try! (stx-transfer? total-cost tx-sender CONTRACT_OWNER))
    
    (map-set drops drop-id (merge drop { sold-count: new-sold-count }))
    (map-set user-purchases { drop-id: drop-id, user: tx-sender } new-purchase-count)
    (map-set drop-earnings drop-id 
      (+ (default-to u0 (map-get? drop-earnings drop-id)) total-cost))
    
    (ok { purchased: quantity, total-paid: total-cost })
  )
)

(define-public (verify-nft-ownership (nft-contract <nft-trait>) (token-id uint))
  (let
    (
      (owner-result (contract-call? nft-contract get-owner token-id))
    )
    (match owner-result
      owner-opt (match owner-opt
        owner (begin
          (map-set nft-holder-verified 
            { user: tx-sender, nft-contract: (contract-of nft-contract) } 
            true)
          (ok true)
        )
        (err u400)
      )
      error (err u401)
    )
  )
)

(define-public (toggle-drop-status (drop-id uint))
  (let
    (
      (drop (unwrap! (map-get? drops drop-id) ERR_NOT_FOUND))
    )
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_OWNER_ONLY)
    (map-set drops drop-id (merge drop { is-active: (not (get is-active drop)) }))
    (ok (not (get is-active drop)))
  )
)

(define-public (update-drop-price (drop-id uint) (new-price uint))
  (let
    (
      (drop (unwrap! (map-get? drops drop-id) ERR_NOT_FOUND))
    )
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_OWNER_ONLY)
    (map-set drops drop-id (merge drop { price: new-price }))
    (ok true)
  )
)

(define-public (emergency-pause)
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_OWNER_ONLY)
    (var-set contract-paused true)
    (ok true)
  )
)

(define-public (emergency-unpause)
  (begin
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_OWNER_ONLY)
    (var-set contract-paused false)
    (ok true)
  )
)

(define-public (withdraw-earnings (drop-id uint))
  (let
    (
      (earnings (default-to u0 (map-get? drop-earnings drop-id)))
    )
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_OWNER_ONLY)
    (asserts! (> earnings u0) (err u500))
    
    (map-delete drop-earnings drop-id)
    (try! (as-contract (stx-transfer? earnings tx-sender CONTRACT_OWNER)))
    (ok earnings)
  )
)

(define-public (enable-drop-whitelist (drop-id uint))
  (let
    (
      (drop (unwrap! (map-get? drops drop-id) ERR_NOT_FOUND))
    )
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_OWNER_ONLY)
    (map-set drop-whitelist-enabled drop-id true)
    (ok true)
  )
)

(define-public (disable-drop-whitelist (drop-id uint))
  (let
    (
      (drop (unwrap! (map-get? drops drop-id) ERR_NOT_FOUND))
    )
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_OWNER_ONLY)
    (map-set drop-whitelist-enabled drop-id false)
    (ok true)
  )
)

(define-public (add-to-whitelist (drop-id uint) (user principal))
  (let
    (
      (drop (unwrap! (map-get? drops drop-id) ERR_NOT_FOUND))
    )
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_OWNER_ONLY)
    (map-set drop-whitelist { drop-id: drop-id, user: user } true)
    (ok true)
  )
)

(define-public (remove-from-whitelist (drop-id uint) (user principal))
  (let
    (
      (drop (unwrap! (map-get? drops drop-id) ERR_NOT_FOUND))
    )
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_OWNER_ONLY)
    (map-delete drop-whitelist { drop-id: drop-id, user: user })
    (ok true)
  )
)

(define-public (batch-add-to-whitelist (drop-id uint) (users (list 100 principal)))
  (let
    (
      (drop (unwrap! (map-get? drops drop-id) ERR_NOT_FOUND))
    )
    (asserts! (is-eq tx-sender CONTRACT_OWNER) ERR_OWNER_ONLY)
    (ok (fold add-user-to-whitelist-fold users drop-id))
  )
)

(define-private (add-user-to-whitelist-fold (user principal) (drop-id uint))
  (begin
    (map-set drop-whitelist { drop-id: drop-id, user: user } true)
    drop-id
  )
)

;; Read-only Functions

(define-read-only (get-drop (drop-id uint))
  (map-get? drops drop-id)
)

(define-read-only (get-user-purchases (drop-id uint) (user principal))
  (default-to u0 (map-get? user-purchases { drop-id: drop-id, user: user }))
)

(define-read-only (get-drop-earnings (drop-id uint))
  (default-to u0 (map-get? drop-earnings drop-id))
)

(define-read-only (is-nft-holder-verified (user principal) (nft-contract principal))
  (default-to false (map-get? nft-holder-verified { user: user, nft-contract: nft-contract }))
)

(define-read-only (get-next-drop-id)
  (var-get next-drop-id)
)

(define-read-only (is-contract-paused)
  (var-get contract-paused)
)

(define-read-only (is-whitelisted (drop-id uint) (user principal))
  (default-to false (map-get? drop-whitelist { drop-id: drop-id, user: user }))
)

(define-read-only (is-whitelist-enabled (drop-id uint))
  (default-to false (map-get? drop-whitelist-enabled drop-id))
)

(define-read-only (get-drop-availability (drop-id uint))
  (match (map-get? drops drop-id)
    drop (let
      (
        (available (- (get total-supply drop) (get sold-count drop)))
        (is-live (and 
          (get is-active drop)
          (>= stacks-block-height (get start-block drop))
          (<= stacks-block-height (get end-block drop))
        ))
      )
      (some { available: available, is-live: is-live, sold-out: (is-eq available u0) })
    )
    none
  )
)

(define-read-only (can-user-purchase (drop-id uint) (user principal) (quantity uint))
  (match (map-get? drops drop-id)
    drop (let
      (
        (current-purchases (default-to u0 (map-get? user-purchases { drop-id: drop-id, user: user })))
        (available (- (get total-supply drop) (get sold-count drop)))
        (would-exceed-limit (> (+ current-purchases quantity) (get max-per-user drop)))
        (would-exceed-supply (> quantity available))
        (is-verified (default-to false (map-get? nft-holder-verified { user: user, nft-contract: (get nft-contract drop) })))
      )
      (some {
        can-purchase: (and 
          (not would-exceed-limit)
          (not would-exceed-supply)
          is-verified
          (get is-active drop)
          (>= stacks-block-height (get start-block drop))
          (<= stacks-block-height (get end-block drop))
        ),
        reason: (if would-exceed-limit "exceeds-user-limit"
          (if would-exceed-supply "exceeds-supply"
            (if (not is-verified) "not-verified"
              (if (not (get is-active drop)) "drop-inactive"
                (if (< stacks-block-height (get start-block drop)) "not-started"
                  (if (> stacks-block-height (get end-block drop)) "ended"
                    "ok"
                  )
                )
              )
            )
          )
        )
      })
    )
    none
  )
)

;; Private Functions

(define-private (verify-nft-holder (user principal) (nft-contract principal))
  (if (default-to false (map-get? nft-holder-verified { user: user, nft-contract: nft-contract }))
    (ok true)
    ERR_UNAUTHORIZED
  )
)
