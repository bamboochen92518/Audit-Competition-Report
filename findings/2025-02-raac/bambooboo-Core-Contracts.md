# Core Contracts - Findings Report

# Table of contents
- ## [Contest Summary](#contest-summary)
- ## [Results Summary](#results-summary)
- ## High Risk Findings
    - ### [H-01. `calculateTimeWeightedAverage` Fails to Correctly Handle Overlapping Periods](#H-01)
    - ### [H-02. Incorrect Fee Percentage Calculation in `FeeCollector.sol`](#H-02)
    - ### [H-03. Wrong Implementation in `_updateWeights`](#H-03)
- ## Medium Risk Findings
    - ### [M-01. Unchecked Overflow in `self.weightedSum` of `updateValue` Function](#M-01)
    - ### [M-02. `collectFee` Doesn't Follow the CEI Principle](#M-02)
    - ### [M-03. Possibly Wrong Implementation in `claimRewards`](#M-03)
    - ### [M-04. Incorrect Token Valuation in `Treasury.sol`](#M-04)
    - ### [M-05. Inconsistent Error Handling in `BoostController.sol`](#M-05)
    - ### [M-06. Incorrect Error Message in `updateUserBoost`](#M-06)
    - ### [M-07. Missing Pool Support Check in `getUserBoost`](#M-07)



# <a id='contest-summary'></a>Contest Summary

### Sponsor: Regnum Aurum Acquisition Corp

### Dates: Feb 3rd, 2025 - Feb 24th, 2025

