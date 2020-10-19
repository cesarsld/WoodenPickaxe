pragma solidity ^0.7.3;

import "../utils/Context.sol";

contract YieldController is Context {
	address payable public owner;

	constructor() public
	{
		owner = msg.sender;
	}

	modifier onlyOwner()
	{
		require(_msgSender() == owner,
		"Sender not authorised to access.");
		_;
	}
	function transferOwnership(address payable newOwner) external onlyOwner
	{
        if (newOwner != address(0)) {
            owner = newOwner;
        }
    }

	function removeAdmin() external onlyOwner {
		owner = address(0);
	}
}