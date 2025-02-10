# Ignite - Findings Report

# Table of contents
- ## [Contest Summary](#contest-summary)
- ## [Results Summary](#results-summary)

- ## Medium Risk Findings
    - ### [M-01. Lack of Validation in `setMaximumSubsidisationAmount` May Lead to DoS](#M-01)



# <a id='contest-summary'></a>Contest Summary

### Sponsor: Benqi

### Dates: Jan 13th, 2025 - Jan 27th, 2025

[See more contest details here](https://codehawks.cyfrin.io/c/2025-01-benqi)

# <a id='results-summary'></a>Results Summary

### Number of findings:
- High: 0
- Medium: 1
- Low: 0



    
# Medium Risk Findings

## <a id='M-01'></a>M-01. Lack of Validation in `setMaximumSubsidisationAmount` May Lead to DoS            



## Summary

In `Ignite.sol`, the `DEFAULT_ADMIN_ROLE` has the ability to set the maximum subsidisation amount using the `setMaximumSubsidisationAmount` function. However, the function does not verify whether the current subsidisation amount is less than or equal to the new maximum subsidisation amount.

## Vulnerability Details

Failing to check this condition could result in inconsistencies, as the system might allow a maximum subsidisation amount that is less than the already subsidised total. This could create a scenario where further operations dependent on this amount are blocked.

## Impact

This vulnerability could lead to a denial of service (DoS) scenario, preventing users from interacting with the contract as expected.

## Tools Used

Manual code review

## Recommendations

Add a validation condition to ensure that the new maximum subsidisation amount is greater than or equal to the current total subsidised amount. For instance:

```Solidity
require(maximumSubsidisationAmount >= totalSubsidisedAmount, "New maximum subsidisation amount must not be less than the current total subsidised amount.");

```

This ensures that the contract remains consistent and avoids potential DoS issues.





