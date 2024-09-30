// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.27;

import {IOracle} from "../IOracle.sol";

contract Univ3RocketPool is IOracle {
    function getLatestPrice() external view returns (int) {
        return 0;
    }
}
