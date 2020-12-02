// SPDX-License-Identifier: AGPL-3.0-or-later
//
// DssExecFactory.sol -- MakerDAO Executive Spell Deployer
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

import "./DssExec.sol";

contract DssExecFactory {

    // An on-chain factory for creating new DssExec contracts.
    //
    // @param description  A string description of the spell
    // @param expiration   The timestamp this spell will expire. (Ex. now + 30 days)
    // @param officeHours  Limits the executive cast time to office hours (true for limit)
    // @param spellAction  The address of the spell action contract (DssAction)
    function newExec(string memory description, uint256 expiration, bool officeHours, address spellAction) public returns (address exec) {
        exec = address(new DssExec(description, expiration, officeHours, spellAction));
    }

    function newWeeklyExec(string memory description, address spellAction) public returns (address exec) {
        exec = newExec(description, now + 30 days, true, spellAction);
    }

    function newMonthlyExec(string memory description, address spellAction) public returns (address exec) {
        exec = newExec(description, now + 4 days, true, spellAction);
    }
}
