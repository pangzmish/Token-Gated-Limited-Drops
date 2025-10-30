# 🎯 Token-Gated Limited Drops

> Exclusive clothing drops accessible only to NFT holders - where digital ownership meets physical fashion! 👕✨

## 🌟 Overview

Token-Gated Limited Drops is a Clarity smart contract that enables exclusive fashion drops where only holders of specific NFTs can purchase limited edition items. This creates a bridge between digital collectibles and physical merchandise, offering true utility for NFT ownership.

## ✨ Features

- 🎫 **NFT-Gated Access**: Only verified NFT holders can purchase items
- 📦 **Drop Management**: Create and manage limited edition drops with customizable parameters
- ⏰ **Time-Based Sales**: Set start and end blocks for drops
- 🛍️ **Purchase Limits**: Control maximum purchases per user
- 💰 **Dynamic Pricing**: Update prices for active drops
- 🔒 **Emergency Controls**: Pause/unpause contract functionality
- 📊 **Real-time Tracking**: Monitor sales, availability, and earnings

## 🚀 Quick Start

### Prerequisites
- Clarinet installed
- Stacks wallet for testing
- NFT contract deployed (for gating)

### Installation

```bash
git clone <repository-url>
cd Token-Gated-Limited-Drops
clarinet check
```

## 📖 Usage Guide

### 🎨 Creating a Drop

Only the contract owner can create drops:

```clarity
(contract-call? .Token-Gated-Limited-Drops create-drop
  "Supreme Hoodie Drop"           ;; name
  "Limited edition hoodies"       ;; description  
  u1000000                        ;; price in microSTX
  u100                           ;; total supply
  u1000                          ;; start block
  u2000                          ;; end block
  u2                             ;; max per user
  'SP1234...NFT-CONTRACT         ;; NFT contract address
)
```

### 🎟️ Verifying NFT Ownership

Users must verify their NFT ownership before purchasing:

```clarity
(contract-call? .Token-Gated-Limited-Drops verify-nft-ownership
  .my-nft-contract               ;; NFT contract
  u1                            ;; token ID owned
)
```

### 🛒 Making a Purchase

Once verified, NFT holders can purchase items:

```clarity
(contract-call? .Token-Gated-Limited-Drops purchase-item
  u1                            ;; drop ID
  u1                            ;; quantity
)
```

### 📊 Checking Drop Status

View drop details and availability:

```clarity
(contract-call? .Token-Gated-Limited-Drops get-drop u1)
(contract-call? .Token-Gated-Limited-Drops get-drop-availability u1)
```

## 🔧 Admin Functions

### 🎛️ Drop Management
- `toggle-drop-status`: Activate/deactivate drops
- `update-drop-price`: Change drop pricing
- `withdraw-earnings`: Collect drop earnings

### 🚨 Emergency Controls
- `emergency-pause`: Halt all contract operations
- `emergency-unpause`: Resume normal operations

## 📱 Read-Only Functions

| Function | Description |
|----------|-------------|
| `get-drop` | Get drop details by ID |
| `get-user-purchases` | Check user's purchase count for a drop |
| `get-drop-availability` | Check remaining supply and status |
| `can-user-purchase` | Validate if user can make purchase |
| `is-nft-holder-verified` | Check if user verified NFT ownership |
| `get-drop-earnings` | View drop earnings |

## 🎯 Use Cases

### 👕 Fashion Brands
- Launch exclusive merchandise for NFT communities
- Create utility for existing PFP collections
- Build loyalty through exclusive access

### 🎮 Gaming Projects
- Reward players with exclusive physical items
- Gate merchandise behind achievement NFTs
- Create cross-platform value

### 🎭 Art Collectors
- Offer physical prints to digital art owners
- Create mixed reality experiences
- Build exclusive collector communities

## 📋 Contract States

### Drop States
- ✅ **Active**: Drop is live and accepting purchases
- ❌ **Inactive**: Drop is paused by admin
- ⏳ **Pending**: Start block not reached
- ⏰ **Ended**: End block passed
- 🚫 **Sold Out**: All items purchased

### Purchase Validation
The contract validates multiple conditions:
- NFT ownership verification ✅
- Drop timing (start/end blocks) ⏰
- Supply availability 📦
- User purchase limits 🎯
- Drop active status 🟢

## 🔒 Security Features

- **Owner-only admin functions**: Critical operations restricted to contract owner
- **NFT verification**: Cryptographic proof of NFT ownership required
- **Purchase limits**: Prevent gaming through quantity restrictions
- **Emergency controls**: Circuit breaker for critical situations
- **Immutable purchases**: Purchase records permanently stored

## 🧪 Testing

```bash
# Check contract syntax
clarinet check

# Run test suite
clarinet test

# Deploy to testnet
clarinet deployments generate-requirements
```

## 🤝 Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙋‍♀️ Support

- 📧 Open an issue for bugs or feature requests
- 💬 Join our Discord for community support
- 📚 Check the [Clarity Documentation](https://docs.stacks.co/clarity) for language reference

---

*Built with ❤️ for the intersection of digital ownership and physical goods*
