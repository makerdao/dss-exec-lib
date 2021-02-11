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

import "./CollateralOpts.sol";
import "./DssExecLib.sol";

abstract contract DssAction {

    using DssExecLib for *;

    bool public immutable officeHours;

    constructor(bool officeHours_) public {
        officeHours = officeHours_;
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
        if (officeHours) {
            uint day = (block.timestamp / 1 days + 3) % 7;
            require(day < 5, "Can only be cast on a weekday");
            uint hour = block.timestamp / 1 hours % 24;
            require(hour >= 14 && hour < 21, "Outside office hours");
        }
        _;
    }

    /*****************************/
    /*** Collateral Onboarding ***/
    /*****************************/

    // Complete collateral onboarding logic.
    function addNewCollateral(CollateralOpts memory co) internal {
        // Add the collateral to the system.
        DssExecLib.addCollateralBase(co.ilk, co.gem, co.join, co.flip, co.pip);

        // Allow FlipperMom to access to the ilk Flipper
        address _flipperMom = DssExecLib.flipperMom();
        DssExecLib.authorize(co.flip, _flipperMom);
        // Disallow Cat to kick auctions in ilk Flipper
        if(!co.isLiquidatable) { DssExecLib.deauthorize(_flipperMom, co.flip); }

        if(co.isOSM) { // If pip == OSM
            // Allow OsmMom to access to the TOKEN OSM
            DssExecLib.authorize(co.pip, DssExecLib.osmMom());
            if (co.whitelistOSM) { // If median is src in OSM
                // Whitelist OSM to read the Median data (only necessary if it is the first time the token is being added to an ilk)
                DssExecLib.addReaderToMedianWhitelist(address(OracleLike(co.pip).src()), co.pip);
            }
            // Whitelist Spotter to read the OSM data (only necessary if it is the first time the token is being added to an ilk)
            DssExecLib.addReaderToOSMWhitelist(co.pip, DssExecLib.spotter());
            // Whitelist End to read the OSM data (only necessary if it is the first time the token is being added to an ilk)
            DssExecLib.addReaderToOSMWhitelist(co.pip, DssExecLib.end());
            // Set TOKEN OSM in the OsmMom for new ilk
            DssExecLib.allowOSMFreeze(co.pip, co.ilk);
        }
        // Increase the global debt ceiling by the ilk ceiling
        DssExecLib.increaseGlobalDebtCeiling(co.ilkDebtCeiling);
        // Set the ilk debt ceiling
        DssExecLib.setIlkDebtCeiling(co.ilk, co.ilkDebtCeiling);
        // Set the ilk dust
        DssExecLib.setIlkMinVaultAmount(co.ilk, co.minVaultAmount);
        // Set the dunk size
        DssExecLib.setIlkMaxLiquidationAmount(co.ilk, co.maxLiquidationAmount);
        // Set the ilk liquidation penalty
        DssExecLib.setIlkLiquidationPenalty(co.ilk, co.liquidationPenalty);

        // Set the ilk stability fee
        DssExecLib.setIlkStabilityFee(co.ilk, co.ilkStabilityFee, true);

        // Set the ilk percentage between bids
        DssExecLib.setIlkMinAuctionBidIncrease(co.ilk, co.bidIncrease);
        // Set the ilk time max time between bids
        DssExecLib.setIlkBidDuration(co.ilk, co.bidDuration);
        // Set the ilk max auction duration
        DssExecLib.setIlkAuctionDuration(co.ilk, co.auctionDuration);
        // Set the ilk min collateralization ratio
        DssExecLib.setIlkLiquidationRatio(co.ilk, co.liquidationRatio);

        // Update ilk spot value in Vat
        DssExecLib.updateCollateralPrice(co.ilk);
    }
}
