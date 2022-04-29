// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../interfaces/ITreasuryContract.sol";
import "../interfaces/IUserContract.sol";
import "contracts/UserContract.sol";
import "hardhat/console.sol";

contract CCIssuer {
    address private ownerDaoAddress;
    address private treasuryAddress;

    constructor(address _ownerDaoAddress, address _treasuryAddress) {
        ownerDaoAddress = _ownerDaoAddress;
        treasuryAddress = _treasuryAddress;
    }

    function issueCC(address _userAddress, uint256 _inititalBalance) public returns(address) {
        require(msg.sender == ownerDaoAddress, "Only DAO can issue new CC");

        // Deploy a new UserContract
        UserContract userContract = new UserContract(
            _userAddress,
            _inititalBalance,
            treasuryAddress
        );

        // Add it to the treasury
        ITreasuryContract(treasuryAddress).addCCAddress(address(userContract));

        console.log("UserContract created at: ", address(userContract));
        return address(userContract);
    }
}
