// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {IERC20} from "src/interfaces/tokenization/IERC20.sol";
import {IERC20Metadata} from "src/interfaces/tokenization/IERC20Metadata.sol";
import {IERC20Permit} from "src/interfaces/tokenization/IERC20Permit.sol";

/// @title ERC20
/// @notice ERC20 implementation with EIP-2612 support and optimized gas usage via Yul
/// @dev Inspired by https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/ERC20.sol
/// @dev Inspired by https://github.com/Vectorized/solady/blob/main/src/tokens/ERC20.sol
/// @author fomoweth
abstract contract ERC20 is IERC20Metadata, IERC20Permit {
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

	/// @inheritdoc IERC20Metadata
	/// @dev Must be implemented by inheriting contracts
	function name() public view virtual returns (string memory);

	/// @inheritdoc IERC20Metadata
	/// @dev Must be implemented by inheriting contracts
	function symbol() public view virtual returns (string memory);

	/// @inheritdoc IERC20Metadata
	/// @dev Default implementation returns 18, can be overridden
	function decimals() public view virtual returns (uint8) {
		return 18;
	}

	/// @inheritdoc IERC20Permit
	function DOMAIN_SEPARATOR() public view virtual returns (bytes32 separator) {
		return _computeDomainSeparator();
	}

	/// @inheritdoc IERC20
	function totalSupply() public view virtual returns (uint256 totalSupply_) {
		assembly ("memory-safe") {
			totalSupply_ := sload(TOTAL_SUPPLY_SLOT)
		}
	}

	/// @inheritdoc IERC20
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

	/// @inheritdoc IERC20
	function balanceOf(address account) public view virtual returns (uint256 balance_) {
		assembly ("memory-safe") {
			// Compute balance storage slot using optimized packing:
			// Pack account (shifted left 96 bits) with slot seed
			mstore(0x00, or(shl(0x60, account), BALANCES_SLOT_SEED))
			// Hash the 32-byte packed data
			balance_ := sload(keccak256(0x00, 0x20))
		}
	}

	/// @inheritdoc IERC20Permit
	function nonces(address owner) public view virtual returns (uint256 nonce) {
		assembly ("memory-safe") {
			// Compute nonce storage slot using optimized packing:
			// Pack owner (shifted left 96 bits) with slot seed
			mstore(0x00, or(shl(0x60, owner), NONCES_SLOT_SEED))
			// Hash the 32-byte packed data
			nonce := sload(keccak256(0x00, 0x20))
		}
	}

	/// @inheritdoc IERC20
	function approve(address spender, uint256 value) public virtual returns (bool) {
		_validateAddress(spender, InvalidSpender.selector);
		_approve(spender, value);
		return true;
	}

	/// @inheritdoc IERC20
	function transfer(address recipient, uint256 value) public virtual returns (bool) {
		_validateAddress(recipient, InvalidRecipient.selector);
		_update(msg.sender, recipient, value);
		return true;
	}

	/// @inheritdoc IERC20
	function transferFrom(address sender, address recipient, uint256 value) public virtual returns (bool) {
		_validateAddress(sender, InvalidSender.selector);
		_validateAddress(recipient, InvalidRecipient.selector);
		_spendAllowance(sender, msg.sender, value);
		_update(sender, recipient, value);
		return true;
	}

	/// @inheritdoc IERC20Permit
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
		bytes32 separator = _computeDomainSeparator();

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
	/// @param account Address to mint tokens to
	/// @param value Amount of tokens to mint
	function _mint(address account, uint256 value) internal {
		_validateAddress(account, InvalidRecipient.selector);
		_update(address(0), account, value);
	}

	/// @notice Burns a `value` amount of tokens from `account`, decreasing the total supply
	/// @param account Address to burn tokens from
	/// @param value Amount of tokens to burn
	function _burn(address account, uint256 value) internal {
		_validateAddress(account, InvalidSender.selector);
		_update(account, address(0), value);
	}

	/// @notice Transfers a `value` amount of tokens from `sender` to `recipient`,
	/// or alternatively mints or burns if `sender` or `recipient` is the zero address
	/// @dev Unified function handling transfers, mints, and burns with overflow protection
	/// @param sender Source address (zero address = mint operation)
	/// @param recipient Destination address (zero address = burn operation)
	/// @param value Amount of tokens to transfer/mint/burn
	function _update(address sender, address recipient, uint256 value) internal virtual {
		assembly ("memory-safe") {
			// Shift addresses left by 96 bits for efficient packing and comparison
			sender := shl(0x60, sender)
			recipient := shl(0x60, recipient)

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

			// Handle recipient side (burn if recipient is zero address)
			switch recipient
			case 0x00 {
				// Burning: decrease total supply
				sstore(TOTAL_SUPPLY_SLOT, sub(sload(TOTAL_SUPPLY_SLOT), value))
			}
			default {
				// Regular transfer: increase recipient's balance
				mstore(0x00, or(recipient, BALANCES_SLOT_SEED))
				let slot := keccak256(0x00, 0x20)
				sstore(slot, add(sload(slot), value))
			}

			// Emit {Transfer} event
			mstore(0x00, value)
			log3(0x00, 0x20, TRANSFER_EVENT_SIGNATURE, shr(0x60, sender), shr(0x60, recipient))
		}
	}

	/// @notice Sets `value` as the allowance of `spender` over the caller's tokens
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
	/// @return digest Hash of the token name string
	function _nameHash() internal view virtual returns (bytes32 digest) {
		return keccak256(bytes(name()));
	}

	/// @notice Returns the hash of the version string for domain separator computation
	/// @return digest Hash of the version string (default: "1")
	function _versionHash() internal view virtual returns (bytes32 digest) {
		return keccak256("1");
	}

	/// @notice Computes the EIP-712 domain separator using the full domain typehash
	/// @return separator Current domain separator for this contract instance and chain
	function _computeDomainSeparator() private view returns (bytes32 separator) {
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
