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

pragma solidity ^0.6.7;

contract DssAction {

    address public immutable lib;

    constructor(address lib_) public {
        lib = lib_;
    }

    function _dcall(bytes memory data) internal {
        (bool ok,) = lib.delegatecall(data);
        require(ok, "fail");
    }

    function libCall(string memory sig) internal {
        _dcall(abi.encodeWithSignature(sig));
    }

    function libCall(string memory sig, uint256 num) internal {
        _dcall(abi.encodeWithSignature(sig, num));
    }

    function libCall(string memory sig, bytes32 what) internal {
        _dcall(abi.encodeWithSignature(sig, what));
    }

    function libCall(string memory sig, string memory what) internal {
        _dcall(abi.encodeWithSignature(sig, what));
    }

    function libCall(string memory sig, bytes32 what, uint256 num) internal {
        _dcall(abi.encodeWithSignature(sig, what, num));
    }

    function libCall(string memory sig, bytes32 what, address addr) internal {
        _dcall(abi.encodeWithSignature(sig, what, addr));
    }

    function libCall(string memory sig, address addr, uint256 num) internal {
        _dcall(abi.encodeWithSignature(sig, addr, num));
    }

    function libCall(string memory sig, address addr, address addr2) internal {
        _dcall(abi.encodeWithSignature(sig, addr, addr2));
    }

    function libCall(string memory sig, address addr, bytes32 what, address addr2) internal {
        _dcall(abi.encodeWithSignature(sig, addr, what, addr2));
    }

    function libCall(string memory sig, address addr, bytes32 what, bytes32 what2, address addr2) internal {
        _dcall(abi.encodeWithSignature(sig, addr, what, what2, addr2));
    }

    function libCall(string memory sig, bytes32 what, address addr, address addr2) internal {
        _dcall(abi.encodeWithSignature(sig, what, addr, addr2));
    }

    function libCall(string memory sig, address addr, address[] memory arr) internal {
        _dcall(abi.encodeWithSignature(sig, addr, arr));
    }

    function libCall(string memory sig, address addr, bytes32 what) internal {
        _dcall(abi.encodeWithSignature(sig, addr, what));
    }

    function libCall(
        string memory sig,
        bytes32 what,
        address[] memory arr,
        bool    bool1,
        bool[] memory bools,
        uint256 num1,
        uint256 num2,
        uint256 num3,
        uint256 num4,
        uint256 num5,
        uint256 num6,
        uint256 num7,
        uint256 num8,
        uint256 num9
    ) internal {
        _dcall(abi.encodeWithSignature(sig, what, arr, bool1, bools, num1, num2, num3, num4, num5, num6, num7, num8, num9));
    }

    /****************************/
    /*** Changelog Management ***/
    /****************************/
    function setChangelogAddress(bytes32 key, address value) internal {
        libCall("setChangelogAddress(bytes32,address)", key, value);
    }

    function setChangelogVersion(string memory version) internal {
        libCall("setChangelogVersion(string)", version);
    }

    function setChangelogIPFS(string memory ipfs) internal {
        libCall("setChangelogIPFS(string)", ipfs);
    }

    function setChangelogSHA256(string memory SHA256) internal {
        libCall("setChangelogSHA256(string)", SHA256);
    }

    /**********************/
    /*** Authorizations ***/
    /**********************/
    function authorize(address base, address ward) internal virtual {
        libCall("authorize(address,address)", base, ward);
    }

    function deauthorize(address base, address ward) internal {
        libCall("deauthorize(address,address)", base, ward);
    }

    /**************************/
    /*** Accumulating Rates ***/
    /**************************/
    function accumulateDSR() internal {
        libCall("accumulateDSR()");
    }

    function accumulateCollateralStabilityFees(bytes32 ilk) internal {
        libCall("accumulateCollateralStabilityFees(bytes32)", ilk);
    }

    /*********************/
    /*** Price Updates ***/
    /*********************/
    function updateCollateralPrice(bytes32 ilk) internal {
        libCall("updateCollateralPrice(bytes32)", ilk);
    }

    /****************************/
    /*** System Configuration ***/
    /****************************/
    function setContract(address base, bytes32 what, address addr) internal {
        libCall("setContract(address,bytes32,address)", base, what, addr);
    }

    function setContract(address base, bytes32 ilk, bytes32 what, address addr) internal {
        libCall("setContract(address,bytes32,bytes32,address)", base, ilk, what, addr);
    }

    /******************************/
    /*** System Risk Parameters ***/
    /******************************/
    function setGlobalDebtCeiling(uint256 amount) internal {
        libCall("setGlobalDebtCeiling(uint256)", amount);
    }

    function increaseGlobalDebtCeiling(uint256 amount) internal {
        libCall("increaseGlobalDebtCeiling(uint256)", amount);
    }

    function decreaseGlobalDebtCeiling(uint256 amount) internal {
        libCall("decreaseGlobalDebtCeiling(uint256)", amount);
    }

    function setDSR(uint256 rate) internal {
        libCall("setDSR(uint256)", rate);
    }

    function setSurplusAuctionAmount(uint256 amount) internal {
        libCall("setSurplusAuctionAmount(uint256)", amount);
    }

    function setSurplusBuffer(uint256 amount) internal {
        libCall("setSurplusBuffer(uint256)", amount);
    }

    function setMinSurplusAuctionBidIncrease(uint256 pct_bps) internal {
        libCall("setMinSurplusAuctionBidIncrease(uint256)", pct_bps);
    }

    function setSurplusAuctionBidDuration(uint256 duration) internal {
        libCall("setSurplusAuctionBidDuration(uint256)", duration);
    }

    function setSurplusAuctionDuration(uint256 duration) internal {
        libCall("setSurplusAuctionDuration(uint256)", duration);
    }

    function setDebtAuctionDelay(uint256 duration) internal {
        libCall("setDebtAuctionDelay(uint256)", duration);
    }

    function setDebtAuctionDAIAmount(uint256 amount) internal {
        libCall("setDebtAuctionDAIAmount(uint256)", amount);
    }

    function setDebtAuctionMKRAmount(uint256 amount) internal {
        libCall("setDebtAuctionMKRAmount(uint256)", amount);
    }

    function setMinDebtAuctionBidIncrease(uint256 pct_bps) internal {
        libCall("setMinDebtAuctionBidIncrease(uint256)", pct_bps);
    }

    function setDebtAuctionBidDuration(uint256 duration) internal {
        libCall("setDebtAuctionBidDuration(uint256)", duration);
    }

    function setDebtAuctionDuration(uint256 duration) internal {
        libCall("setDebtAuctionDuration(uint256)", duration);
    }

    function setDebtAuctionMKRIncreaseRate(uint256 pct_bps) internal {
        libCall("setDebtAuctionMKRIncreaseRate(uint256)", pct_bps);
    }

    function setMaxTotalDAILiquidationAmount(uint256 amount) internal {
        libCall("setMaxTotalDAILiquidationAmount(uint256)", amount);
    }

    function setEmergencyShutdownProcessingTime(uint256 duration) internal {
        libCall("setEmergencyShutdownProcessingTime(uint256)", duration);
    }

    function setGlobalStabilityFee(uint256 rate) internal {
        libCall("setGlobalStabilityFee(uint256)", rate);
    }

    function setDAIReferenceValue(uint256 value) internal {
        libCall("setDAIReferenceValue(uint256)", value);
    }

    /*****************************/
    /*** Collateral Management ***/
    /*****************************/
    function setIlkDebtCeiling(bytes32 ilk, uint256 amount) internal {
        libCall("setIlkDebtCeiling(bytes32,uint256)", ilk, amount);
    }

    function setIlkMinVaultAmount(bytes32 ilk, uint256 amount) internal {
        libCall("setIlkMinVaultAmount(bytes32,uint256)", ilk, amount);
    }

    function setIlkLiquidationPenalty(bytes32 ilk, uint256 pct_bps) internal {
        libCall("setIlkLiquidationPenalty(bytes32,uint256)", ilk, pct_bps);
    }

    function setIlkMaxLiquidationAmount(bytes32 ilk, uint256 amount) internal {
        libCall("setIlkMaxLiquidationAmount(bytes32,uint256)", ilk, amount);
    }

    function setIlkLiquidationRatio(bytes32 ilk, uint256 pct_bps) internal {
        libCall("setIlkLiquidationRatio(bytes32,uint256)", ilk, pct_bps);
    }

    function setIlkMinAuctionBidIncrease(bytes32 ilk, uint256 pct_bps) internal {
        libCall("setIlkMinAuctionBidIncrease(bytes32,uint256)", ilk, pct_bps);
    }

    function setIlkBidDuration(bytes32 ilk, uint256 duration) internal {
        libCall("setIlkBidDuration(bytes32,uint256)", ilk, duration);
    }

    function setIlkAuctionDuration(bytes32 ilk, uint256 duration) internal {
        libCall("setIlkAuctionDuration(bytes32,uint256)", ilk, duration);
    }

    function setIlkStabilityFee(bytes32 ilk, uint256 rate) internal {
        libCall("setIlkStabilityFee(bytes32,uint256)", ilk, rate);
    }

    /***********************/
    /*** Core Management ***/
    /***********************/
    function updateCollateralAuctionContract(bytes32 ilk, address newFlip, address oldFlip) internal {
        libCall("updateCollateralAuctionContract(bytes32,address,address)", ilk, newFlip, oldFlip);
    }

    function updateSurplusAuctionContract(address newFlap, address oldFlap) internal {
        libCall("updateSurplusAuctionContract(address,address)", newFlap, oldFlap);
    }

    function updateDebtAuctionContract(address newFlop, address oldFlop) internal {
        libCall("updateDebtAuctionContract(address,address)", newFlop, oldFlop);
    }

    /*************************/
    /*** Oracle Management ***/
    /*************************/
    function addWritersToMedianWhitelist(address medianizer, address[] memory feeds) internal {
        libCall("addWritersToMedianWhitelist(address,address[])", medianizer, feeds);
    }

    function removeWritersFromMedianWhitelist(address medianizer, address[] memory feeds) internal {
        libCall("removeWritersFromMedianWhitelist(address,address[])", medianizer, feeds);
    }

    function addReadersToMedianWhitelist(address medianizer, address[] memory readers) internal {
        libCall("addReadersToMedianWhitelist(address,address[])", medianizer, readers);
    }

    function addReaderToMedianWhitelist(address medianizer, address reader) internal {
        libCall("addReaderToMedianWhitelist(address,address)", medianizer, reader);
    }

    function removeReadersFromMedianWhitelist(address medianizer, address[] memory readers) internal {
        libCall("removeReadersFromMedianWhitelist(address,address[])", medianizer, readers);
    }

    function removeReaderFromMedianWhitelist(address medianizer, address reader) internal {
        libCall("removeReaderFromMedianWhitelist(address,address)", medianizer, reader);
    }

    function setMedianWritersQuorum(address medianizer, uint256 minQuorum) internal {
        libCall("setMedianWritersQuorum(address,uint256)", medianizer, minQuorum);
    }

    function addReaderToOSMWhitelist(address osm, address reader) internal {
        libCall("addReaderToOSMWhitelist(address,address)", osm, reader);
    }

    function removeReaderFromOSMWhitelist(address osm, address reader) internal {
        libCall("removeReaderFromOSMWhitelist(address,address)", osm, reader);
    }

    function allowOSMFreeze(address osm, bytes32 ilk) internal {
        libCall("allowOSMFreeze(address,bytes32)", osm, ilk);
    }

    /*****************************/
    /*** Collateral Onboarding ***/
    /*****************************/
    function addNewCollateral(
        bytes32          ilk,
        address[] memory addresses,
        bool             liquidatable,
        bool[] memory    oracleSettings,
        uint256          ilkDebtCeiling,
        uint256          minVaultAmount,
        uint256          maxLiquidationAmount,
        uint256          liquidationPenalty,
        uint256          ilkStabilityFee,
        uint256          bidIncrease,
        uint256          bidDuration,
        uint256          auctionDuration,
        uint256          liquidationRatio
    ) internal {
        libCall(
            "addNewCollateral(bytes32,address[],bool,bool[],uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256,uint256)",
            ilk,
            addresses,
            liquidatable,
            oracleSettings,
            ilkDebtCeiling,
            minVaultAmount,
            maxLiquidationAmount,
            liquidationPenalty,
            ilkStabilityFee,
            bidIncrease,
            bidDuration,
            auctionDuration,
            liquidationRatio
        );
    }
}
