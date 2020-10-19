pragma solidity ^0.7.3;

import "../erc721/ERC721.sol";
import "../utils/SafeMath.sol";
import "../erc20/ERC20.sol";
import "../erc20/mintable.sol";
import "./YieldController.sol";
import "../Gold/GoldEREC20.sol";

contract Pickaxe is ERC721, YieldController {
	using SafeMath for uint256;

	enum Rank {WOOD, IRON, GOLD}

	// could add modifiers that could increase max capacity and/or yield
	struct YieldNFT {
		uint256 bornAt;
		uint256 lastUpdate;
		uint256 expiry;
		Rank rank;
	}

	uint256 constant WOOD_MAX_CAPACITY = 500 * (10**18);
	uint256 constant IRON_MAX_CAPACITY = 2000 * (10**18);
	uint256 constant GOLD_MAX_CAPACITY = 10000 * (10**18);

	uint256 constant WOOD_YIELD_RATE = 500 * (10**18) / 4 days;
	uint256 constant IRON_YIELD_RATE = 2000 * (10**18) / 8 days;
	uint256 constant GOLD_YIELD_RATE = 10000 * (10**18) / 12 days;

	uint256 constant GLOBAL_MODIFIER_UNIT = 10000;

	uint256 public globalModifier;
	Gold public gold = Gold(0x0);
	bool public burnAllowed = false;
	bool public claimable = true;

	YieldNFT[] yieldNft;

	address private signer;

	event PickaxeMinted(uint256 bornAt, uint256 lastUpdate, uint256 expiry, uint8 rank);
	event Yield(uint256 indexed tokenId, uint256 amount);

	modifier mustBeValidToken(uint256 _tokenId) {
		require(ownerOf(_tokenId) != address(0), "Pickaxe: Token ID does not exist.");
    	_;
	}
	modifier canBurn {
		require (burnAllowed == true, "Pickaxe: Burn not allowed.");
		_;
	}

	constructor (string memory name, string memory symbol, address _signer) ERC721(name, symbol) public {
		globalModifier = 10000;
		signer = _signer;
    }

	function getYieldNFT(uint256 _tokenId) external view  mustBeValidToken(_tokenId)
	returns (uint256, uint256, uint256, uint256, uint256, uint8) {
		YieldNFT storage nft = yieldNft[_tokenId];
		return (nft.bornAt, nft.lastUpdate, nft.expiry, nft.maxCapacity, nft.ratePerSecond, uint8(nft.rank));
	}

	function spawnWoodPickaxe(uint256 _expiry, address _owner) external {
		Mintable mintable = Mintable(_tokenAddress);
		require (mintable.isMinter(address(this)) == true, "Pickaxe: Pickaxe contract not a minter of token address.");
		YieldNFT memory nft = YieldNFT(now, now, _expiry, WOOD_MAX_CAPACITY, WOOD_YIELD_RATE, Rank.WOOD);
		uint256 id = yieldNft.length;
		yieldNft.push(nft);
		_safeMint(_owner, id);
		emit YieldNFTMinted(nft.bornAt, nft.lastUpdate, nft.expiry, nft.maxCapacity, nft.ratePerSecond, uint8(nft.rank));
	}

	function burn(uint256 _tokenId) public canBurn {
		require (ownerOf(_tokenId) == _msgSender(), "Token ID does not belong to sender.");
		_burn(_tokenId);
	}

	// potentially add task to collect gold and add signature just like upgrade pickaxe
	function collectGold(uint256 _tokenId) public {
		require(claimable, "Pickaxe: Yield not claimable.")
		require (ownerOf(_tokenId) == _msgSender(), "Pickaxe: Token ID does not belong to sender.");
		YieldNFT storage nft = yieldNft[_tokenId];
		require (now > nft.lastUpdate, "Pickaxe: Block timestamp is below lastUpdate value.");
		uint256 amountToMint = _calculateYield(nft.lastUpdate, nft.rank);
		nft.lastUpdate = now;
		gold.mint(_msgSender(), _amountToMint);
		emit Yield(amountToMint, nft.tokenAddress);
	}

	// add a requirement to upgrade (spend gold, do an action on the site etc)
	function upgadePickaxe(uint256 _tokenId, uint8 rank, bytes _signature) public {
		bytes32 msgHash = keccak256(abi.encodePacked(_tokenId,rank));
		YieldNFT storage nft = yieldNft[_tokenId];
		require(nft.rank != Rank.GOLD, "Pickaxe: Cannot upgrade beyond this rank.");
		require(recover(msgHash, _signature) == signer, "Pickaxe: Signature is not correct");
		collectGold(_tokenId);
		nft.rank = Rank(rank);
	}

	function _calculateYield(uint256 _lastUpdate, Rank rank) internal view returns(uint) {
		(uint256 _rate, uint256 _capacity) = _getRankVariables(rank);
		uint256 amount = now.sub(_lastUpdate).mul(_rate).mul(globalModifier).div(GLOBAL_MODIFIER_UNIT);
		if (amount > _capacity)
			return _capacity;
		return amount;
	}

	function _getRankVariables(Rank rank) private pure returns (uint256, uint256) {
		if (rank == Rank.WOOD)
			return (WOOD_MAX_CAPACITY, WOOD_YIELD_RATE);
		else if (rank == Rank.IRON)
			return (IRON_MAX_CAPACITY, IRON_YIELD_RATE);
		else if (rank == Rank.GOLD)
			return (GOLD_MAX_CAPACITY, GOLD_YIELD_RATE);
	}

	function setBurn(bool _value) external onlyOwner {
		burnAllowed = _value;
	}

	function setClaim(bool _value) external onlyOwner {
		claimable = _value;
	}

	function setGlobalModifier(uint256 _value) external onlyOwner {
		globalModifier = _value;
	}

	function recover(bytes32 _msgHash, bytes _sig) private pure returns (address) {
		bytes32 r;
		bytes32 s;
		uint8 v;

		if (s_ig.length != 65)
			return address(0);
		assembly {
			r := mload(add(_sig, 32))
			s := mload(add(_sig, 64))
			v := byte(0, mload(add(_sig, 96)))
		}
		if(v < 27)
			v += 27;
		if (v != 27 && v != 28)
			return address(0);
		else
			return ecrecover(_msgHash, v, r, s);
	}
}