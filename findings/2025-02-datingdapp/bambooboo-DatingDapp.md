# DatingDapp - Findings Report

# Table of contents
- ## [Contest Summary](#contest-summary)
- ## [Results Summary](#results-summary)
- ## High Risk Findings
    - ### [H-01. Missing Deposit Mechanism in `LikeRegistry.sol` Prevents Getting Dating Funds](#H-01)
- ## Medium Risk Findings
    - ### [M-01. Reentrancy Risk in `mintProfile` Due to Improper State Update Order](#M-01)



# <a id='contest-summary'></a>Contest Summary

### Sponsor: First Flight #33

### Dates: Feb 6th, 2025 - Feb 13th, 2025

[See more contest details here](https://codehawks.cyfrin.io/c/2025-02-datingdapp)

# <a id='results-summary'></a>Results Summary

### Number of findings:
- High: 1
- Medium: 1
- Low: 0


# High Risk Findings

## <a id='H-01'></a>H-01. Missing Deposit Mechanism in `LikeRegistry.sol` Prevents Getting Dating Funds            



## Summary

The contract documentation states:

> "If the like is mutual, all their previous like payments (minus a 10% fee) are pooled into a shared multisig wallet."

However, there is no mechanism for users to deposit funds into the contract. As a result, `userBalances` remains empty, and the multisig wallet will never receive any funds, making the intended functionality ineffective.

## Vulnerability Details

In `src/LikeRegistry.sol`, the contract maintains a mapping:

```Solidity
mapping(address => uint256) public userBalances;
```

The function `matchRewards` attempts to access `userBalances` to retrieve user balances:

```Solidity
uint256 matchUserOne = userBalances[from];
uint256 matchUserTwo = userBalances[to];
```

However, there is no function that allows users to deposit funds into `userBalances`. Without a way to update this mapping, the balance always remains zero, rendering the dating funds distribution mechanism non-functional.

## Impact

* Users cannot deposit funds to update `userBalances`, making it impossible to participate in the intended payment flow.
* The multisig wallet never receives any funds, preventing users from benefiting from mutual likes.
* The core feature of like payments is ineffective, as no transactions occur.

## Tools Used

Manual code review

## Recommendations

To fix this issue, implement a `receive` function that allows users to deposit funds into the contract while preventing unintended deposits:

```Solidity
receive() external payable {
    require(msg.value > 0, "Deposit must be greater than zero");
    userBalances[msg.sender] += msg.value;
}
```

This ensures that users can fund their accounts, allowing `matchRewards` to function as intended.

    
# Medium Risk Findings

## <a id='M-01'></a>M-01. Reentrancy Risk in `mintProfile` Due to Improper State Update Order            



## Summary

In `src/SoulboundProfileNFT.sol`, the `mintProfile` function first checks the validity, then mints the NFT, which may trigger an external call via the `onERC721Received` function, and finally updates the contract's internal state. This violates the **Checks-Effects-Interactions (CEI) principle**, potentially introducing a reentrancy risk.

## Vulnerability Details

The function implementation is as follows:

```Solidity
function mintProfile(string memory name, uint8 age, string memory profileImage) external {
    require(profileToToken[msg.sender] == 0, "Profile already exists");
​
    uint256 tokenId = ++_nextTokenId;
    _safeMint(msg.sender, tokenId); // External call before updating contract state
​
    // Store metadata on-chain
    _profiles[tokenId] = Profile(name, age, profileImage);
    profileToToken[msg.sender] = tokenId;
​
    emit ProfileMinted(msg.sender, tokenId, name, age, profileImage);
}
```

In this function, `_safeMint(msg.sender, tokenId)` is executed before updating `_profiles[tokenId]` and `profileToToken[msg.sender]`. Since `_safeMint` can trigger `onERC721Received`, which allows external contracts to execute arbitrary logic, an attacker could exploit this reentrancy window to manipulate contract state in an unintended way.

## Impact

* Potential reentrancy attack, leading to unauthorized multiple profile minting
* Inconsistent contract state if execution is reverted unexpectedly during the external call

## Tools Used

Manual code review

## Recommendations

Reorder the function logic to follow the CEI principle:

1. Update the contract's internal state before performing any external interactions
2. Call `_safeMint` only after modifying `_profiles[tokenId]` and `profileToToken[msg.sender]`

The corrected implementation should be:

```Solidity
function mintProfile(string memory name, uint8 age, string memory profileImage) external {
    require(profileToToken[msg.sender] == 0, "Profile already exists");
​
    uint256 tokenId = ++_nextTokenId;
​
    // Store metadata on-chain before external interaction
    _profiles[tokenId] = Profile(name, age, profileImage);
    profileToToken[msg.sender] = tokenId;
​
    _safeMint(msg.sender, tokenId); // External call after state update
​
    emit ProfileMinted(msg.sender, tokenId, name, age, profileImage);
}
```

This modification ensures that any external contract interaction occurs only after the contract's internal state is securely updated, reducing the risk of reentrancy attacks.






