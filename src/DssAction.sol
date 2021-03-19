// SPDX-License-Identifier: AGPL-3.0-or-later
//
// DssAction.sol -- DSS Executive Spell Actions
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

import { DssExecLib } from "./DssExecLib.sol";
import { CollateralOpts } from "./CollateralOpts.sol";

interface OracleLike {
    function src() external view returns (address);
}

abstract contract DssAction {

    using DssExecLib for *;

    // Office Hours defaults to true by default.
    //   To disable office hours, override this function and
    //    return false in the inherited action.
    function officeHours() public virtual returns (bool) {
        return true;
    }

    // DssExec calls execute. We limit this function subject to officeHours modifier.
    function execute() external limited {
        actions();
    }

    // DssAction developer must override `actions()` and place all actions to be called inside.
    //   The DssExec function will call this subject to the officeHours limiter
    //   By keeping this function public we allow simulations of `execute()` on the actions outside of the cast time.
    function actions() public virtual;

    // Modifier required to
    modifier limited {
        if (officeHours()) {
            uint day = (block.timestamp / 1 days + 3) % 7;
            require(day < 5, "Can only be cast on a weekday");
            uint hour = block.timestamp / 1 hours % 24;
            require(hour >= 14 && hour < 21, "Outside office hours");
        }
        _;
    }

    function addNewCollateral(CollateralOpts memory co) internal {

        address[] memory _addrs = new address[](4);
        bool[] memory _bools = new bool[](3);
        uint256[] memory _vals = new uint256[](9);
        _addrs[0] = co.gem;
        _addrs[1] = co.join;
        _addrs[2] = co.flip;
        _addrs[3] = co.pip;
        _bools[0] = co.isLiquidatable;
        _bools[1] = co.isOSM;
        _bools[2] = co.whitelistOSM;
        _vals[0]  = co.ilkDebtCeiling;
        _vals[1]  = co.minVaultAmount;
        _vals[2]  = co.maxLiquidationAmount;
        _vals[3]  = co.liquidationPenalty;
        _vals[4]  = co.ilkStabilityFee;
        _vals[5]  = co.bidIncrease;
        _vals[6]  = co.bidDuration;
        _vals[7]  = co.auctionDuration;
        _vals[8]  = co.liquidationRatio;

        DssExecLib.addNewCollateral(
            co.ilk,
            _addrs,
            _bools,
            _vals
        );
    }
}
