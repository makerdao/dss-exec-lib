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

    /**********************/
    /*** Authorizations ***/
    /**********************/
    function authorize_test(address base, address ward) public {
        lib.authorize(base, ward);
    }

    function deauthorize_test(address base, address ward) public {
        lib.deauthorize(base, ward);
    }

    /**************************/
    /*** Accumulating Rates ***/
    /**************************/
    function accumulateDSR_test() public {
        lib.accumulateDSR();
    }

    function accumulateCollateralStabilityFees_test(bytes32 ilk) public {
        lib.accumulateCollateralStabilityFees(ilk);
    }

    /****************************/
    /*** Changelog Management ***/
    /****************************/

    function setChangelogAddress_test(bytes32 key, address val) public {
        lib.setChangelogAddress(key, val);
    }

    function setChangelogVersion_test(string memory version) public {
        lib.setChangelogVersion(version);
    }

    function setChangelogIPFS_test(string memory ipfs) public {
        lib.setChangelogIPFS(ipfs);
    }

    function setChangelogSHA256_test(string memory SHA256) public {
        lib.setChangelogSHA256(SHA256);
    }

    /*********************/
    /*** Price Updates ***/
    /*********************/
    function updateCollateralPrice_test(bytes32 ilk) public {
        lib.updateCollateralPrice(ilk);
    }

    /****************************/
    /*** System Configuration ***/
    /****************************/
    function setContract_test(address base, bytes32 what, address addr) public {
        lib.setContract(base, what, addr);
    }

    function setContract_test(address base, bytes32 ilk, bytes32 what, address addr) public {
        lib.setContract(base, ilk, what, addr);
    }

    /******************************/
    /*** System Risk Parameters ***/
    /******************************/
    function setGlobalDebtCeiling_test(uint256 amount) public {
        lib.setGlobalDebtCeiling(amount);
    }

    function increaseGlobalDebtCeiling_test(uint256 amount) public {
        lib.increaseGlobalDebtCeiling(amount);
    }

    function decreaseGlobalDebtCeiling_test(uint256 amount) public {
        lib.decreaseGlobalDebtCeiling(amount);
    }

    function setDSR_test(uint256 rate) public {
        lib.setDSR(rate);
    }

    function setSurplusAuctionAmount_test(uint256 amount) public {
        lib.setSurplusAuctionAmount(amount);
    }

    function setSurplusBuffer_test(uint256 amount) public {
        lib.setSurplusBuffer(amount);
    }

    function setMinSurplusAuctionBidIncrease_test(uint256 pct_bps) public {
        lib.setMinSurplusAuctionBidIncrease(pct_bps);
    }

    function setSurplusAuctionBidDuration_test(uint256 duration) public {
        lib.setSurplusAuctionBidDuration(duration);
    }

    function setSurplusAuctionDuration_test(uint256 duration) public {
        lib.setSurplusAuctionDuration(duration);
    }

    function setDebtAuctionDelay_test(uint256 duration) public {
        lib.setDebtAuctionDelay(duration);
    }

    function setDebtAuctionDAIAmount_test(uint256 amount) public {
        lib.setDebtAuctionDAIAmount(amount);
    }

    function setDebtAuctionMKRAmount_test(uint256 amount) public {
        lib.setDebtAuctionMKRAmount(amount);
    }

    function setMinDebtAuctionBidIncrease_test(uint256 pct_bps) public {
        lib.setMinDebtAuctionBidIncrease(pct_bps);
    }

    function setDebtAuctionBidDuration_test(uint256 duration) public {
        lib.setDebtAuctionBidDuration(duration);
    }

    function setDebtAuctionDuration_test(uint256 duration) public {
        lib.setDebtAuctionDuration(duration);
    }

    function setDebtAuctionMKRIncreaseRate_test(uint256 pct_bps) public {
        lib.setDebtAuctionMKRIncreaseRate(pct_bps);
    }

    function setMaxTotalDAILiquidationAmount_test(uint256 amount) public {
        lib.setMaxTotalDAILiquidationAmount(amount);
    }

    function setEmergencyShutdownProcessingTime_test(uint256 duration) public {
        lib.setEmergencyShutdownProcessingTime(duration);
    }

    function setGlobalStabilityFee_test(uint256 rate) public {
        lib.setGlobalStabilityFee(rate);
    }

    function setDAIReferenceValue_test(uint256 value) public {
        lib.setDAIReferenceValue(value);
    }

    /*****************************/
    /*** Collateral Management ***/
    /*****************************/
    function setIlkDebtCeiling_test(bytes32 ilk, uint256 amount) public {
        lib.setIlkDebtCeiling(ilk, amount);
    }

    function increaseIlkDebtCeiling_test(bytes32 ilk, uint256 amount) public {
        lib.increaseIlkDebtCeiling(ilk, amount, true);
    }

    function decreaseIlkDebtCeiling_test(bytes32 ilk, uint256 amount) public {
        lib.decreaseIlkDebtCeiling(ilk, amount, true);
    }

    function setIlkAutoLineParameters_test(bytes32 ilk, uint256 amount, uint256 gap, uint256 ttl) public {
        lib.setIlkAutoLineParameters(ilk, amount, gap, ttl);
    }

    function setIlkAutoLineDebtCeiling_test(bytes32 ilk, uint256 amount) public {
        lib.setIlkAutoLineDebtCeiling(ilk, amount);
    }

    function removeIlkFromAutoLine_test(bytes32 ilk) public {
        lib.removeIlkFromAutoLine(ilk);
    }

    function setIlkMinVaultAmount_test(bytes32 ilk, uint256 amount) public {
        lib.setIlkMinVaultAmount(ilk, amount);
    }

    function setIlkLiquidationPenalty_test(bytes32 ilk, uint256 pct_bps) public {
        lib.setIlkLiquidationPenalty(ilk, pct_bps);
    }

    function setIlkMaxLiquidationAmount_test(bytes32 ilk, uint256 amount) public {
        lib.setIlkMaxLiquidationAmount(ilk, amount);
    }

    function setIlkLiquidationRatio_test(bytes32 ilk, uint256 pct_bps) public {
        lib.setIlkLiquidationRatio(ilk, pct_bps);
    }

    function setIlkMinAuctionBidIncrease_test(bytes32 ilk, uint256 pct_bps) public {
        lib.setIlkMinAuctionBidIncrease(ilk, pct_bps);
    }

    function setIlkBidDuration_test(bytes32 ilk, uint256 duration) public {
        lib.setIlkBidDuration(ilk, duration);
    }

    function setIlkAuctionDuration_test(bytes32 ilk, uint256 duration) public {
        lib.setIlkAuctionDuration(ilk, duration);
    }

    function setIlkStabilityFee_test(bytes32 ilk, uint256 rate) public {
        lib.setIlkStabilityFee(ilk, rate, true);
    }


    /*************************/
    /*** Oracle Management ***/
    /*************************/
    function addWritersToMedianWhitelist_test(address medianizer, address[] memory feeds) public {
        lib.addWritersToMedianWhitelist(medianizer, feeds);
    }

    function removeWritersFromMedianWhitelist_test(address medianizer, address[] memory feeds) public {
        lib.removeWritersFromMedianWhitelist(medianizer, feeds);
    }

    function addReadersToMedianWhitelist_test(address medianizer, address[] memory readers) public {
        lib.addReadersToMedianWhitelist(medianizer, readers);
    }

    function addReaderToMedianWhitelist_test(address medianizer, address reader) public {
        lib.addReaderToMedianWhitelist(medianizer, reader);
    }

    function removeReadersFromMedianWhitelist_test(address medianizer, address[] memory readers) public {
        lib.removeReadersFromMedianWhitelist(medianizer, readers);
    }

    function removeReaderFromMedianWhitelist_test(address medianizer, address reader) public {
        lib.removeReaderFromMedianWhitelist(medianizer, reader);
    }

    function setMedianWritersQuorum_test(address medianizer, uint256 minQuorum) public {
        lib.setMedianWritersQuorum(medianizer, minQuorum);
    }

    function addReaderToOSMWhitelist_test(address osm, address reader) public {
        lib.addReaderToOSMWhitelist(osm, reader);
    }

    function removeReaderFromOSMWhitelist_test(address osm, address reader) public {
        lib.removeReaderFromOSMWhitelist(osm, reader);
    }

    function allowOSMFreeze_test(address osm, bytes32 ilk) public {
        lib.allowOSMFreeze(osm, ilk);
    }


    /*****************************/
    /*** Collateral Onboarding ***/
    /*****************************/

    function addCollateralBase_test(
        bytes32 ilk, address gem, address join, address flip, address pip
    ) public {
        lib.addCollateralBase(ilk, gem, join, flip, pip);
    }


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
