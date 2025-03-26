# Inheritable Smart Contract Wallet - Findings Report

# Table of contents
- ## [Contest Summary](#contest-summary)
- ## [Results Summary](#results-summary)
- ## High Risk Findings
    - ### [H-01. Unauthorized Ownership Reclaim in `inherit` Function](#H-01)
    - ### [H-02. Transaction Blocking by Malicious Beneficiary](#H-02)
    - ### [H-03. Incorrect Beneficiary Payment Logic in `buyOutEstateNFT` Function](#H-03)
    - ### [H-04. Lack of Ownership Transfer in `buyOutEstateNFT` Function](#H-04)

- ## Low Risk Findings
    - ### [L-01. Dust Accumulation in `withdrawInheritedFunds` Function](#L-01)


# <a id='contest-summary'></a>Contest Summary

### Sponsor: First Flight #35

### Dates: Mar 6th, 2025 - Mar 13th, 2025

[See more contest details here](https://codehawks.cyfrin.io/c/2025-03-inheritable-smart-contract-wallet)

# <a id='results-summary'></a>Results Summary

### Number of findings:
- High: 4
- Medium: 0
- Low: 1


# High Risk Findings

## <a id='H-01'></a>H-01. Unauthorized Ownership Reclaim in `inherit` Function            



## Summary

In `src/InheritanceManager.sol`, the function `inherit` allows anyone to become the owner of the contract when `beneficiaries.length == 1` without verifying if `msg.sender` is the sole beneficiary. This behavior violates the intended inheritance mechanism and could result in unauthorized ownership transfers.

## Vulnerability Details

In [InheritanceManager.sol#L217](https://github.com/CodeHawks-Contests/2025-03-inheritable-smart-contract-wallet/blob/main/src/InheritanceManager.sol#L217), the `inherit` function is implemented as follows:

```Solidity
function inherit() external {
    if (block.timestamp < getDeadline()) {
        revert InactivityPeriodNotLongEnough();
    }
    if (beneficiaries.length == 1) {
        owner = msg.sender;
        _setDeadline();
    } else if (beneficiaries.length > 1) {
        isInherited = true;
    } else {
        revert InvalidBeneficiaries();
    }
}
```

When `beneficiaries.length == 1`, the function does not check that `msg.sender` is the only beneficiary in the list. This allows any attacker to front-run the intended beneficiary and claim ownership of the contract.

## PoC

```Solidity
// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Test, console} from "forge-std/Test.sol";
import {InheritanceManager} from "../src/InheritanceManager.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";

contract InheritanceManagerTest is Test {
    InheritanceManager im;
    ERC20Mock usdc;
    ERC20Mock weth;

    address owner = makeAddr("owner");
    address user1 = makeAddr("user1");

    function setUp() public {
        vm.prank(owner);
        im = new InheritanceManager();
        usdc = new ERC20Mock();
        weth = new ERC20Mock();
    }

    function test_invalid_beneficiary() public {
        address user2 = makeAddr("user2");
        vm.startPrank(owner);
        // Only one beneficiary is set
        im.addBeneficiary(user1);
        vm.stopPrank();

        vm.warp(1);
        vm.deal(address(im), 9e18);
        vm.warp(1 + 90 days);

        // After 90 days, user2 (who is not the beneficiary or the original owner) can inherit the contract
        vm.startPrank(user2);
        im.inherit();
        vm.stopPrank();

        assertEq(im.getOwner(), user2); // Ownership was wrongly transferred to user2
    }
}
```

## Impact

This vulnerability enables any attacker to steal contract ownership if there is only one beneficiary. The intended beneficiary can be front-run, causing a complete loss of control over the contract and any assets it holds.

## Tools Used

* Manual code review

- Foundry for Solidity testing

## Recommendations

To prevent unauthorized ownership claims, add a check before assigning a new owner:

```Solidity
function inherit() external {
    if (block.timestamp < getDeadline()) {
        revert InactivityPeriodNotLongEnough();
    }
    if (beneficiaries.length == 1) {
        // ✅ Ensure only the beneficiary can claim ownership
        require(msg.sender == beneficiaries[0], "Not a valid beneficiary.");
        owner = msg.sender;
        _setDeadline();
    } else if (beneficiaries.length > 1) {
        isInherited = true;
    } else {
        revert InvalidBeneficiaries();
    }
}
```


## <a id='H-02'></a>H-02. Transaction Blocking by Malicious Beneficiary            



## Summary

In `src/InheritanceManager.sol`, the `withdrawInheritedFunds` function sends `amountPerBeneficiary` to each beneficiary in a loop. However, if one of the beneficiaries intentionally reverts the transaction (e.g., via a fallback function), it will block the entire distribution, preventing all beneficiaries from receiving their share of the assets.

## Vulnerability Details

In [InheritanceManager.sol#L236](https://github.com/CodeHawks-Contests/2025-03-inheritable-smart-contract-wallet/blob/main/src/InheritanceManager.sol#L236), the contract sends ETH or ERC20 tokens to each beneficiary using a passive distribution method. If a malicious beneficiary intentionally reverts, the entire loop fails, blocking payments to all beneficiaries.

Here is the affected code:

```Solidity
function withdrawInheritedFunds(address _asset) external {
    if (!isInherited) {
        revert NotYetInherited();
    }
    uint256 divisor = beneficiaries.length;
    if (_asset == address(0)) {
        uint256 ethAmountAvailable = address(this).balance;
        uint256 amountPerBeneficiary = ethAmountAvailable / divisor;
        for (uint256 i = 0; i < divisor; i++) {
            address payable beneficiary = payable(beneficiaries[i]);
            (bool success,) = beneficiary.call{value: amountPerBeneficiary}("");
            require(success, "something went wrong");
        }
    } else {
        uint256 assetAmountAvailable = IERC20(_asset).balanceOf(address(this));
        uint256 amountPerBeneficiary = assetAmountAvailable / divisor;
        for (uint256 i = 0; i < divisor; i++) {
            IERC20(_asset).safeTransfer(beneficiaries[i], amountPerBeneficiary);
        }
    }
}
```

## PoC

The following test case demonstrates how a malicious beneficiary can block the **withdrawal** process:

```Solidity
// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;
​
import {Test, console} from "forge-std/Test.sol";
import {InheritanceManager} from "../src/InheritanceManager.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";
​
contract InheritanceManagerTest is Test {
    InheritanceManager im;
    ERC20Mock usdc;
    ERC20Mock weth;
​
    address owner = makeAddr("owner");
    address user1 = makeAddr("user1");
​
    function setUp() public {
        vm.prank(owner);
        im = new InheritanceManager();
        usdc = new ERC20Mock();
        weth = new ERC20Mock();
    }
​
    function test_MaliciousBeneficiaryBlocksAll() public {
        MaliciousBeneficiary malicious;
        malicious = new MaliciousBeneficiary();
        vm.startPrank(owner);
        im.addBeneficiery(user1);
        im.addBeneficiery(payable(address(malicious)));
        vm.stopPrank();
        vm.warp(1);
        vm.deal(address(im), 1e18);
        vm.warp(1 + 90 days); // Trigger inheritance period
        vm.startPrank(user1);
        im.inherit();
        
        // This will fail because of the malicious beneficiary
        vm.expectRevert("something went wrong");
        im.withdrawInheritedFunds(address(0));
        vm.stopPrank();
​
        // Confirm no one received their share
        assertEq(user1.balance, 0);
        assertEq(address(malicious).balance, 0);
    }
}
​
contract MaliciousBeneficiary {
    // This fallback will revert any received ETH
    fallback() external payable {
        revert("Blocked transfer");
    }
}
```

## Impact

* Funds Lockup: A malicious beneficiary can prevent all other beneficiaries from receiving their rightful share.

- Denial of Service (DoS): Any beneficiary with a reverting fallback can block withdrawals indefinitely.

* Broken Functionality: The inheritance process becomes unusable, as no funds can be distributed.

## Tools Used

* Manual code review

- Foundry for Solidity testing

## Recommendations

Change from Passive to Active Distribution:

Instead of forcing payment during the loop (passive model), allow each beneficiary to claim their portion (active model). This prevents one malicious actor from blocking others.

## <a id='H-03'></a>H-03. Incorrect Beneficiary Payment Logic in `buyOutEstateNFT` Function            



## Summary

In `src/InheritanceManager.sol`, the `buyOutEstateNFT` function allows a beneficiary to buy out an estate NFT by transferring tokens to other beneficiaries. However, the current implementation incorrectly uses a `return` statement when the buyer is identified, causing some remaining beneficiaries to not receive their share of the payment.

## Vulnerability Details

In [InheritanceManager.sol#L263](https://github.com/CodeHawks-Contests/2025-03-inheritable-smart-contract-wallet/blob/main/src/InheritanceManager.sol#L263), the `buyOutEstateNFT` function transfers tokens from the buyer to the contract and attempts to distribute these tokens to other beneficiaries. However, when the buyer is found in the beneficiary list, the function exits immediately due to the `return` statement, preventing further iterations and leaving some beneficiaries unpaid.

Here is the affected code:

```Solidity
function buyOutEstateNFT(uint256 _nftID) external onlyBeneficiaryWithIsInherited {
    uint256 value = nftValue[_nftID];
    uint256 divisor = beneficiaries.length;
    uint256 multiplier = beneficiaries.length - 1;
    uint256 finalAmount = (value / divisor) * multiplier;
    IERC20(assetToPay).safeTransferFrom(msg.sender, address(this), finalAmount);
    for (uint256 i = 0; i < beneficiaries.length; i++) {
        if (msg.sender == beneficiaries[i]) {
            return; // ❌ Exits early, leaving later beneficiaries unpaid
        } else {
            IERC20(assetToPay).safeTransfer(beneficiaries[i], finalAmount / divisor);
        }
    }
    nft.burnEstate(_nftID);
}
```

## PoC

The following test case demonstrates that when a beneficiary buys out the NFT, any beneficiaries after their position in the list will not receive their share of the payment:

```Solidity
// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;
​
import {Test, console} from "forge-std/Test.sol";
import {InheritanceManager} from "../../src/2025-03-inheritable-smart-contract-wallet/InheritanceManager.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";
​
contract InheritanceManagerTest is Test {
    InheritanceManager im;
    ERC20Mock usdc;
​
    address owner = makeAddr("owner");
    address user1 = makeAddr("user1");
    address user2 = makeAddr("user2");
    address user3 = makeAddr("user3");
​
    function setUp() public {
        vm.prank(owner);
        im = new InheritanceManager();
        usdc = new ERC20Mock();
​
        // Set up beneficiaries and create estate NFT
        im.addBeneficiery(user1);
        im.addBeneficiery(user2);
        im.addBeneficiery(user3);
        im.createEstateNFT("our beach-house", 3e6, address(usdc));
​
        // Mint USDC to user1
        usdc.mint(user1, 4e6);
    }
​
    function test_buyOutEstateNFTOrderedFailed() public {
        vm.warp(1 + 90 days); // Simulate time passing for inheritance
        vm.startPrank(user1);
        usdc.approve(address(im), 4e6);
        im.inherit(); // Trigger inheritance
        im.buyOutEstateNFT(1); // user1 buys the NFT
        vm.stopPrank();
​
        // ❌ user2 and user3 should receive their share, but they don't
        assertEq(usdc.balanceOf(user2), 0);
        assertEq(usdc.balanceOf(user3), 0);
    }
}
```

## Impact

* Partial Payment Failure: If a beneficiary buys out the estate NFT and is not the last in the list, any beneficiaries after them will not receive their share of the payment.
* Loss of Funds: This results in funds being incorrectly retained within the contract rather than distributed to the rightful beneficiaries.

## Tools Used

* Manual code review

- Foundry for Solidity testing

## Recommendations

To fix the issue, replace the `return` statement with `continue` to ensure that all other beneficiaries still receive their share of the payment:

```Solidity
function buyOutEstateNFT(uint256 _nftID) external onlyBeneficiaryWithIsInherited {
    uint256 value = nftValue[_nftID];
    uint256 divisor = beneficiaries.length;
    uint256 multiplier = beneficiaries.length - 1;
    uint256 finalAmount = (value / divisor) * multiplier;
    IERC20(assetToPay).safeTransferFrom(msg.sender, address(this), finalAmount);
​
    for (uint256 i = 0; i < beneficiaries.length; i++) {
        if (msg.sender == beneficiaries[i]) {
            continue; // ✅ Continue to ensure all other beneficiaries are paid
        }
        IERC20(assetToPay).safeTransfer(beneficiaries[i], finalAmount / divisor);
    }
    nft.burnEstate(_nftID);
}
```

## <a id='H-04'></a>H-04. Lack of Ownership Transfer in `buyOutEstateNFT` Function            



## Summary

In `src/InheritanceManager.sol`, the `buyOutEstateNFT` function allows a beneficiary to buy out an estate NFT by transferring tokens to other beneficiaries. However, after the payment is completed, the function burns the NFT instead of transferring ownership to the buyer. This results in the buyer losing their claim to the estate despite successfully paying for it.

## Vulnerability Details

In [InheritanceManager.sol#L263](https://github.com/CodeHawks-Contests/2025-03-inheritable-smart-contract-wallet/blob/main/src/InheritanceManager.sol#L263), the `buyOutEstateNFT` function facilitates the payment process but does not correctly update the NFT ownership.

Here is the affected code:

```Solidity
function buyOutEstateNFT(uint256 _nftID) external onlyBeneficiaryWithIsInherited {
    uint256 value = nftValue[_nftID];
    uint256 divisor = beneficiaries.length;
    uint256 multiplier = beneficiaries.length - 1;
    uint256 finalAmount = (value / divisor) * multiplier;
    IERC20(assetToPay).safeTransferFrom(msg.sender, address(this), finalAmount);
    for (uint256 i = 0; i < beneficiaries.length; i++) {
        if (msg.sender == beneficiaries[i]) {
            return; // ❌ Incorrectly exits the loop, NFT is not transferred
        } else {
            IERC20(assetToPay).safeTransfer(beneficiaries[i], finalAmount / divisor);
        }
    }
    nft.burnEstate(_nftID); // ❌ NFT is burned, buyer loses their claim
}
```

## Impact

* Loss of Ownership: After completing the payment, the buyer does not receive the estate NFT.
* Irrecoverable Asset Destruction: The NFT is permanently burned, meaning the buyer cannot claim the estate.
* Financial Loss: A paying beneficiary loses both the tokens spent on the buyout and the estate NFT.

## Tools Used

* Manual code review

## Recommendations

Instead of burning the estate NFT, transfer it to the buyer after the payment is processed.

Here is the fixed code:

```Solidity
function buyOutEstateNFT(uint256 _nftID) external onlyBeneficiaryWithIsInherited {
    uint256 value = nftValue[_nftID];
    uint256 divisor = beneficiaries.length;
    uint256 multiplier = beneficiaries.length - 1;
    uint256 finalAmount = (value / divisor) * multiplier;
    IERC20(assetToPay).safeTransferFrom(msg.sender, address(this), finalAmount);
​
    for (uint256 i = 0; i < beneficiaries.length; i++) {
        if (msg.sender == beneficiaries[i]) {
            // ✅ Transfer the NFT to the buyer
            nft.safeTransferFrom(address(this), msg.sender, _nftID);
        } else {
            IERC20(assetToPay).safeTransfer(beneficiaries[i], finalAmount / divisor);
        }
    }
}
```

    


# Low Risk Findings

## <a id='L-01'></a>L-01. Dust Accumulation in `withdrawInheritedFunds` Function            



## Summary

In `src/InheritanceManager.sol`, the `withdrawInheritedFunds` function distributes the contract’s remaining assets equally among the beneficiaries. However, if the total asset amount is not perfectly divisible by the number of beneficiaries, residual dust (leftover assets) remains trapped in the contract, leading to fund lockup.

## Vulnerability Details

In [InheritanceManager.sol#L236](https://github.com/CodeHawks-Contests/2025-03-inheritable-smart-contract-wallet/blob/main/src/InheritanceManager.sol#L236), the `withdrawInheritedFunds` function calculates the share per beneficiary using integer division, which truncates any remainder.

Consider the following code snippet:

```Solidity
function withdrawInheritedFunds(address _asset) external {
    if (!isInherited) {
        revert NotYetInherited();
    }
    uint256 divisor = beneficiaries.length;
    if (_asset == address(0)) {
        uint256 ethAmountAvailable = address(this).balance;
        uint256 amountPerBeneficiary = ethAmountAvailable / divisor;
        for (uint256 i = 0; i < divisor; i++) {
            address payable beneficiary = payable(beneficiaries[i]);
            (bool success,) = beneficiary.call{value: amountPerBeneficiary}("");
            require(success, "something went wrong");
        }
    } else {
        uint256 assetAmountAvailable = IERC20(_asset).balanceOf(address(this));
        uint256 amountPerBeneficiary = assetAmountAvailable / divisor;
        for (uint256 i = 0; i < divisor; i++) {
            IERC20(_asset).safeTransfer(beneficiaries[i], amountPerBeneficiary);
        }
    }
}
```

When the contract holds assets that cannot be evenly divided, the leftover value (i.e., dust) remains locked because the calculation only distributes the integer portion.

## PoC

The following Foundry test demonstrates the issue:

```Solidity
// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Test, console} from "forge-std/Test.sol";
import {InheritanceManager} from "../src/InheritanceManager.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";

contract InheritanceManagerTest is Test {
    InheritanceManager im;
    ERC20Mock usdc;
    ERC20Mock weth;

    address owner = makeAddr("owner");
    address user1 = makeAddr("user1");

    function setUp() public {
        vm.prank(owner);
        im = new InheritanceManager();
        usdc = new ERC20Mock();
        weth = new ERC20Mock();
    }

    function test_withdrawInheritedFundsEtherDust() public {
        address user2 = makeAddr("user2");
        address user3 = makeAddr("user3");
        
        vm.startPrank(owner);
        im.addBeneficiary(user1);
        im.addBeneficiary(user2);
        im.addBeneficiary(user3);
        vm.stopPrank();

        vm.warp(1);
        vm.deal(address(im), 1e18); // 1 Ether (not a multiple of 3)
        vm.warp(1 + 90 days);

        vm.startPrank(user1);
        im.inherit();
        im.withdrawInheritedFunds(address(0));
        vm.stopPrank();

        // Check if dust remains in the contract
        assertEq(1, address(im).balance); // 1 Wei remains trapped
    }
}
```

## Impact

* Residual Dust: Small fractions of ETH or ERC20 tokens may remain stuck in the contract.

- Fund Inefficiency: This leads to imperfect fund distribution, causing permanent lockup of unclaimed funds.

* Gas Wastage: Beneficiaries may attempt repeated withdrawals to retrieve the dust unsuccessfully.

## Tools Used

* Manual code review

- Foundry for Solidity testing

## Recommendations

To prevent dust accumulation, track the remaining balance and assign all leftover assets to the last beneficiary:

```Solidity
function withdrawInheritedFunds(address _asset) external {
    if (!isInherited) {
        revert NotYetInherited();
    }
    uint256 divisor = beneficiaries.length;
    if (_asset == address(0)) {
        uint256 ethAmountAvailable = address(this).balance;
        uint256 amountPerBeneficiary = ethAmountAvailable / divisor;
​
        for (uint256 i = 0; i < divisor; i++) {
            if (i == divisor - 1) {
                // Give the last beneficiary the remaining dust
                amountPerBeneficiary = ethAmountAvailable;
            } else {
                ethAmountAvailable -= amountPerBeneficiary;
            }
​
            address payable beneficiary = payable(beneficiaries[i]);
            (bool success, ) = beneficiary.call{value: amountPerBeneficiary}("");
            require(success, "Transfer failed");
        }
    } else {
        uint256 assetAmountAvailable = IERC20(_asset).balanceOf(address(this));
        uint256 amountPerBeneficiary = assetAmountAvailable / divisor;
​
        for (uint256 i = 0; i < divisor; i++) {
            if (i == divisor - 1) {
                // Handle dust for ERC20 tokens
                amountPerBeneficiary = assetAmountAvailable;
            } else {
                assetAmountAvailable -= amountPerBeneficiary;
            }
​
            IERC20(_asset).safeTransfer(beneficiaries[i], amountPerBeneficiary);
        }
    }
}
```

Although it is unfair to give the dust to a single beneficiary, this ensures that no assets remain trapped. This implementation guarantees that the contract fully distributes all available funds.



