// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "src/2025-02-raac/contracts/libraries/math/TimeWeightedAverage.sol";
import {Test, console} from 'forge-std/Test.sol';

contract testRAACTWAP {
    function testCalculateTWAP() external pure {
        TimeWeightedAverage.PeriodParams[] memory periods = new TimeWeightedAverage.PeriodParams[](3);
        
        // period[0] and period[1] are overlapped
        periods[0] = TimeWeightedAverage.PeriodParams({startTime: 1, endTime: 4, value: 100, weight: 1e18});
        periods[1] = TimeWeightedAverage.PeriodParams({startTime: 1, endTime: 4, value: 100, weight: 1e18});
        periods[2] = TimeWeightedAverage.PeriodParams({startTime: 5, endTime: 8, value: 130, weight: 1e18});
        
        uint256 TWAP = TimeWeightedAverage.calculateTimeWeightedAverage(periods, 8);
        
        // The TWAP should be 115 instead of 110 since (110 + 130) / 2 = 115
        // However, this function can't deal with overlapped period
        assert(TWAP == 110);
    }
}
