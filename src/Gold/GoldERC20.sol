pragma solidity ^0.7.3;

import "../utils/Contect.sol";
import "../erc20/ERC20.sol";
import "../erc20/mintable.sol";

contract Gold is ERC20, Mintable{
	function mint(address _account, uint256 _amount) external onlyMinter {
		_mint(_account, _address);
	}

	function burn(uint256 _amount) external {
		_burn(msg.sender, _amount);
	}
}