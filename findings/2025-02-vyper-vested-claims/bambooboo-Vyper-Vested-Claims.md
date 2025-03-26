# Vyper Vested Claims - Findings Report

# Table of contents
- ## [Contest Summary](#contest-summary)
- ## [Results Summary](#results-summary)

- ## Medium Risk Findings
    - ### [M-01. Missing Merkle Proof Verification in claimable_amount](#M-01)



# <a id='contest-summary'></a>Contest Summary

### Sponsor: First Flight #34

### Dates: Feb 20th, 2025 - Feb 27th, 2025

[See more contest details here](https://codehawks.cyfrin.io/c/2025-02-vyper-vested-claims)

# <a id='results-summary'></a>Results Summary

### Number of findings:
- High: 0
- Medium: 1
- Low: 0



    
# Medium Risk Findings

## <a id='M-01'></a>M-01. Missing Merkle Proof Verification in claimable_amount            



## Summary

In `src/VestedAirdrop.vy`, the `claimable_amount` function is responsible for calculating the amount a user can claim. However, the function does not verify the user's proof against the Merkle root, allowing any arbitrary user to query a claimable amount without validating their eligibility. This flaw could mislead users and external systems relying on the function's output.

## Vulnerability Details

In [VestedAirdrop.vy#L176](https://github.com/CodeHawks-Contests/2025-02-vyper-vested-claims/blob/main/src/VestedAirdrop.vy#L176), the `claimable_amount` function is implemented as follows:

```Solidity
def claimable_amount(user: address, total_amount: uint256) -> uint256:
    """
    @notice this function is needed on the frontend to show the claimable amount
    @param user address, the address of the user
    @param total_amount uint256, the total amount of tokens
    @return claimable uint256, the amount of tokens that can be claimed
    @dev the data is NOT verified against the merkle root
    @dev no on-chain contract should/will use this function
    """
    assert block.timestamp >= self.vesting_start_time, "Claiming is not available yet"
​
    claimable:      uint256 = 0
    current_amount: uint256 = self.claimed_amount[user]
    vested:         uint256 = self._calculate_vested_amount(total_amount)
​
    # Calculate how much the user can claim now
    if vested > current_amount:
        claimable = vested - current_amount
​
    return claimable
```

The issue arises because the function does not verify whether the user is eligible to claim tokens via a Merkle proof. Without this check, unauthorized users can receive misleading claimable amounts, potentially causing errors in off-chain systems that trust this function's output. While the function cannot directly lead to unauthorized claims, it may cause confusion and incorrect estimations.

## Impact

1. **Misleading Information**: Users without valid proofs can still query and receive non-zero claimable amounts.
2. **Inaccurate Frontend Display**: Frontend applications relying on this function may display inaccurate claimable amounts.
3. **Integration Errors**: External systems consuming this function's output could make incorrect assumptions, leading to potential errors in downstream logic.

## Tools Used

* Manual code review

## Recommendations

Ensure the function validates the user's eligibility using a Merkle proof before calculating the claimable amount. Below is the revised function with the required proof verification:

**Updated Code**

```Solidity
def claimable_amount(user: address, total_amount: uint256, proof: bytes32[ ] ) -> uint256:
    """
    @notice this function is needed on the frontend to show the claimable amount
    @param user address, the address of the user
    @param total_amount uint256, the total amount of tokens
    @param proof bytes32[], the Merkle proof to verify user eligibility
    @return claimable uint256, the amount of tokens that can be claimed
    @dev Verifies eligibility against the Merkle root
    @dev No on-chain contract should/will use this function
    """
    assert block.timestamp >= self.vesting_start_time, "Claiming is not available yet"

    # Added verification to ensure the user has a valid proof
    if not self.verify_proof(user, total_amount, proof):
        return 0

    claimable:      uint256 = 0
    current_amount: uint256 = self.claimed_amount[user]
    vested:         uint256 = self._calculate_vested_amount(total_amount)

    # Calculate how much the user can claim now
    if vested > current_amount:
        claimable = vested - current_amount

    return claimable
```





