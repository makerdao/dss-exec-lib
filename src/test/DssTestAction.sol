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

pragma solidity ^0.6.12;
pragma experimental ABIEncoderV2;

import "../DssAction.sol";

contract DssTestNoOfficeHoursAction is DssAction {
    function description() public override view returns (string memory) {
        return "No Office Hours Action";
    }

    function actions() public override {
        require(!officeHours());
    }

    function officeHours() public override returns (bool) {
        return false;
    }
}

contract DssTestAction is DssAction {

    function description() external override view returns (string memory) {
        return "DssTestAction";
    }

    function actions() public override {}

    function canCast_test(uint40 ts, bool officeHours) public pure returns (bool) {
        return DssExecLib.canCast(ts, officeHours);
    }

    function nextCastTime_test(uint40 eta, uint40 ts, bool officeHours) public pure returns (uint256) {
        return DssExecLib.nextCastTime(eta, ts, officeHours);
    }

    /**********************/
    /*** Authorizations ***/
    /**********************/
    function authorize_test(address base, address ward) public {
        DssExecLib.authorize(base, ward);
    }

    function deauthorize_test(address base, address ward) public {
        DssExecLib.deauthorize(base, ward);
    }

    function setAuthority_test(address base, address authority) public {
        DssExecLib.setAuthority(base, authority);
    }

    function delegateVat_test(address usr) public {
        DssExecLib.delegateVat(usr);
    }

    function undelegateVat_test(address usr) public {
        DssExecLib.undelegateVat(usr);
    }

    /**************************/
    /*** Accumulating Rates ***/
    /**************************/
    function accumulateDSR_test() public {
        DssExecLib.accumulateDSR();
    }

    function accumulateCollateralStabilityFees_test(bytes32 ilk) public {
        DssExecLib.accumulateCollateralStabilityFees(ilk);
    }

    /****************************/
    /*** Changelog Management ***/
    /****************************/

    function setChangelogAddress_test(bytes32 key, address val) public {
        DssExecLib.setChangelogAddress(key, val);
    }

    function setChangelogVersion_test(string memory version) public {
        DssExecLib.setChangelogVersion(version);
    }

    function setChangelogIPFS_test(string memory ipfs) public {
        DssExecLib.setChangelogIPFS(ipfs);
    }

    function setChangelogSHA256_test(string memory SHA256) public {
        DssExecLib.setChangelogSHA256(SHA256);
    }

    /*********************/
    /*** Price Updates ***/
    /*********************/
    function updateCollateralPrice_test(bytes32 ilk) public {
        DssExecLib.updateCollateralPrice(ilk);
    }

    /****************************/
    /*** System Configuration ***/
    /****************************/
    function setContract_test(address base, bytes32 what, address addr) public {
        DssExecLib.setContract(base, what, addr);
    }

    function setContract_test(address base, bytes32 ilk, bytes32 what, address addr) public {
        DssExecLib.setContract(base, ilk, what, addr);
    }

    /******************************/
    /*** System Risk Parameters ***/
    /******************************/
    function setGlobalDebtCeiling_test(uint256 amount) public {
        DssExecLib.setGlobalDebtCeiling(amount);
    }

    function increaseGlobalDebtCeiling_test(uint256 amount) public {
        DssExecLib.increaseGlobalDebtCeiling(amount);
    }

    function decreaseGlobalDebtCeiling_test(uint256 amount) public {
        DssExecLib.decreaseGlobalDebtCeiling(amount);
    }

    function setDSR_test(uint256 rate) public {
        DssExecLib.setDSR(rate, true);
    }

    function setSurplusAuctionAmount_test(uint256 amount) public {
        DssExecLib.setSurplusAuctionAmount(amount);
    }

    function setSurplusBuffer_test(uint256 amount) public {
        DssExecLib.setSurplusBuffer(amount);
    }

    function setMinSurplusAuctionBidIncrease_test(uint256 pct_bps) public {
        DssExecLib.setMinSurplusAuctionBidIncrease(pct_bps);
    }

    function setSurplusAuctionBidDuration_test(uint256 duration) public {
        DssExecLib.setSurplusAuctionBidDuration(duration);
    }

    function setSurplusAuctionDuration_test(uint256 duration) public {
        DssExecLib.setSurplusAuctionDuration(duration);
    }

    function setDebtAuctionDelay_test(uint256 duration) public {
        DssExecLib.setDebtAuctionDelay(duration);
    }

    function setDebtAuctionDAIAmount_test(uint256 amount) public {
        DssExecLib.setDebtAuctionDAIAmount(amount);
    }

    function setDebtAuctionMKRAmount_test(uint256 amount) public {
        DssExecLib.setDebtAuctionMKRAmount(amount);
    }

    function setMinDebtAuctionBidIncrease_test(uint256 pct_bps) public {
        DssExecLib.setMinDebtAuctionBidIncrease(pct_bps);
    }

    function setDebtAuctionBidDuration_test(uint256 duration) public {
        DssExecLib.setDebtAuctionBidDuration(duration);
    }

    function setDebtAuctionDuration_test(uint256 duration) public {
        DssExecLib.setDebtAuctionDuration(duration);
    }

    function setDebtAuctionMKRIncreaseRate_test(uint256 pct_bps) public {
        DssExecLib.setDebtAuctionMKRIncreaseRate(pct_bps);
    }

    function setMaxTotalDAILiquidationAmount_test(uint256 amount) public {
        DssExecLib.setMaxTotalDAILiquidationAmount(amount);
    }

    function setEmergencyShutdownProcessingTime_test(uint256 duration) public {
        DssExecLib.setEmergencyShutdownProcessingTime(duration);
    }

    function setGlobalStabilityFee_test(uint256 rate) public {
        DssExecLib.setGlobalStabilityFee(rate);
    }

    function setDAIReferenceValue_test(uint256 value) public {
        DssExecLib.setDAIReferenceValue(value);
    }

    /*****************************/
    /*** Collateral Management ***/
    /*****************************/
    function setIlkDebtCeiling_test(bytes32 ilk, uint256 amount) public {
        DssExecLib.setIlkDebtCeiling(ilk, amount);
    }

    function increaseIlkDebtCeiling_test(bytes32 ilk, uint256 amount) public {
        DssExecLib.increaseIlkDebtCeiling(ilk, amount, true);
    }

    function decreaseIlkDebtCeiling_test(bytes32 ilk, uint256 amount) public {
        DssExecLib.decreaseIlkDebtCeiling(ilk, amount, true);
    }

    function setIlkAutoLineParameters_test(bytes32 ilk, uint256 amount, uint256 gap, uint256 ttl) public {
        DssExecLib.setIlkAutoLineParameters(ilk, amount, gap, ttl);
    }

    function setIlkAutoLineDebtCeiling_test(bytes32 ilk, uint256 amount) public {
        DssExecLib.setIlkAutoLineDebtCeiling(ilk, amount);
    }

    function removeIlkFromAutoLine_test(bytes32 ilk) public {
        DssExecLib.removeIlkFromAutoLine(ilk);
    }

    function setIlkMinVaultAmount_test(bytes32 ilk, uint256 amount) public {
        DssExecLib.setIlkMinVaultAmount(ilk, amount);
    }

    function setIlkLiquidationPenalty_test(bytes32 ilk, uint256 pct_bps) public {
        DssExecLib.setIlkLiquidationPenalty(ilk, pct_bps);
    }

    function setStartingPriceMultiplicativeFactor_test(bytes32 ilk, uint256 pct_bps) public {
        DssExecLib.setStartingPriceMultiplicativeFactor(ilk, pct_bps); // clip.buf
    }

    function setAuctionTimeBeforeReset_test(bytes32 ilk, uint256 duration) public {
        DssExecLib.setAuctionTimeBeforeReset(ilk, duration);
    }

    function setAuctionPermittedDrop_test(bytes32 ilk, uint256 pct_bps) public {
        DssExecLib.setAuctionPermittedDrop(ilk, pct_bps);
    }

    function setIlkMaxLiquidationAmount_test(bytes32 ilk, uint256 amount) public {
        DssExecLib.setIlkMaxLiquidationAmount(ilk, amount);
    }

    function setIlkLiquidationRatio_test(bytes32 ilk, uint256 pct_bps) public {
        DssExecLib.setIlkLiquidationRatio(ilk, pct_bps);
    }

    function setKeeperIncentivePercent_test(bytes32 ilk, uint256 pct_bps) public {
        DssExecLib.setKeeperIncentivePercent(ilk, pct_bps);
    }

    function setKeeperIncentiveFlatRate_test(bytes32 ilk, uint256 amount) public {
        DssExecLib.setKeeperIncentiveFlatRate(ilk, amount);
    }

    function setLiquidationBreakerPriceTolerance_test(address clip, uint256 pct_bps) public {
        DssExecLib.setLiquidationBreakerPriceTolerance(clip, pct_bps);
    }

    function setIlkStabilityFee_test(bytes32 ilk, uint256 rate) public {
        DssExecLib.setIlkStabilityFee(ilk, rate, true);
    }

    function setLinearDecrease_test(address calc, uint256 duration) public {
        DssExecLib.setLinearDecrease(calc, duration);
    }

    function setStairstepExponentialDecrease_test(address calc, uint256 duration, uint256 pct_bps) public {
        DssExecLib.setStairstepExponentialDecrease(calc, duration, pct_bps);
    }

    function setExponentialDecrease_test(address calc, uint256 pct_bps) public {
        DssExecLib.setExponentialDecrease(calc, pct_bps);
    }

    /*************************/
    /*** Oracle Management ***/
    /*************************/

    function whitelistOracleMedians_test(address oracle) public {
        DssExecLib.whitelistOracleMedians(oracle);
    }

    function addReaderToWhitelistCall_test(address medianizer, address reader) public {
        DssExecLib.addReaderToWhitelistCall(medianizer, reader);
    }

    function removeReaderFromWhitelistCall_test(address medianizer, address reader) public {
        DssExecLib.removeReaderFromWhitelistCall(medianizer, reader);
    }

    function setMedianWritersQuorum_test(address medianizer, uint256 minQuorum) public {
        DssExecLib.setMedianWritersQuorum(medianizer, minQuorum);
    }

    function addReaderToWhitelist_test(address osm, address reader) public {
        DssExecLib.addReaderToWhitelist(osm, reader);
    }

    function removeReaderFromWhitelist_test(address osm, address reader) public {
        DssExecLib.removeReaderFromWhitelist(osm, reader);
    }

    function allowOSMFreeze_test(address osm, bytes32 ilk) public {
        DssExecLib.allowOSMFreeze(osm, ilk);
    }

    /*****************************/
    /*** Direct Deposit Module ***/
    /*****************************/

    function setD3MTargetInterestRate_test(address d3m, uint256 pct_bps) public {
        DssExecLib.setD3MTargetInterestRate(d3m, pct_bps);
    }

    /*****************************/
    /*** Collateral Onboarding ***/
    /*****************************/

    function addCollateralBase_test(
        bytes32 ilk, address gem, address join, address clip, address calc, address pip
    ) public {
        DssExecLib.addCollateralBase(ilk, gem, join, clip, calc, pip);
    }

    function addNewCollateral_test(
        CollateralOpts memory co
    ) public {
        DssExecLib.addNewCollateral(co);
    }

    /***************/
    /*** Payment ***/
    /***************/

    function sendPaymentFromSurplusBuffer_test(address target, uint256 amount) public {
        DssExecLib.sendPaymentFromSurplusBuffer(target, amount);
    }

    /************/
    /*** Misc ***/
    /************/
    function linearInterpolation_test(bytes32 _name, address _target, bytes32 _what, uint256 _startTime, uint256 _start, uint256 _end, uint256 _duration) public returns (address) {
        return DssExecLib.linearInterpolation(_name, _target, _what, _startTime, _start, _end, _duration);
    }
    function linearInterpolation_test(bytes32 _name, address _target, bytes32 _ilk, bytes32 _what, uint256 _startTime, uint256 _start, uint256 _end, uint256 _duration) public returns (address) {
        return DssExecLib.linearInterpolation(_name, _target, _ilk, _what, _startTime, _start, _end, _duration);
    }

}
