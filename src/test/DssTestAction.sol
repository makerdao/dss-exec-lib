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

pragma solidity ^0.6.7;
pragma experimental ABIEncoderV2;

import "../DssAction.sol";

contract DssTestAction is DssAction {

    constructor(address lib, bool ofcHrs) DssAction(lib, ofcHrs) public {}

    function actions() public override {}

    /**********************/
    /*** Authorizations ***/
    /**********************/
    function authorize_test(address base, address ward) public {
        authorize(base, ward);
    }

    function deauthorize_test(address base, address ward) public {
        deauthorize(base, ward);
    }

    /**************************/
    /*** Accumulating Rates ***/
    /**************************/
    function accumulateDSR_test() public {
        accumulateDSR();
    }

    function accumulateCollateralStabilityFees_test(bytes32 ilk) public {
        accumulateCollateralStabilityFees(ilk);
    }

    /****************************/
    /*** Changelog Management ***/
    /****************************/

    function setChangelogAddress_test(bytes32 key, address val) public {
        setChangelogAddress(key, val);
    }

    function setChangelogVersion_test(string memory version) public {
        setChangelogVersion(version);
    }

    function setChangelogIPFS_test(string memory ipfs) public {
        setChangelogIPFS(ipfs);
    }

    function setChangelogSHA256_test(string memory SHA256) public {
        setChangelogSHA256(SHA256);
    }

    /*********************/
    /*** Price Updates ***/
    /*********************/
    function updateCollateralPrice_test(bytes32 ilk) public {
        updateCollateralPrice(ilk);
    }

    /****************************/
    /*** System Configuration ***/
    /****************************/
    function setContract_test(address base, bytes32 what, address addr) public {
        setContract(base, what, addr);
    }

    function setContract_test(address base, bytes32 ilk, bytes32 what, address addr) public {
        setContract(base, ilk, what, addr);
    }

    /******************************/
    /*** System Risk Parameters ***/
    /******************************/
    function setGlobalDebtCeiling_test(uint256 amount) public {
        setGlobalDebtCeiling(amount);
    }

    function increaseGlobalDebtCeiling_test(uint256 amount) public {
        increaseGlobalDebtCeiling(amount);
    }

    function decreaseGlobalDebtCeiling_test(uint256 amount) public {
        decreaseGlobalDebtCeiling(amount);
    }

    function setDSR_test(uint256 rate) public {
        setDSR(rate);
    }

    function setSurplusAuctionAmount_test(uint256 amount) public {
        setSurplusAuctionAmount(amount);
    }

    function setSurplusBuffer_test(uint256 amount) public {
        setSurplusBuffer(amount);
    }

    function setMinSurplusAuctionBidIncrease_test(uint256 pct_bps) public {
        setMinSurplusAuctionBidIncrease(pct_bps);
    }

    function setSurplusAuctionBidDuration_test(uint256 duration) public {
        setSurplusAuctionBidDuration(duration);
    }

    function setSurplusAuctionDuration_test(uint256 duration) public {
        setSurplusAuctionDuration(duration);
    }

    function setDebtAuctionDelay_test(uint256 duration) public {
        setDebtAuctionDelay(duration);
    }

    function setDebtAuctionDAIAmount_test(uint256 amount) public {
        setDebtAuctionDAIAmount(amount);
    }

    function setDebtAuctionMKRAmount_test(uint256 amount) public {
        setDebtAuctionMKRAmount(amount);
    }

    function setMinDebtAuctionBidIncrease_test(uint256 pct_bps) public {
        setMinDebtAuctionBidIncrease(pct_bps);
    }

    function setDebtAuctionBidDuration_test(uint256 duration) public {
        setDebtAuctionBidDuration(duration);
    }

    function setDebtAuctionDuration_test(uint256 duration) public {
        setDebtAuctionDuration(duration);
    }

    function setDebtAuctionMKRIncreaseRate_test(uint256 pct_bps) public {
        setDebtAuctionMKRIncreaseRate(pct_bps);
    }

    function setMaxTotalDAILiquidationAmount_test(uint256 amount) public {
        setMaxTotalDAILiquidationAmount(amount);
    }

    function setEmergencyShutdownProcessingTime_test(uint256 duration) public {
        setEmergencyShutdownProcessingTime(duration);
    }

    function setGlobalStabilityFee_test(uint256 rate) public {
        setGlobalStabilityFee(rate);
    }

    function setDAIReferenceValue_test(uint256 value) public {
        setDAIReferenceValue(value);
    }

    /*****************************/
    /*** Collateral Management ***/
    /*****************************/
    function setIlkDebtCeiling_test(bytes32 ilk, uint256 amount) public {
        setIlkDebtCeiling(ilk, amount);
    }

    function increaseIlkDebtCeiling_test(bytes32 ilk, uint256 amount) public {
        increaseIlkDebtCeiling(ilk, amount);
    }

    function decreaseIlkDebtCeiling_test(bytes32 ilk, uint256 amount) public {
        decreaseIlkDebtCeiling(ilk, amount);
    }

    function setIlkAutoLineParameters_test(bytes32 ilk, uint256 amount, uint256 gap, uint256 ttl) public {
        setIlkAutoLineParameters(ilk, amount, gap, ttl);
    }

    function setIlkAutoLineDebtCeiling_test(bytes32 ilk, uint256 amount) public {
        setIlkAutoLineDebtCeiling(ilk, amount);
    }

    function removeIlkFromAutoLine_test(bytes32 ilk) public {
        removeIlkFromAutoLine(ilk);
    }

    function setIlkMinVaultAmount_test(bytes32 ilk, uint256 amount) public {
        setIlkMinVaultAmount(ilk, amount);
    }

    function setIlkLiquidationPenalty_test(bytes32 ilk, uint256 pct_bps) public {
        setIlkLiquidationPenalty(ilk, pct_bps);
    }

    function setIlkMaxLiquidationAmount_test(bytes32 ilk, uint256 amount) public {
        setIlkMaxLiquidationAmount(ilk, amount);
    }

    function setIlkLiquidationRatio_test(bytes32 ilk, uint256 pct_bps) public {
        setIlkLiquidationRatio(ilk, pct_bps);
    }

    function setIlkMinAuctionBidIncrease_test(bytes32 ilk, uint256 pct_bps) public {
        setIlkMinAuctionBidIncrease(ilk, pct_bps);
    }

    function setIlkBidDuration_test(bytes32 ilk, uint256 duration) public {
        setIlkBidDuration(ilk, duration);
    }

    function setIlkAuctionDuration_test(bytes32 ilk, uint256 duration) public {
        setIlkAuctionDuration(ilk, duration);
    }

    function setIlkStabilityFee_test(bytes32 ilk, uint256 rate) public {
        setIlkStabilityFee(ilk, rate);
    }

    /***********************/
    /*** Core Management ***/
    /***********************/
    function updateCollateralAuctionContract_test(bytes32 ilk, address newFlip, address oldFlip) public {
        updateCollateralAuctionContract(ilk, newFlip, oldFlip);
    }

    function updateSurplusAuctionContract_test(address newFlap, address oldFlap) public {
        updateSurplusAuctionContract(newFlap, oldFlap);
    }

    function updateDebtAuctionContract_test(address newFlop, address oldFlop) public {
        updateDebtAuctionContract(newFlop, oldFlop);
    }

    /*************************/
    /*** Oracle Management ***/
    /*************************/
    function addWritersToMedianWhitelist_test(address medianizer, address[] memory feeds) public {
        addWritersToMedianWhitelist(medianizer, feeds);
    }

    function removeWritersFromMedianWhitelist_test(address medianizer, address[] memory feeds) public {
        removeWritersFromMedianWhitelist(medianizer, feeds);
    }

    function addReadersToMedianWhitelist_test(address medianizer, address[] memory readers) public {
        addReadersToMedianWhitelist(medianizer, readers);
    }

    function addReaderToMedianWhitelist_test(address medianizer, address reader) public {
        addReaderToMedianWhitelist(medianizer, reader);
    }

    function removeReadersFromMedianWhitelist_test(address medianizer, address[] memory readers) public {
        removeReadersFromMedianWhitelist(medianizer, readers);
    }

    function removeReaderFromMedianWhitelist_test(address medianizer, address reader) public {
        removeReaderFromMedianWhitelist(medianizer, reader);
    }

    function setMedianWritersQuorum_test(address medianizer, uint256 minQuorum) public {
        setMedianWritersQuorum(medianizer, minQuorum);
    }

    function addReaderToOSMWhitelist_test(address osm, address reader) public {
        addReaderToOSMWhitelist(osm, reader);
    }

    function removeReaderFromOSMWhitelist_test(address osm, address reader) public {
        removeReaderFromOSMWhitelist(osm, reader);
    }

    function allowOSMFreeze_test(address osm, bytes32 ilk) public {
        allowOSMFreeze(osm, ilk);
    }


    /*****************************/
    /*** Collateral Onboarding ***/
    /*****************************/

    function addCollateralBase_test(
        bytes32 ilk, address gem, address join, address flip, address pip
    ) public {
        addCollateralBase(ilk, gem, join, flip, pip);
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

    /************/
    /*** Misc ***/
    /************/
    function linearInterpolation_test(address _target, bytes32 _what, uint256 _start, uint256 _end, uint256 _duration) public returns (address) {
        return linearInterpolation(_target, _what, _start, _end, _duration);
    }
    function linearInterpolation_test(address _target, bytes32 _ilk, bytes32 _what, uint256 _start, uint256 _end, uint256 _duration) public returns (address) {
        return linearInterpolation(_target, _ilk, _what, _start, _end, _duration);
    }

}