[See more contest details here](https://codehawks.cyfrin.io/c/2025-02-raac)

# <a id='results-summary'></a>Results Summary

### Number of findings:
- High: 3
- Medium: 7
- Low: 0


# High Risk Findings

## <a id='H-01'></a>H-01. `calculateTimeWeightedAverage` Fails to Correctly Handle Overlapping Periods            



## Summary

The function `calculateTimeWeightedAverage` in `contracts/libraries/math/TimeWeightedAverage.sol` is advertised as capable of handling both sequential and overlapping periods with associated weights. However, the function currently fails to handle overlapping periods correctly, leading to inaccurate Time-Weighted Average Price (TWAP) calculations.

## Vulnerability Details

In [TimeWeightedAverage.sol#L194](https://github.com/Cyfrin/2025-02-raac/blob/89ccb062e2b175374d40d824263a4c0b601bcb7f/contracts/libraries/math/TimeWeightedAverage.sol#L194), the `calculateTimeWeightedAverage` function is intended to compute the TWAP by considering multiple periods with their corresponding weights. However, the function assumes that periods do not overlap, which results in an incorrect calculation when periods do overlap.

In the example provided, two periods have identical start and end times, causing them to overlap. As a result, the TWAP is computed incorrectly because the function does not account for the overlap and treats the periods as separate. The function does not merge overlapping periods before calculating the weighted average.

### Proof of Concept (PoC)

```Solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "src/2025-02-raac/contracts/libraries/math/TimeWeightedAverage.sol";
import {Test, console} from 'forge-std/Test.sol';

contract testRAACTWAP {
    function testCalculateTWAP() external pure {
        TimeWeightedAverage.PeriodParams;
        
        // periods[0] and periods[1] overlap
        periods[0] = TimeWeightedAverage.PeriodParams({startTime: 1, endTime: 4, value: 100, weight: 1e18});
        periods[1] = TimeWeightedAverage.PeriodParams({startTime: 1, endTime: 4, value: 100, weight: 1e18});
        periods[2] = TimeWeightedAverage.PeriodParams({startTime: 5, endTime: 8, value: 130, weight: 1e18});
        
        uint256 TWAP = TimeWeightedAverage.calculateTimeWeightedAverage(periods, 8);
        
        // The TWAP should be 115 instead of 110 since (100 + 130) / 2 = 115
        // However, the function fails to handle overlapping periods, leading to an incorrect result
        assert(TWAP == 110);
    }
}
```

In this example, periods 0 and 1 overlap, both starting at time 1 and ending at time 4. The expected TWAP for these periods should be 115, calculated as the average of the values 100 (from periods 0 and 1) and 130 (from period 2). However, since the function does not handle overlapping periods correctly, the result is incorrectly computed as 110, effectively double-counting the value from time 1 to time 4.

## Impact

The failure of the `calculateTimeWeightedAverage` function to correctly handle overlapping periods can lead to inaccurate TWAP calculations. Inaccurate TWAP values may cause financial losses or incorrect decisions to be made based on faulty data. This vulnerability is particularly impactful in decentralized finance (DeFi) protocols or applications that rely on accurate price or value calculations.

## Tools Used

* Manual code review
* Foundry (for testing and verification)

## Recommendations

* Modify the `calculateTimeWeightedAverage` function to properly handle overlapping periods by merging them before performing the TWAP calculation.
* Implement checks to detect overlapping periods and ensure they are handled correctly, such as merging periods with identical start and end times.
* Test the function thoroughly with various overlapping and sequential periods to ensure that the TWAP calculation is robust and accurate under all scenarios.

## <a id='H-02'></a>H-02. Incorrect Fee Percentage Calculation in `FeeCollector.sol`            



## Summary

In `FeeCollector.sol`, the fee allocation values for Buy/Sell Swap Tax and NFT Royalty Fees are incorrectly set. The contract defines 10,000 as 100%, meaning that 0.5% should correspond to 50, not 500, and 1% should correspond to 100, not 1000. This miscalculation leads to an overestimation of fee allocations, potentially affecting the distribution of funds.

## Vulnerability Details

In [FeeCollector.sol#L379](https://github.com/Cyfrin/2025-02-raac/blob/main/contracts/core/collectors/FeeCollector.sol#L379), the fee allocation is defined as follows:

```Solidity
// Buy/Sell Swap Tax (2% total)
feeTypes[6] = FeeType({
    veRAACShare: 500,     // 0.5%
    burnShare: 500,       // 0.5%
    repairShare: 1000,    // 1.0%
    treasuryShare: 0
});
​
// NFT Royalty Fees (2% total)
feeTypes[7] = FeeType({
    veRAACShare: 500,     // 0.5%
    burnShare: 0,
    repairShare: 1000,    // 1.0%
    treasuryShare: 500    // 0.5%
});
```

Since 10,000 represents 100%, the correct values should be:

* 0.5% → 50 instead of 500
* 1% → 100 instead of 1000

Due to this incorrect scaling, the fee percentages are 10 times higher than intended, potentially diverting more funds than expected.

## Impact

The miscalculation inflates the actual fee deductions, leading to excessive allocations for veRAAC, burn, repair, and treasury shares. This could result in an imbalance in fund distribution, affecting the contract's financial operations and user expectations.

## Tools Used

Manual code review.

## Recommendations

Adjust the fee allocation values to correctly reflect the intended percentages:

```Solidity
// Buy/Sell Swap Tax (2% total)
feeTypes[6] = FeeType({
    veRAACShare: 50,     // 0.5%
    burnShare: 50,       // 0.5%
    repairShare: 100,    // 1.0%
    treasuryShare: 0
});
​
// NFT Royalty Fees (2% total)
feeTypes[7] = FeeType({
    veRAACShare: 50,     // 0.5%
    burnShare: 0,
    repairShare: 100,    // 1.0%
    treasuryShare: 50    // 0.5%
});
```

By correcting the values, the contract will allocate fees as intended, ensuring proper fund distribution.

## <a id='H-03'></a>H-03. Wrong Implementation in `_updateWeights`            



## Summary

The `_updateWeights` function in `BaseGauge.sol` does not handle the initial period differently from subsequent periods, despite an `if-else` clause intended to do so. Both branches of the conditional statement execute the same logic, making the distinction redundant and potentially misleading.

## Vulnerability Details

In [BaseGauge.sol#L185](https://github.com/Cyfrin/2025-02-raac/blob/main/contracts/core/governance/gauges/BaseGauge.sol#L185), the `_updateWeights` function contains an `if-else` clause that appears to differentiate between the initial period and subsequent periods. However, both branches execute identical logic, as seen in the code snippet below:

```Solidity
function _updateWeights(uint256 newWeight) internal {
        uint256 currentTime = block.timestamp;
        uint256 duration = getPeriodDuration();
        
        if (weightPeriod.startTime == 0) {
            // For initial period, start from next period boundary
            uint256 nextPeriodStart = ((currentTime / duration) + 1) * duration;
            TimeWeightedAverage.createPeriod(
                weightPeriod,
                nextPeriodStart,
                duration,
                newWeight,
                WEIGHT_PRECISION
            );
        } else {
            // For subsequent periods, ensure we're creating a future period
            uint256 nextPeriodStart = ((currentTime / duration) + 1) * duration;
            TimeWeightedAverage.createPeriod(
                weightPeriod,
                nextPeriodStart,
                duration,
                newWeight,
                WEIGHT_PRECISION
            );
        }
    }
```

Both the `if` and `else` branches compute `nextPeriodStart` using the same formula and call `TimeWeightedAverage.createPeriod` with identical parameters. This redundancy suggests either an incorrect implementation or unnecessary complexity.

## Impact

* **Code Maintainability:** The redundant `if-else` structure makes the code harder to understand and maintain, as it suggests a distinction that does not actually exist.
* **Potential Logic Error:** If different logic is required for the initial period, the current implementation fails to account for it, which could lead to unintended behavior.
* **Gas Inefficiency:** The extra condition check adds a minor but unnecessary computational cost to function execution.

## Tools Used

Manual code review.

## Recommendations

* If there is no actual difference between the initial and subsequent periods, remove the redundant `if-else` clause and simplify the function:

```Solidity
function _updateWeights(uint256 newWeight) internal {
    uint256 currentTime = block.timestamp;
    uint256 duration = getPeriodDuration();
    uint256 nextPeriodStart = ((currentTime / duration) + 1) * duration;
    
    TimeWeightedAverage.createPeriod(
        weightPeriod,
        nextPeriodStart,
        duration,
        newWeight,
        WEIGHT_PRECISION
    );
}
```

* If the intention was to handle the initial period differently, introduce logic that truly differentiates between the two cases. For example, the initial period might require an immediate start rather than waiting for the next period boundary.
* Conduct further testing to confirm whether the intended behavior aligns with the actual implementation.

    
# Medium Risk Findings

## <a id='M-01'></a>M-01. Unchecked Overflow in `self.weightedSum` of `updateValue` Function            



## Summary

In `contracts/libraries/math/TimeWeightedAverage.sol`, the function `updateValue` uses `unchecked` for updates but does not verify whether `self.weightedSum` will overflow. This could lead to serious issues if the value exceeds the maximum limit of `uint256`.

## Vulnerability Details

In [TimeWeightedAverage.sol#L134](https://github.com/Cyfrin/2025-02-raac/blob/89ccb062e2b175374d40d824263a4c0b601bcb7f/contracts/libraries/math/TimeWeightedAverage.sol#L134), the function `updateValue` computes a `timeWeightedValue` and adds it to `self.weightedSum`. However, the code does not check whether this addition causes an overflow.

```Solidity
function updateValue(
    Period storage self,
    uint256 newValue,
    uint256 timestamp
) internal {
    if (timestamp < self.startTime || timestamp > self.endTime) {
        revert InvalidTime();
    }
​
    unchecked {
        uint256 duration = timestamp - self.lastUpdateTime;
        if (duration > 0) {
            uint256 timeWeightedValue = self.value * duration;
            if (timeWeightedValue / duration != self.value) revert ValueOverflow();
            
            // Missing check for overflow when updating weightedSum
            self.weightedSum += timeWeightedValue;
            self.totalDuration += duration;
        }
    }
​
    self.value = newValue;
    self.lastUpdateTime = timestamp;
}
```

When `self.weightedSum` is updated, it does not verify whether the sum exceeds `uint256`'s maximum value, which could lead to an overflow.

## Impact

If an overflow occurs, it can lead to unintended behavior, incorrect TWAP calculations, and potentially cause loss of funds or incorrect trading decisions in protocols relying on this function.

## Tools Used

Manual code review

## Recommendations

Before adding `timeWeightedValue` to `self.weightedSum`, a check should be added to prevent overflow:

```Solidity
if (self.weightedSum + timeWeightedValue < self.weightedSum) revert ValueOverflow();
```

The corrected function:

```Solidity
function updateValue(
    Period storage self,
    uint256 newValue,
    uint256 timestamp
) internal {
    if (timestamp < self.startTime || timestamp > self.endTime) {
        revert InvalidTime();
    }
​
    unchecked {
        uint256 duration = timestamp - self.lastUpdateTime;
        if (duration > 0) {
            uint256 timeWeightedValue = self.value * duration;
            if (timeWeightedValue / duration != self.value) revert ValueOverflow();
            
            if (self.weightedSum + timeWeightedValue < self.weightedSum) revert ValueOverflow();
            
            self.weightedSum += timeWeightedValue;
            self.totalDuration += duration;
        }
    }
​
    self.value = newValue;
    self.lastUpdateTime = timestamp;
}
```

This ensures that the update does not cause an overflow, improving the function's safety and reliability.

## <a id='M-02'></a>M-02. `collectFee` Doesn't Follow the CEI Principle            



## Summary

The function `collectFee` in `FeeCollector.sol` does not follow the Checks-Effects-Interactions (CEI) principle, which is a best practice in Solidity to prevent reentrancy and other vulnerabilities. Although the function is protected by the `nonReentrant` modifier, it still performs an external call (a token transfer) before updating the contract's internal state. This can lead to potential issues, including reentrancy vulnerabilities if `nonReentrant` is removed in future updates or interactions with untrusted tokens.

## Vulnerability Details

In [FeeCollector.sol#L162](https://github.com/Cyfrin/2025-02-raac/blob/main/contracts/core/collectors/FeeCollector.sol#L162), the `collectFee` function is responsible for collecting fees in `raacToken`. However, it does not follow the CEI pattern, as it interacts with an external contract before updating internal state variables.

```Solidity
function collectFee(uint256 amount, uint8 feeType) external override nonReentrant whenNotPaused returns (bool) {
    if (amount == 0 || amount > MAX_FEE_AMOUNT) revert InvalidFeeAmount();
    if (feeType > 7) revert InvalidFeeType();
    
    // External interaction before updating contract state
    raacToken.safeTransferFrom(msg.sender, address(this), amount);
    
    // Internal state update happens after external call
    _updateCollectedFees(amount, feeType);
    
    emit FeeCollected(feeType, amount);
    return true;
}
```

The function calls an external contract (`safeTransferFrom`) before updating the contract's internal state. Although the `nonReentrant` modifier prevents direct reentrancy attacks, it is still considered best practice to follow the CEI principle to minimize risks.

## Impact

If the function is modified in the future and `nonReentrant` is removed or bypassed, an attacker could exploit this issue to reenter the contract before the state is updated. Additionally, interacting with an untrusted `ERC20` token that has custom logic in `transferFrom` could cause unpredictable behavior, leading to incorrect fee tracking or failed transactions.

## Tools Used

Manual code review

## Recommendations

To follow the CEI principle, the function should first update the contract’s internal state and then perform the external token transfer. This ensures that even if an external call behaves unexpectedly, the contract remains in a consistent state.

The updated version is shown below:

```Solidity
function collectFee(uint256 amount, uint8 feeType) external override nonReentrant whenNotPaused returns (bool) {
    if (amount == 0 || amount > MAX_FEE_AMOUNT) revert InvalidFeeAmount();
    if (feeType > 7) revert InvalidFeeType();
    
    // Update internal state first
    _updateCollectedFees(amount, feeType);
    
    // Only then perform external interaction
    raacToken.safeTransferFrom(msg.sender, address(this), amount);
    
    emit FeeCollected(feeType, amount);
    return true;
}
```

By making this change, the contract ensures that its internal state is consistent before making any external calls, reducing risks associated with external dependencies.

## <a id='M-03'></a>M-03. Possibly Wrong Implementation in `claimRewards`            



## Summary

In `FeeCollector.sol`, an internal function `_updateLastClaimTime` is defined in [FeeCollector.sol#L555](https://github.com/Cyfrin/2025-02-raac/blob/main/contracts/core/collectors/FeeCollector.sol#L555), but it is not used in the contract. It seems that this function should be invoked after `claimRewards`, which is defined in [FeeCollector.sol#L199](https://github.com/Cyfrin/2025-02-raac/blob/main/contracts/core/collectors/FeeCollector.sol#L199), but it is not being called anywhere in the relevant code.

## Vulnerability Details

The `_updateLastClaimTime` function is likely intended to track the time of the user's last reward claim. However, it is not being called after `claimRewards`, meaning the contract does not update the user's last claim time when rewards are claimed. This may lead to inaccurate tracking of claim times and could potentially interfere with future reward calculations or any features that depend on this data.

## Impact

The lack of updating the last claim time could cause incorrect tracking of the user's rewards, leading to issues such as incorrect reward calculations or user experience inconsistencies. If the function was intended for accurate reward claiming logic (e.g., for future reward claims or bonus calculations), its omission could lead to bugs or unintended behavior.

## Tools Used

Manual code review.

## Recommendations

To fix this issue, you should call `_updateLastClaimTime` after the rewards are successfully transferred in the `claimRewards` function. The modified code would look like this:

```Solidity
function claimRewards(address user) external override nonReentrant whenNotPaused returns (uint256) {
    if (user == address(0)) revert InvalidAddress();
    
    uint256 pendingReward = _calculatePendingRewards(user);
    if (pendingReward == 0) revert InsufficientBalance();
    
    // Reset user rewards before transfer
    userRewards[user] = totalDistributed;
    
    // Add part: update last claim time
    _updateLastClaimTime(user);
    
    // Transfer rewards
    raacToken.safeTransfer(user, pendingReward);
    
    emit RewardClaimed(user, pendingReward);
    return pendingReward;
}
```

By including the `_updateLastClaimTime` call, the contract will correctly track the last time a user claimed rewards, improving the reliability of the reward system.


## <a id='M-04'></a>M-04. Incorrect Token Valuation in `Treasury.sol`            



## Summary

In `contracts/core/collectors/Treasury.sol`, the internal variable `_totalValue` is used to track the total value across all tokens. However, the contract assumes that all tokens have the same value, which is incorrect and can lead to inaccurate accounting of treasury assets.

## Vulnerability Details

The `_totalValue` variable is updated in the `deposit` and `withdraw` functions as follows:

```Solidity
_totalValue += amount;
_totalValue -= amount;
```

This implementation fails to account for the differing values of tokens. It assumes that all deposited and withdrawn tokens have the same unit value, which is not the case in real-world scenarios where token prices fluctuate. As a result, `_totalValue` does not reflect the true value of the treasury’s holdings.

## Impact

This vulnerability can lead to:

* Inaccurate tracking of the total treasury value.
* Potential mismanagement of funds due to incorrect value representation.

## Tools Used

Manual code review.

## Recommendations

To address this issue, the contract should integrate an oracle to fetch real-time token prices and adjust `_totalValue` accordingly. Instead of directly adding or subtracting the raw `amount`, the contract should compute the value of tokens in a common denomination (e.g., USD or ETH) before updating `_totalValue`.

## <a id='M-05'></a>M-05. Inconsistent Error Handling in `BoostController.sol`            



## Summary

In `contracts/interfaces/core/governance/IBoostController.sol`, the `error PoolNotSupported` is documented to occur when a pool is not in the supported pools list. However, in `contracts/core/governance/boost/BoostController.sol`, this error is actually triggered when an attempt is made to modify a pool's support status, but the status remains unchanged.

## Vulnerability Details

The function `modifySupportedPool` is implemented as follows:

```Solidity
    function modifySupportedPool(address pool, bool isSupported) external onlyRole(MANAGER_ROLE) {
        if (pool == address(0)) revert InvalidPool();
        if (supportedPools[pool] == isSupported) revert PoolNotSupported();
        // ... (ignore the other parts)
    }
```

This logic indicates that `PoolNotSupported` is reverted when the pool's current support status is the same as the requested status, rather than when the pool is not in the supported pools list. This discrepancy between documentation and implementation can lead to confusion and improper handling of errors in dependent contracts.

## Impact

* Misinterpretation of error handling can lead to unintended behavior in governance mechanisms.
* Smart contracts or external integrations relying on `PoolNotSupported` for validation might function incorrectly.
* Potential security risks if error handling is assumed incorrectly in other contract logic.

## Tools Used

Manual code review.

## Recommendations

* **Update the Documentation:** Ensure `IBoostController.sol` accurately reflects the actual behavior of `PoolNotSupported` in `BoostController.sol`.
* **Introduce a More Descriptive Error:** Consider adding a new error type, such as `PoolStatusUnchanged`, to clearly indicate the specific condition.
* **Refactor the Function Logic (if necessary):** If `PoolNotSupported` is meant to indicate an entirely different scenario, update the function implementation accordingly to maintain consistency.

## <a id='M-06'></a>M-06. Incorrect Error Message in `updateUserBoost`            



## Summary

In `updateUserBoost` [BoostController.sol#L179](https://github.com/Cyfrin/2025-02-raac/blob/main/contracts/core/governance/boost/BoostController.sol#L179), the following line is present:

```Solidity
if (user == address(0)) revert InvalidPool();
```

However, this check is intended to validate the user address rather than the pool, making the error message misleading.

## Vulnerability Details

The function `updateUserBoost` includes a validation check to ensure that the `user` address is not zero. However, the error message `InvalidPool()` suggests that the issue pertains to the pool rather than the user. This can cause confusion during debugging and may mislead developers when identifying the root cause of failures.

## Impact

* Misleading error messages can lead to incorrect debugging and extended troubleshooting time.
* Developers may misinterpret the nature of the failure, possibly overlooking the real issue.

## Tools Used

Manual code review.

## Recommendations

* Modify the revert statement to provide a more accurate error message, such as:

```Solidity
if (user == address(0)) revert InvalidUser();
```

* Ensure that error messages accurately describe the condition being checked to improve code clarity and maintainability.

## <a id='M-07'></a>M-07. Missing Pool Support Check in `getUserBoost`            



## Summary

The function `getUserBoost` in `BoostController.sol` does not verify whether the specified pool is supported before executing its logic. This oversight may lead to unintended behavior when interacting with unsupported pools.

## Vulnerability Details

In [BoostController.sol#L304](https://github.com/Cyfrin/2025-02-raac/blob/main/contracts/core/governance/boost/BoostController.sol#L304), the function `getUserBoost` lacks a check to ensure that the provided pool exists in the `supportedPools` mapping. As a result, calling `getUserBoost` with an unsupported pool address may cause unexpected results or inconsistencies in boost calculations.

## Impact

Without verifying the pool's support status, users may attempt to retrieve boost values for non-existent or unauthorized pools. This can lead to incorrect data being used in calculations and may introduce potential security risks if certain operations depend on valid pool verification.

## Tools Used

Manual code review. 

## Recommendations

To mitigate this issue, add a validation check at the beginning of the `getUserBoost` function to ensure that the specified pool is supported:

```Solidity
if (!supportedPools[pool]) revert PoolNotSupported();
```

This change prevents unauthorized or unsupported pools from being used in the function, ensuring that only valid pools are processed.





