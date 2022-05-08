// SPDX-License-Identifier: GNU-GPL-3.0-or-later

pragma solidity ^0.8.0;

import "../interfaces/ITreasuryContract.sol";

contract UserContract {
    uint256 public availableBalance; // In Paisa. 1Rs = 100
    uint256 public nonce;
    address public owner;

    address private treasuryAddress;

    event CC_Charged(address indexed _by, uint256 indexed _amount);

    constructor(
        address _owner,
        uint256 _initialBalance,
        address _treasuryAddress
    ) {
        owner = _owner;
        availableBalance = _initialBalance;
        treasuryAddress = _treasuryAddress;
        nonce = 0;
    }

    function canCharge(uint256 _amount) public view returns (bool) {
        return availableBalance >= _amount;
    }

    function charge(
        uint256 _amount,
        bytes memory _signature,
        address _tokenAddress
    ) public {
        require(canCharge(_amount), "Don't have enough balance");
        require(verifySignature(_amount, _signature), "Signature not verified");

        // Ask treasury to transfer the funds
        ITreasuryContract(treasuryAddress).sendToken(
            _amount,
            2,
            _tokenAddress,
            address(this),
            msg.sender
        );

        availableBalance -= _amount;
        nonce += 1;

        emit CC_Charged(msg.sender, _amount);
    }

    function getCurrentPayloadHash(uint256 _amount, address _targetedReceiver)
        public
        view
        returns (bytes32)
    {
        // Message Format => <Nonce>_<Receiver Address>_<Amount>
        // Example => 0_0x1234567890123456789012345678901234567890_100
        string memory _payload = string(
            abi.encodePacked(nonce, "_", _targetedReceiver, "_", _amount)
        );
        return keccak256(abi.encodePacked(_payload));
    }

    function verifySignature(uint256 _amount, bytes memory _signature)
        internal
        view
        returns (bool)
    {
        bytes32 payloadHash = getCurrentPayloadHash(_amount, msg.sender);
        bytes32 ethSignedMessageHash = getEthSignedMessageHash(payloadHash);

        return recover(ethSignedMessageHash, _signature) == owner;
    }

    function getEthSignedMessageHash(bytes32 _messageHash)
        internal
        pure
        returns (bytes32)
    {
        return
            keccak256(
                abi.encodePacked(
                    "\x19Ethereum Signed Message:\n32",
                    _messageHash
                )
            );
    }

    function recover(bytes32 _ethSignedMessageHash, bytes memory _signature)
        private
        pure
        returns (address)
    {
        (bytes32 r, bytes32 s, uint8 v) = _split(_signature);
        return ecrecover(_ethSignedMessageHash, v, r, s);
    }

    function _split(bytes memory _signature)
        internal
        pure
        returns (
            bytes32 r,
            bytes32 s,
            uint8 v
        )
    {
        require(_signature.length == 65, "Invalid signature length");
        assembly {
            r := mload(add(_signature, 32))
            s := mload(add(_signature, 64))
            v := byte(0, mload(add(_signature, 96)))
        }
    }

    function flush() public {
        require(msg.sender == owner);
        nonce += 1;
    }

    function getCurrentNonce() public view returns (uint256) {
        return nonce;
    }
}
