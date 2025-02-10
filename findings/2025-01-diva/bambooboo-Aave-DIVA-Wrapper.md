# Aave DIVA Wrapper - Findings Report

# Table of contents
- ## [Contest Summary](#contest-summary)
- ## [Results Summary](#results-summary)
- ## High Risk Findings
    - ### [H-01. Mismatch in Constructor Parameter Order in `AaveDIVAWrapper.sol` and `AaveDIVAWrapperCore.sol`](#H-01)




# <a id='contest-summary'></a>Contest Summary

### Sponsor: DIVA

### Dates: Jan 24th, 2025 - Jan 31st, 2025

[See more contest details here](https://codehawks.cyfrin.io/c/2025-01-diva)

# <a id='results-summary'></a>Results Summary

### Number of findings:
- High: 1
- Medium: 0
- Low: 0


# High Risk Findings

## <a id='H-01'></a>H-01. Mismatch in Constructor Parameter Order in `AaveDIVAWrapper.sol` and `AaveDIVAWrapperCore.sol`            



## Summary

In `AaveDIVAWrapper.sol`, the order of parameters in the constructor specifies the Aave address first, followed by the DIVA address:

```Solidity
constructor(address _aaveV3Pool, address _diva, address _owner) AaveDIVAWrapperCore(_aaveV3Pool, _diva, _owner) {}
```

However, in `AaveDIVAWrapperCore.sol`, the constructor expects the DIVA address first, followed by the Aave address:

```Solidity
constructor(address diva_, address aaveV3Pool_, address owner_) Ownable(owner_)
```

This discrepancy leads to incorrect contract initialization as the parameters are mismatched, resulting in invalid addresses being assigned.

## Vulnerability Details

When deploying `AaveDIVAWrapper`, the incorrect parameter order causes the Aave and DIVA contract addresses to be swapped. This results in:

1. Functionality relying on the Aave or DIVA address failing.
2. Potential misallocation of funds or loss of access to critical resources due to invalid addresses being used in contract interactions.

## Impact

The contract cannot perform as intended, which may lead to severe issues, including:

1. Malfunctioning interactions with the Aave protocol and DIVA.
2. Potentially high financial risk due to misconfigured contract addresses.

## Tools Used

Manual code review.

## Recommendations

Ensure the parameter order in `AaveDIVAWrapper` matches the expected order in `AaveDIVAWrapperCore`. Update `AaveDIVAWrapper` as follows:

```Solidity
constructor(address _diva, address _aaveV3Pool, address _owner) AaveDIVAWrapperCore(_diva, _aaveV3Pool, _owner) {}
```

    





