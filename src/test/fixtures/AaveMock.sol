// SPDX-License-Identifier: AGPL-3.0-or-later
pragma solidity ^0.6.12;

contract AaveMock {
    // https://docs.aave.com/developers/the-core-protocol/lendingpool
    function getReserveData(address dai) public view returns (
        uint256, uint128, uint128, uint128, uint128, uint128, uint40, address, address, address, address, uint8
    ) {
        address _dai = dai; // avoid stack too deep
        return (0,0,0,0,0,0,0, _dai, _dai, _dai, address(this), 0);
    }

    function getMaxVariableBorrowRate() public pure returns (uint256) {
        return type(uint256).max;
    }
}
