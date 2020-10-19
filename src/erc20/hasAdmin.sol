pragma solidity ^0.7.3;

import "../utils/Context.sol";

contract HasAdmin is Context
{
	address payable public admin;

	constructor() public {
		admin = msg.sender;
	}

	modifier onlyAdmin() {
		require(_msgSender() == admin,
		"Sender not authorised to access.");
		_;
	}
	function transferOwnership(address payable newAdmin) external onlyAdmin {
        if (newAdmin != address(0))
            admin = newAdmin;
    }

	function removeAdmin() external onlyAdmin {
		admin = address(0);
	}
}