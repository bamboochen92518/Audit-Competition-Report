# Pieces Protocol - Findings Report

# Table of contents
- ## [Contest Summary](#contest-summary)
- ## [Results Summary](#results-summary)
- ## High Risk Findings
    - ### [H-01. Public `mint` Function Lacks Access Control, Allowing Unauthorized ERC20 Minting](#H-01)
    - ### [H-02. Ensure Consistency Between ERC20 Transfers and `TokenDivider` Contract Balances](#H-02)
- ## Medium Risk Findings
    - ### [M-01. Unbounded `s_userToSellOrders[msg.sender]` Leading to Potential High Gas Costs and DoS Risks](#M-01)
    - ### [M-02. Vulnerability in `buyOrder` Function: Potential ERC20 Token Burning Issue](#M-02)
- ## Low Risk Findings
    - ### [L-01. Remove Redundant Condition Checks to Optimize Gas Usage](#L-01)
    - ### [L-02. Optimize Gas Usage by Removing Duplicate Modifiers](#L-02)


# <a id='contest-summary'></a>Contest Summary

### Sponsor: First Flight #32

### Dates: Jan 16th, 2025 - Jan 23rd, 2025

[See more contest details here](https://codehawks.cyfrin.io/c/2025-01-pieces-protocol)

# <a id='results-summary'></a>Results Summary

### Number of findings:
- High: 2
- Medium: 2
- Low: 2


# High Risk Findings

## <a id='H-01'></a>H-01. Public `mint` Function Lacks Access Control, Allowing Unauthorized ERC20 Minting            



## Summary

In `src/token/ERC20ToGenerateNftFraccion.sol`, the `mint` function is public, meaning anyone can mint the ERC20 token corresponding to the NFT. However, since there are additional records in the contract, self-minting tokens bypasses these records, leaving them untracked.

## Recommendations

It is recommended to implement access control to prevent unauthorized token minting.

## <a id='H-02'></a>H-02. Ensure Consistency Between ERC20 Transfers and `TokenDivider` Contract Balances            



## Summary

Each fraction of an NFT is represented as an ERC20 token, allowing users to transfer tokens using `transfer` and `transferFrom`. However, these transfers do not update the records in the `TokenDivider` contract, causing discrepancies between the tokens held by users and the `balances` recorded in the contract.

## Recommendations

It is recommended to either adjust the authentication of these functions or ensure that these functions update the balances in the `TokenDivider` contract.

    
# Medium Risk Findings

## <a id='M-01'></a>M-01. Unbounded `s_userToSellOrders[msg.sender]` Leading to Potential High Gas Costs and DoS Risks            



## Summary

In `src/TokenDivider.sol`, the `sellErc20` function pushes an order into the array `s_userToSellOrders[msg.sender]`. However, this array is unbounded, which poses a problem: if the array grows too large, it could result in excessive gas costs for other users.

## PoC

```Solidity
pragma solidity ^0.8.18;
​
​
import {Test, console} from 'forge-std/Test.sol';
import {DeployTokenDivider} from 'script/DeployTokenDivider.s.sol';
import {TokenDivider} from 'src/TokenDivider.sol';
import {ERC721Mock} from '../mocks/ERC721Mock.sol';
import {ERC20Mock} from '@openzeppelin/contracts/mocks/token/ERC20Mock.sol';
import {Ownable} from '@openzeppelin/contracts/access/Ownable.sol';
​
​
contract TokenDiverTest is Test {
  DeployTokenDivider deployer;
  TokenDivider tokenDivider;
  ERC721Mock erc721Mock;
​
  address public USER = makeAddr("user");
  uint256 constant public AMOUNT = 2e18;
  uint256 constant public TOKEN_ID = 0;
​
  function setUp() public {
    deployer = new DeployTokenDivider();
    tokenDivider = deployer.run();
​
    erc721Mock = new ERC721Mock();
​
    erc721Mock.mint(USER);
  }
​
  modifier nftDivided() {
    vm.startPrank(USER);
    erc721Mock.approve(address(tokenDivider), TOKEN_ID);
    tokenDivider.divideNft(address(erc721Mock), TOKEN_ID, AMOUNT);
    vm.stopPrank();
​
    _;
  }
​
  function testUnboundedArray() public nftDivided {
    ERC20Mock erc20Mock = ERC20Mock(tokenDivider.getErc20InfoFromNft(address(erc721Mock)).erc20Address);
​
    vm.startPrank(USER);
    erc20Mock.approve(address(tokenDivider), AMOUNT);
​
    for (uint256 i = 0; i < AMOUNT; i++) {
      tokenDivider.sellErc20(address(erc721Mock), 1e18, 1);
    }
​
    vm.stopPrank();
  }
}
```

## Recommendations

Add a limit to the maximum length of the array.

## <a id='M-02'></a>M-02. Vulnerability in `buyOrder` Function: Potential ERC20 Token Burning Issue            



## Summary

In `src/TokenDivider.sol`, users can purchase a portion of an NFT through the `buyOrder` function. However, since the ERC20 token is burnable, a user could call the `burn` function on their tokens. This would prevent other users holding the remaining portions of the NFT from ever being able to claim the NFT.

## Recommendations

It is recommended to add constraints to the `burn` function to prevent this issue.


# Low Risk Findings

## <a id='L-01'></a>L-01. Remove Redundant Condition Checks to Optimize Gas Usage            



## Summary

In `src/TokenDivider.sol`, we identified redundant condition checks at lines **185** and **195**:

```Solidity
if (to == address(0)) {
    revert TokenDivider__CantTransferToAddressZero();
}
```

These checks validate the same criteria and unnecessarily increase gas consumption.

## Recommendations

Remove one of these redundant checks to streamline the contract logic and optimize gas usage while maintaining functionality and security.

## <a id='L-02'></a>L-02. Optimize Gas Usage by Removing Duplicate Modifiers            



## Summary

In `src/TokenDivider.sol`, line 109, the `onlyNftOwner(nftAddress, tokenId)` modifier is used twice.

## Recommendations

It is recommended to remove one instance to improve efficiency.



