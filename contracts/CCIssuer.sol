// SPDX-License-Identifier: GNU-GPL-3.0-or-later

pragma solidity ^0.8.0;

import "../interfaces/ITreasuryContract.sol";
import "../interfaces/IUserContract.sol";
import "contracts/UserContract.sol";

contract CCIssuer {
    address private ownerDaoAddress;
    address private treasuryAddress;

    mapping (address => address[]) private issuedCC;

    event CCIssued(address indexed to, address indexed ccAddress, uint256 indexed amount);

    constructor(address _ownerDaoAddress, address _treasuryAddress) {
        ownerDaoAddress = _ownerDaoAddress;
        treasuryAddress = _treasuryAddress;
    }

    function issueCC(address _userAddress, uint256 _inititalBalance) public {
        require(msg.sender == ownerDaoAddress, "Only DAO can issue new CC");

        // Deploy a new UserContract
        UserContract userContract = new UserContract(
            _userAddress,
            _inititalBalance,
            treasuryAddress
        );

        // Add it to the treasury
        ITreasuryContract(treasuryAddress).addCCAddress(address(userContract));

        // Add the record to issuedCC
        issuedCC[_userAddress].push(address(userContract));

        emit CCIssued(_userAddress, address(userContract), _inititalBalance);
    }

    function getNoOfCC(address _userAddress) public view returns (uint256) {
        return issuedCC[_userAddress].length;
    }

    function getCCAddress(address _userAddress, uint256 _index) public view returns (address) {
        require(_index < issuedCC[_userAddress].length, "Index out of bounds");
        return issuedCC[_userAddress][_index];
    }
}
