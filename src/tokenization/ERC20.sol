// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

/// @title ERC20
/// @notice ERC20 implementation with EIP-2612 support and optimized gas usage via Yul
/// @dev Inspired by OpenZeppelin: https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/ERC20.sol
/// @dev Inspired by Solady: https://github.com/Vectorized/solady/blob/main/src/tokens/ERC20.sol
/// @author fomoweth
abstract contract ERC20 {
	/// @notice Thrown when permit deadline has passed
	error DeadlineExpired();

	/// @notice Thrown when spender doesn't have sufficient allowance
	error InsufficientAllowance();

	/// @notice Thrown when account doesn't have sufficient balance
	error InsufficientBalance();

	/// @notice Thrown when approver address is invalid (zero address)
	error InvalidApprover();

	/// @notice Thrown when receiver address is invalid (zero address)
	error InvalidReceiver();

	/// @notice Thrown when sender address is invalid (zero address)
	error InvalidSender();

	/// @notice Thrown when permit signature is invalid or doesn't match owner
	error InvalidSigner();

	/// @notice Thrown when spender address is invalid (zero address)
	error InvalidSpender();

	/// @notice Thrown when total supply would overflow uint256
	error TotalSupplyOverflow();

	/// @notice Emitted when `value` amount tokens is approved by `owner` to be used by `spender`
	event Approval(address indexed owner, address indexed spender, uint256 value);

	/// @notice Emitted when `value` amount tokens is transferred from `sender` to `receiver`
	event Transfer(address indexed sender, address indexed receiver, uint256 value);

	/// @notice Precomputed {Approval} event signature for gas optimization
	/// @dev keccak256(bytes("Approval(address,address,uint256)"))
	uint256 private constant APPROVAL_EVENT_SIGNATURE = 0x8c5be1e5ebec7d5bd14f71427d1e84f3dd0314c0f7b2291e5b200ac8c7c3b925;

	/// @notice Precomputed {Transfer} event signature for gas optimization
	/// @dev keccak256(bytes("Transfer(address,address,uint256)"))
	uint256 private constant TRANSFER_EVENT_SIGNATURE = 0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef;

	/// @notice Precomputed EIP-712 domain typehash for gas optimization
	/// @dev keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)")
	uint256 private constant DOMAIN_TYPEHASH = 0x8b73c3c69bb8fe3d512ecc4cf759cc79239f7b179b0ffacaa9a75d522b39400f;

	/// @notice Precomputed EIP-2612 permit typehash for gas optimization
	/// @dev keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)")
	uint256 private constant PERMIT_TYPEHASH = 0x6e71edae12b1b97f4d1f60370fef10105fa2faae0126114a169c64845d6126c9;

	/// @notice Seed for computing allowance storage slots
	/// @dev First 4 bytes of keccak256("ERC20.storage.allowances") for collision resistance
	uint256 private constant ALLOWANCES_SLOT_SEED = 0x9901fc93;

	/// @notice Seed for computing balance storage slots
	/// @dev First 4 bytes of keccak256("ERC20.storage.balances") for collision resistance
	uint256 private constant BALANCES_SLOT_SEED = 0x87a211a2;

	/// @notice Seed for computing nonce storage slots
	/// @dev First 4 bytes of keccak256("ERC20.storage.nonces") for collision resistance
	uint256 private constant NONCES_SLOT_SEED = 0x38377508;

	/// @notice Storage slot for total supply using ERC-7201 namespace standard
	/// @dev keccak256(abi.encode(uint256(keccak256("ERC20.storage.totalSupply")) - 1)) & ~bytes32(uint256(0xff))
	uint256 private constant TOTAL_SUPPLY_SLOT = 0xa4711d1da1eafbe0408d37bf83c2d50cd4f0195bddddf2c70d22f9310191b800;

	/// @notice Returns the name of the token
	/// @dev Must be implemented by inheriting contracts
	/// @return Token name string
	function name() public view virtual returns (string memory);

	/// @notice Returns the symbol of the token
	/// @dev Must be implemented by inheriting contracts
	/// @return Token symbol string
	function symbol() public view virtual returns (string memory);

	/// @notice Returns the decimals places of the token
	/// @dev Default implementation returns 18, can be overridden
	/// @return Number of decimals used for token display and calculations
	function decimals() public view virtual returns (uint8) {
		return 18;
	}

	/// @notice Returns the EIP-712 domain separator used in the encoding of the signature for {permit}
	/// @return separator Current domain separator for this contract and chain
	function DOMAIN_SEPARATOR() public view virtual returns (bytes32 separator) {
		return _buildDomainSeparator();
	}

	/// @notice Returns the value of tokens in existence
	/// @return totalSupply_ Current total supply of tokens
	function totalSupply() public view virtual returns (uint256 totalSupply_) {
		assembly ("memory-safe") {
			totalSupply_ := sload(TOTAL_SUPPLY_SLOT)
		}
	}

	/// @notice Returns the remaining number of tokens that `spender` will be allowed to spend on behalf of `owner`
	/// @param owner Token owner address
	/// @param spender Address authorized to spend tokens
	/// @return allowance_ Current allowance amount
	function allowance(address owner, address spender) public view virtual returns (uint256 allowance_) {
		assembly ("memory-safe") {
			// Compute allowance storage slot using optimized packing:
			// Pack owner (shifted left 96 bits) with slot seed in first 32 bytes
			mstore(0x00, or(shl(0x60, owner), ALLOWANCES_SLOT_SEED))
			// Pack spender (shifted left 96 bits) in second 32 bytes
			mstore(0x20, shl(0x60, spender))
			// Hash the 52-byte packed data (0x34 = 52 bytes)
			allowance_ := sload(keccak256(0x00, 0x34))
		}
	}

	/// @notice Returns the value of tokens owned by `account`
	/// @param account Address to query balance for
	/// @return balance_ Current balance of the account
	function balanceOf(address account) public view virtual returns (uint256 balance_) {
		assembly ("memory-safe") {
			// Compute balance storage slot using optimized packing:
			// Pack account (shifted left 96 bits) with slot seed
			mstore(0x00, or(shl(0x60, account), BALANCES_SLOT_SEED))
			// Hash the 32-byte packed data
			balance_ := sload(keccak256(0x00, 0x20))
		}
	}

	/// @notice Returns the current nonce for `owner`
	/// @param owner Address to query nonce for
	/// @return nonce Current nonce value used for permit signatures
	function nonces(address owner) public view virtual returns (uint256 nonce) {
		assembly ("memory-safe") {
			// Compute nonce storage slot using optimized packing:
			// Pack owner (shifted left 96 bits) with slot seed
			mstore(0x00, or(shl(0x60, owner), NONCES_SLOT_SEED))
			// Hash the 32-byte packed data
			nonce := sload(keccak256(0x00, 0x20))
		}
	}

	/// @notice Sets a `value` amount of tokens as the allowance of `spender` over the caller's tokens
	/// @param spender Address to grant allowance to
	/// @param value Amount of tokens to approve
	/// @return Always returns true on success (reverts on failure)
	function approve(address spender, uint256 value) public virtual returns (bool) {
		_validateAddress(spender, InvalidSpender.selector);
		_approve(spender, value);
		return true;
	}

	/// @notice Moves a `value` amount of tokens from the caller's account to `receiver`
	/// @param receiver Address to transfer tokens to
	/// @param value Amount of tokens to transfer
	/// @return Always returns true on success (reverts on failure)
	function transfer(address receiver, uint256 value) public virtual returns (bool) {
		_validateAddress(receiver, InvalidReceiver.selector);
		_update(msg.sender, receiver, value);
		return true;
	}

	/// @notice Moves a `value` amount of tokens from `sender` to `receiver`
	/// @param sender Address to transfer tokens from
	/// @param receiver Address to transfer tokens to
	/// @param value Amount of tokens to transfer
	/// @return Always returns true on success (reverts on failure)
	function transferFrom(address sender, address receiver, uint256 value) public virtual returns (bool) {
		_validateAddress(sender, InvalidSender.selector);
		_validateAddress(receiver, InvalidReceiver.selector);
		_spendAllowance(sender, msg.sender, value);
		_update(sender, receiver, value);
		return true;
	}

	/// @notice Sets `value` as the allowance of `spender` over `owner`'s tokens, given `owner`'s signed approval
	/// @param owner Token owner who signed the permit
	/// @param spender Address to grant allowance to
	/// @param value Amount of tokens to approve
	/// @param deadline Timestamp when the permit expires
	/// @param v Recovery byte of the signature
	/// @param r First 32 bytes of the signature
	/// @param s Second 32 bytes of the signature
	function permit(
		address owner,
		address spender,
		uint256 value,
		uint256 deadline,
		uint8 v,
		bytes32 r,
		bytes32 s
	) public virtual {
		_validateAddress(owner, InvalidApprover.selector);
		_validateAddress(spender, InvalidSpender.selector);

		// Compute current EIP-712 domain separator
		bytes32 separator = _buildDomainSeparator();

		assembly ("memory-safe") {
			// Revert if deadline has passed
			if gt(timestamp(), deadline) {
				mstore(0x00, 0x1ab7da6b) // DeadlineExpired()
				revert(0x1c, 0x04)
			}

			// Load free memory pointer
			let ptr := mload(0x40)

			// Clean upper 96 bits of addresses for consistent packing
			owner := shr(0x60, shl(0x60, owner))
			spender := shr(0x60, shl(0x60, spender))

			// Compute nonce storage slot and load current nonce value
			mstore(0x00, or(shl(0x60, owner), NONCES_SLOT_SEED))
			let slot := keccak256(0x00, 0x20)
			let nonce := sload(slot)

			// Build EIP-2612 permit struct hash
			mstore(ptr, PERMIT_TYPEHASH)
			mstore(add(ptr, 0x20), owner)
			mstore(add(ptr, 0x40), spender)
			mstore(add(ptr, 0x60), value)
			mstore(add(ptr, 0x80), nonce)
			mstore(add(ptr, 0xa0), deadline)

			// Prepare EIP-191 message hash: "\x19\x01" + domainSeparator + structHash
			mstore(0x40, keccak256(ptr, 0xc0)) // Store struct hash at 0x40
			mstore(0x20, separator) // Store domain separator at 0x20
			mstore(0x00, 0x1901) // Store EIP-191 prefix at 0x00

			// Prepare ecrecover calldata
			mstore(0x00, keccak256(0x1e, 0x42)) // Final message hash (skip 30 bytes, take 66 bytes)
			mstore(0x20, and(0xff, v))
			mstore(0x40, r)
			mstore(0x60, s)

			// Call ecrecover precompile and increment nonce if successful
			// staticcall returns 1 on success, 0 on failure
			sstore(slot, add(nonce, staticcall(gas(), 0x01, 0x00, 0x80, 0x20, 0x20)))

			// Verify recovered address matches owner
			if iszero(eq(mload(returndatasize()), owner)) {
				mstore(0x00, 0x815e1d64) // InvalidSigner()
				revert(0x1c, 0x04)
			}

			// Update allowance storage
			mstore(0x40, or(shl(0xa0, ALLOWANCES_SLOT_SEED), spender))
			sstore(keccak256(0x2c, 0x34), value)

			// Emit {Approval} event
			log3(add(ptr, 0x60), 0x20, APPROVAL_EVENT_SIGNATURE, owner, spender)

			// Restore memory pointers
			mstore(0x40, ptr)
			mstore(0x60, 0x00)
		}
	}

	/// @notice Mints a `value` amount of tokens to `account`, increasing the total supply
	/// @dev Updates total supply and account balance, emits Transfer event from zero address
	/// @param account Address to mint tokens to
	/// @param value Amount of tokens to mint
	function _mint(address account, uint256 value) internal {
		_validateAddress(account, InvalidReceiver.selector);
		_update(address(0), account, value);
	}

	/// @notice Burns a `value` amount of tokens from `account`, decreasing the total supply
	/// @dev Updates total supply and account balance, emits Transfer event to zero address
	/// @param account Address to burn tokens from
	/// @param value Amount of tokens to burn
	function _burn(address account, uint256 value) internal {
		_validateAddress(account, InvalidSender.selector);
		_update(account, address(0), value);
	}

	/// @notice Transfers a `value` amount of tokens from `sender` to `receiver`,
	/// or alternatively mints or burns if `sender` or `receiver` is the zero address
	/// @dev Unified function handling transfers, mints, and burns with overflow protection
	/// @param sender Source address (zero address = mint operation)
	/// @param receiver Destination address (zero address = burn operation)
	/// @param value Amount of tokens to transfer/mint/burn
	function _update(address sender, address receiver, uint256 value) internal virtual {
		assembly ("memory-safe") {
			// Shift addresses left by 96 bits for efficient packing and comparison
			sender := shl(0x60, sender)
			receiver := shl(0x60, receiver)

			// Handle sender side (mint if sender is zero address)
			switch sender
			case 0x00 {
				// Minting: increase total supply with overflow protection
				let totalSupplyBefore := sload(TOTAL_SUPPLY_SLOT)
				let totalSupplyAfter := add(totalSupplyBefore, value)

				// Check for total supply overflow
				if lt(totalSupplyAfter, totalSupplyBefore) {
					mstore(0x00, 0xe5cfe957) // TotalSupplyOverflow()
					revert(0x1c, 0x04)
				}

				sstore(TOTAL_SUPPLY_SLOT, totalSupplyAfter)
			}
			default {
				// Regular transfer: decrease sender's balance
				mstore(0x00, or(sender, BALANCES_SLOT_SEED))
				let slot := keccak256(0x00, 0x20)
				let balance_ := sload(slot)

				// Check for insufficient balance
				if lt(balance_, value) {
					mstore(0x00, 0xf4d678b8) // InsufficientBalance()
					revert(0x1c, 0x04)
				}

				sstore(slot, sub(balance_, value))
			}

			// Handle receiver side (burn if receiver is zero address)
			switch receiver
			case 0x00 {
				// Burning: decrease total supply
				sstore(TOTAL_SUPPLY_SLOT, sub(sload(TOTAL_SUPPLY_SLOT), value))
			}
			default {
				// Regular transfer: increase receiver's balance
				mstore(0x00, or(receiver, BALANCES_SLOT_SEED))
				let slot := keccak256(0x00, 0x20)
				sstore(slot, add(sload(slot), value))
			}

			// Emit {Transfer} event
			mstore(0x00, value)
			log3(0x00, 0x20, TRANSFER_EVENT_SIGNATURE, shr(0x60, sender), shr(0x60, receiver))
		}
	}

	/// @notice Sets `value` as the allowance of `spender` over the caller's tokens
	/// @dev Internal function to update allowance and emit Approval event
	/// @param spender Address to grant allowance to
	/// @param value Amount of tokens to approve
	function _approve(address spender, uint256 value) internal {
		assembly ("memory-safe") {
			// Compute allowance storage slot and store given value
			mstore(0x00, or(shl(0x60, caller()), ALLOWANCES_SLOT_SEED))
			mstore(0x20, shl(0x60, spender))
			sstore(keccak256(0x00, 0x34), value)

			// Emit {Approval} event
			mstore(0x00, value)
			log3(0x00, 0x20, APPROVAL_EVENT_SIGNATURE, caller(), spender)
		}
	}

	/// @notice Updates the allowance of `owner` for `spender` based on spent `value`
	/// @param owner Token owner address
	/// @param spender Address spending the tokens
	/// @param value Amount of tokens being spent
	function _spendAllowance(address owner, address spender, uint256 value) internal virtual {
		assembly ("memory-safe") {
			// Compute allowance storage slot and load current value
			mstore(0x00, or(shl(0x60, owner), ALLOWANCES_SLOT_SEED))
			mstore(0x20, shl(0x60, spender))

			let slot := keccak256(0x00, 0x34)
			let allowance_ := sload(slot)

			// Skip allowance check if it's maximum value (infinite approval)
			if not(allowance_) {
				// Check for sufficient allowance
				if lt(allowance_, value) {
					mstore(0x00, 0x13be252b) // InsufficientAllowance()
					revert(0x1c, 0x04)
				}

				// Decrease spender's allowance
				sstore(slot, sub(allowance_, value))
			}
		}
	}

	/// @notice Returns the hash of the token name for domain separator computation
	/// @dev Virtual function allowing inheriting contracts to optimize by caching the hash
	/// @return digest Hash of the token name string
	function _nameHash() internal view virtual returns (bytes32 digest) {
		return keccak256(bytes(name()));
	}

	/// @notice Returns the hash of the version string for domain separator computation
	/// @dev Virtual function allowing inheriting contracts to override the version
	/// @return digest Hash of the version string (default: "1")
	function _versionHash() internal view virtual returns (bytes32 digest) {
		return keccak256("1");
	}

	/// @notice Computes the EIP-712 domain separator using the full domain typehash
	/// @return separator Current domain separator for this contract instance and chain
	function _buildDomainSeparator() private view returns (bytes32 separator) {
		bytes32 nameHash = _nameHash();
		bytes32 versionHash = _versionHash();

		assembly ("memory-safe") {
			let ptr := mload(0x40)
			mstore(ptr, DOMAIN_TYPEHASH)
			mstore(add(ptr, 0x20), nameHash)
			mstore(add(ptr, 0x40), versionHash)
			mstore(add(ptr, 0x60), chainid())
			mstore(add(ptr, 0x80), address())
			separator := keccak256(ptr, 0xa0)
		}
	}

	/// @notice Validates that the given address is not the zero address
	/// @param target Address to validate
	/// @param selector Error selector to revert with if validation fails
	function _validateAddress(address target, bytes4 selector) internal pure {
		assembly ("memory-safe") {
			// Check if address is zero after shifting (efficiently removes upper bits)
			if iszero(shl(0x60, target)) {
				mstore(0x00, selector)
				revert(0x00, 0x04)
			}
		}
	}
}
