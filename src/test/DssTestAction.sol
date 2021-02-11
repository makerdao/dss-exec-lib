// SPDX-License-Identifier: AGPL-3.0-or-later
//
// DssTestAction.sol -- Testable Actions
//
// Copyright (C) 2020 Maker Ecosystem Growth Holdings, Inc.
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Affero General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Affero General Public License for more details.
//
// You should have received a copy of the GNU Affero General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.

pragma solidity ^0.6.11;

import "../DssAction.sol";

contract DssTestAction is DssAction {

    constructor(bool ofcHrs) DssAction(ofcHrs) public {}

    function actions() public override {}

    /*****************************/
    /*** Collateral Onboarding ***/
    /*****************************/

    function addNewCollateral_test(
        bytes32          ilk,
        address[] memory addresses,
        bool[] memory    oracleSettings,
        uint256[] memory amounts
    ) public {
        CollateralOpts memory co = CollateralOpts(
            ilk,
            addresses[0],
            addresses[1],
            addresses[2],
            addresses[3],
            oracleSettings[0],
            oracleSettings[1],
            oracleSettings[2],
            amounts[0],           // ilkDebtCeiling
            amounts[1],           // minVaultAmount
            amounts[2],           // maxLiquidationAmount
            amounts[3],           // liquidationPenalty
            amounts[4],           // ilkStabilityFee
            amounts[5],           // bidIncrease
            amounts[6],           // bidDuration
            amounts[7],           // auctionDuration
            amounts[8]            // liquidationRatio
        );

        addNewCollateral(co);
    }

}
