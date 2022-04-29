// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

interface ITreasuryContract {
    function sendToken(
        uint256 _amount,
        uint8 _inDecimals,
        address _targetToken,
        address _sender,
        address _receiver
    ) external;

    function withdrawFunds(
        uint256 _amount,
        address _tokenAddress,
        address _receiver
    ) external;

    function transferOwnership(address _newOwner) external;

    function addCCAddress(address _ccAddress) external;

    function removeCCAddress(address _ccAddress) external;
}
