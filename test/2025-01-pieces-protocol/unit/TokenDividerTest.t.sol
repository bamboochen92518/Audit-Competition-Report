// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;


import {Test, console} from 'forge-std/Test.sol';
import {TokenDivider} from '../../../src/2025-01-pieces-protocol/TokenDivider.sol';
import {ERC721Mock} from '../mocks/ERC721Mock.sol';
import {ERC20Mock} from '@openzeppelin/contracts/mocks/token/ERC20Mock.sol';
import {Ownable} from '@openzeppelin/contracts/access/Ownable.sol';


contract TokenDividerTest is Test {
    TokenDivider tokenDivider;
    ERC721Mock erc721Mock;

    address public USER = makeAddr("user");
    address public USER2 = makeAddr("user2");
    uint256 constant public STARTING_USER_BALANCE = 10e18;
    uint256 constant public AMOUNT = 2e18;
    uint256 constant public TOKEN_ID = 0;

    function setUp() public {
        tokenDivider = new TokenDivider();
        
        erc721Mock = new ERC721Mock();
        
        erc721Mock.mint(USER);
        vm.deal(USER2, STARTING_USER_BALANCE);
    }

    function testDivideNft() public {
        
        vm.startPrank(USER);
        erc721Mock.approve(address(tokenDivider), TOKEN_ID);

        tokenDivider.divideNft(address(erc721Mock), TOKEN_ID, AMOUNT);
        vm.stopPrank();
        ERC20Mock erc20Mock = ERC20Mock(tokenDivider.getErc20InfoFromNft(address(erc721Mock)).erc20Address);

        console.log("ERC20 Token name is: ", erc20Mock.name());
        console.log("ERC20 Token symbol is: ", erc20Mock.symbol());
        assertEq(tokenDivider.getErc20TotalMintedAmount(address(erc20Mock)), AMOUNT);
        assertEq(erc721Mock.ownerOf(TOKEN_ID), address(tokenDivider));
        assertEq(tokenDivider.getBalanceOf(USER,  address(erc20Mock)), AMOUNT);

    }


    modifier nftDivided() {
        vm.startPrank(USER);
        erc721Mock.approve(address(tokenDivider), TOKEN_ID);
        tokenDivider.divideNft(address(erc721Mock), TOKEN_ID, AMOUNT);
        vm.stopPrank();

        _;

    }

    function testDivideNftFailsIsSenderIsNotNftOwner() public {
        vm.prank(USER);
        erc721Mock.approve(address(tokenDivider), TOKEN_ID);

        vm.startPrank(USER2);
        vm.expectRevert(TokenDivider.TokenDivider__NotFromNftOwner.selector);
        tokenDivider.divideNft(address(erc721Mock), TOKEN_ID, AMOUNT);
        vm.stopPrank();
    }

    function testTransferErcTokensAndClaimNftFailsIfDontHaveAllTheErc20() public nftDivided {
        ERC20Mock erc20Mock = ERC20Mock(tokenDivider.getErc20InfoFromNft(address(erc721Mock)).erc20Address);
        vm.startPrank(USER);
       // Arrange

        erc20Mock.approve(address(tokenDivider), AMOUNT);

        
        // Act / Assert
        tokenDivider.transferErcTokens(address(erc721Mock),USER2, AMOUNT);
        
        assertEq(tokenDivider.getBalanceOf(USER2, address(erc20Mock)), AMOUNT);
        assertEq(tokenDivider.getBalanceOf(USER, address(erc20Mock)), 0);

        vm.expectRevert(TokenDivider.TokenDivider__NotEnoughErc20Balance.selector);
        
        tokenDivider.claimNft(address(erc721Mock));
        
        vm.stopPrank();

    }

    function testClaimNft() public nftDivided {
        ERC20Mock erc20Mock = ERC20Mock(tokenDivider.getErc20InfoFromNft(address(erc721Mock)).erc20Address);
        vm.startPrank(USER);
        erc20Mock.approve(address(tokenDivider), AMOUNT);
        tokenDivider.claimNft(address(erc721Mock));
        vm.stopPrank();

        assertEq(erc20Mock.totalSupply(), 0);
        assertEq(tokenDivider.getBalanceOf(USER, address(erc20Mock)), 0);
        assertEq(erc721Mock.ownerOf(TOKEN_ID), USER);
    }


    function testSellErc20() public nftDivided{
        ERC20Mock erc20Mock = ERC20Mock(tokenDivider.getErc20InfoFromNft(address(erc721Mock)).erc20Address);

        vm.startPrank(USER);
        erc20Mock.approve(address(tokenDivider), AMOUNT);
        tokenDivider.sellErc20(address(erc721Mock), 1e18, AMOUNT);
        vm.stopPrank();
        
        assertEq(tokenDivider.getBalanceOf(USER, address(erc20Mock)), 0);
        assertEq(erc20Mock.balanceOf(address(tokenDivider)), AMOUNT);
    }

    function testBuyErc20() public nftDivided {
        ERC20Mock erc20Mock = ERC20Mock(tokenDivider.getErc20InfoFromNft(address(erc721Mock)).erc20Address);

        uint256 ownerBalanceBefore = address(tokenDivider.owner()).balance;
        uint256 userBalanceBefore = address(USER).balance;
        uint256 user2TokenBalanceBefore = tokenDivider.getBalanceOf(USER2, address(erc20Mock));

        vm.startPrank(USER);

        erc20Mock.approve(address(tokenDivider), AMOUNT);
    
        tokenDivider.sellErc20(address(erc721Mock), AMOUNT, 1e18); // Creamos una orden de venta por 1 ETH

        uint256 fees = AMOUNT / 100;
    
        vm.stopPrank();


        vm.prank(USER2);
        tokenDivider.buyOrder{value: (3e18)}(0, USER);

        uint256 ownerBalanceAfter = address(tokenDivider.owner()).balance;
        uint256 userBalanceAfter = address(USER).balance;
        uint256 user2TokenBalanceAfter = tokenDivider.getBalanceOf(USER2, address(erc20Mock));

        assertEq(user2TokenBalanceAfter - 1e18, user2TokenBalanceBefore);
        assertEq(ownerBalanceAfter - fees, ownerBalanceBefore);

        if(block.chainid != 31337) {
            assertEq(userBalanceAfter - AMOUNT + fees / 2, userBalanceBefore);
        } else {
            assertEq(user2TokenBalanceAfter, 1e18);
            
        }
    }

    function testPublicMint() public nftDivided {
        // Step 1. Sell ERC20 token
        ERC20Mock erc20Mock = ERC20Mock(tokenDivider.getErc20InfoFromNft(address(erc721Mock)).erc20Address);

        vm.startPrank(USER);
        erc20Mock.approve(address(tokenDivider), AMOUNT);
        tokenDivider.sellErc20(address(erc721Mock), 1e18, AMOUNT);
        vm.stopPrank();
        
        assertEq(tokenDivider.getBalanceOf(USER, address(erc20Mock)), 0);
        assertEq(erc20Mock.balanceOf(address(tokenDivider)), AMOUNT);
        
        // Step 2. Mint the token
        erc20Mock.mint(USER, AMOUNT);
        
        assertEq(tokenDivider.getBalanceOf(USER, address(erc20Mock)), AMOUNT);
        assertEq(erc20Mock.balanceOf(address(tokenDivider)), AMOUNT);

        // Step 3. Claim NFT
        vm.startPrank(USER);
        erc20Mock.approve(address(tokenDivider), AMOUNT);
        tokenDivider.claimNft(address(erc721Mock));
        vm.stopPrank();

        assertEq(erc721Mock.ownerOf(TOKEN_ID), USER);
    }

    function testUnboundedArray() public nftDivided {
        ERC20Mock erc20Mock = ERC20Mock(tokenDivider.getErc20InfoFromNft(address(erc721Mock)).erc20Address);

        vm.startPrank(USER);
        erc20Mock.approve(address(tokenDivider), AMOUNT);

        for (uint256 i = 0; i < AMOUNT; i++) {
            tokenDivider.sellErc20(address(erc721Mock), 1e18, 1);
        }

        vm.stopPrank();
    }
}
