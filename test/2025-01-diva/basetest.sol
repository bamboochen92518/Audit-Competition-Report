// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Test.sol";
import "../../src/2025-01-diva/AaveDIVAWrapper.sol";
import "../../src/2025-01-diva/WToken.sol";
import "../../src/2025-01-diva/interfaces/IAaveDIVAWrapper.sol";
import "../../src/2025-01-diva/interfaces/IAave.sol";
import "../../src/2025-01-diva/interfaces/IDIVA.sol";
import "../../src/2025-01-diva/interfaces/IWToken.sol";

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "lib/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";


address constant aaveAddress = 0x794a61358D6845594F94dc1DB02A252b5b4814aD;
address constant divaAddress = 0x2C9c47E7d254e493f02acfB410864b9a86c28e1D;
address constant usdcAddress = 0xaf88d065e77c8cC2239327C5EDb3A432268e5831;
address constant usdtAddress = 0xfd086bc7cd5c481dcc9c85ebe478a1c0b69fcbb9;
address constant uniswapRouterAddress = 0x4752ba5DBc23f44D87826276BF6Fd6b1C372aD24;


contract MyContractTest is Test {
    IUniswapV2Router02 public uniswapRouter;
    IERC20 public usdc;

    address user = makeAddr("user");
    address owner = makeAddr("owner");
    address recipient = makeAddr("recipient");

    address wtoken_address;

    AaveDIVAWrapper wrapper;
    IAave aave;
    IDIVA diva;
    
    uint256 owner_init_eth_amount = 10 ether;
    // uint256 block_number = 299481002;

    function setUp() public {
        vm.createSelectFork("https://rpc.ankr.com/arbitrum", 299824150);

        vm.deal(owner, owner_init_eth_amount);

        // Get USDC by UniSwapV2 First
        uniswapRouter = IUniswapV2Router02(uniswapRouterAddress);
        usdc = IERC20(usdcAddress);

        address[] memory path = new address[](2);
        path[0] = uniswapRouter.WETH();
        path[1] = usdcAddress;

        vm.startPrank(owner);
        uniswapRouter.swapETHForExactTokens{value: 3 ether}(
            5000 * 1e6,             // Amount of USDC to receive
            path,                   // Swap path
            owner,                  // Recipient
            block.timestamp + 15    // Deadline
        );
        vm.stopPrank();

        // Construct A Wrapper
        wrapper = new AaveDIVAWrapper(divaAddress, aaveAddress, owner);
    }

    modifier register() {
        vm.startPrank(owner);
        wtoken_address = wrapper.registerCollateralToken(usdcAddress);
        vm.stopPrank();
        _;
    }

    function testRegisterCollateralToken() register public { 
        require(wtoken_address == wrapper.getWToken(usdcAddress));
        require(usdcAddress == wrapper.getCollateralToken(wtoken_address));
    }

    receive() external payable {
        // Code to handle received ETH
    }
}
