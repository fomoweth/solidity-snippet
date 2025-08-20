// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

/// @title Random
/// @dev Modified from https://github.com/Vectorized/solady/blob/main/test/utils/TestPlus.sol
abstract contract Random {
	/// @dev `address(bytes20(uint160(uint256(keccak256("hevm cheat code")))))`
	address private constant VM_ADDRESS = 0x7109709ECfa91a80626fF3989D68f67F5b1DD12D;

	/// @dev This is the keccak256 of a very long string I randomly mashed on my keyboard
	uint256 private constant RANDOMNESS_SLOT = 0xd715531fe383f818c5f158c342925dcf01b954d24678ada4d07c36af0f20e1ee;

	/// @dev The maximum private key
	uint256 private constant PRIVATE_KEY_MAX = 0xfffffffffffffffffffffffffffffffebaaedce6af48a03bbfd25e8cd0364140;

	/// @dev Some constant to brutalize the upper bits of addresses
	uint256 private constant ADDRESS_BRUTALIZER = 0xc0618c2bfd481dcf3e31738f;

	/// @dev Multiplier for a mulmod Lehmer pseudorandom number generator.
	/// Prime, and a primitive root of `_LPRNG_MODULO`.
	uint256 private constant LPRNG_MULTIPLIER = 0x100000000000000000000000000000051;

	/// @dev Modulo for a mulmod Lehmer pseudorandom number generator. (prime)
	uint256 private constant LPRNG_MODULO = 0xffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff43;

	/// @dev Returns a pseudorandom random number from [0 .. 2**256 - 1] (inclusive)
	/// For usage in fuzz tests, please ensure that the function has an unnamed uint256 argument
	/// e.g. `testSomething(uint256) public`
	/// This function may return a previously returned result
	function random() internal returns (uint256 result) {
		assembly ("memory-safe") {
			result := RANDOMNESS_SLOT
			let value := sload(result)
			mstore(0x20, value)
			let r := keccak256(0x20, 0x40)
			// If the storage is uninitialized, initialize it to the keccak256 of the calldata
			if iszero(value) {
				value := result
				calldatacopy(mload(0x40), 0x00, calldatasize())
				r := keccak256(mload(0x40), calldatasize())
			}
			sstore(result, add(r, 0x01))

			// Do some biased sampling for more robust tests
			// prettier-ignore
			for {} 0x01 {} {
                let y := mulmod(r, LPRNG_MULTIPLIER, LPRNG_MODULO)
                // With a 1/256 chance, randomly set `r` to any of 0,1,2,3
                if iszero(byte(0x13, y)) {
                    r := and(byte(0x0b, y), 0x03)
                    break
                }
                let d := byte(0x11, y)
                // With a 1/2 chance, set `r` to near a random power of 2
                if iszero(and(0x02, d)) {
                    // Set `t` either `not(0x00)` or `xor(value, r)`
                    let t := or(xor(value, r), sub(0x00, and(0x01, d)))
                    // Set `r` to `t` shifted left or right
                    // prettier-ignore
                    for {} 0x01 {} {
                        if iszero(and(0x08, d)) {
                            if iszero(and(0x10, d)) { t := 0x01 }
                            if iszero(and(0x20, d)) {
                                r := add(shl(shl(0x03, and(byte(0x07, y), 0x1f)), t), sub(0x03, and(0x07, r)))
                                break
                            }
                            r := add(shl(byte(0x07, y), t), sub(0x1ff, and(0x3ff, r)))
                            break
                        }
                        if iszero(and(0x10, d)) { t := shl(0xff, 0x01) }
                        if iszero(and(0x20, d)) {
                            r := add(shr(shl(0x03, and(byte(0x07, y), 0x1f)), t), sub(0x03, and(0x07, r)))
                            break
                        }
                        r := add(shr(byte(0x07, y), t), sub(0x1ff, and(0x3ff, r)))
                        break
                    }
                    // With a 1/2 chance, negate `r`
                    r := xor(sub(0x00, shr(0x07, d)), r)
                    break
                }
                // Otherwise, just set `r` to `xor(value, r)`
                r := xor(value, r)
                break
            }
			result := r
		}
	}

	/// @dev Returns a pseudorandom random number from [0 .. 2**256 - 1] (inclusive)
	/// For usage in fuzz tests, please ensure that the function has an unnamed uint256 argument
	/// e.g. `testSomething(uint256) public`
	function randomUnique(uint256 groupId) internal returns (uint256 result) {
		result = randomUnique(bytes32(groupId));
	}

	/// @dev Returns a pseudorandom random number from [0 .. 2**256 - 1] (inclusive)
	/// For usage in fuzz tests, please ensure that the function has an unnamed uint256 argument
	/// e.g. `testSomething(uint256) public`
	function randomUnique(bytes32 groupId) internal returns (uint256 result) {
		do {
			result = random();
		} while (_markAsGenerated("uint256", groupId, result));
	}

	/// @dev Returns a pseudorandom random number from [0 .. 2**256 - 1] (inclusive)
	/// For usage in fuzz tests, please ensure that the function has an unnamed uint256 argument
	/// e.g. `testSomething(uint256) public`.
	function randomUnique() internal returns (uint256 result) {
		result = randomUnique("");
	}

	/// @dev Returns a pseudorandom number, uniformly distributed in [0 .. 2**256 - 1] (inclusive)
	function randomUniform() internal returns (uint256 result) {
		assembly ("memory-safe") {
			result := RANDOMNESS_SLOT
			// prettier-ignore
			for { let value := sload(result) } 0x01 {} {
                // If the storage is uninitialized, initialize it to the keccak256 of the calldata
                if iszero(value) {
                    calldatacopy(mload(0x40), 0x00, calldatasize())
                    value := keccak256(mload(0x40), calldatasize())
                    sstore(result, value)
                    result := value
                    break
                }
                mstore(0x1f, value)
                value := keccak256(0x20, 0x40)
                sstore(result, value)
                result := value
                break
            }
		}
	}

	/// @dev Returns a boolean with an approximately 1/n chance of being true
	/// This function may return a previously returned result
	function randomChance(uint256 n) internal returns (bool result) {
		uint256 r = randomUniform();
		assembly ("memory-safe") {
			result := iszero(mod(r, n))
		}
	}

	/// @dev Returns a random private key that can be used for ECDSA signing
	/// This function may return a previously returned result
	function randomPrivateKey() internal returns (uint256 result) {
		result = randomUniform();
		assembly ("memory-safe") {
			// prettier-ignore
			for {} 0x01 {} {
				if iszero(and(result, 0x10)) {
					if iszero(and(result, 0x20)) {
						result := add(and(result, 0xf), 0x01)
						break
					}
					result := sub(PRIVATE_KEY_MAX, and(result, 0xf))
					break
				}
				result := shr(0x01, result)
				break
			}
		}
	}

	/// @dev Returns a random private key that can be used for ECDSA signing
	function randomUniquePrivateKey(uint256 groupId) internal returns (uint256 result) {
		result = randomUniquePrivateKey(bytes32(groupId));
	}

	/// @dev Returns a random private key that can be used for ECDSA signing
	function randomUniquePrivateKey(bytes32 groupId) internal returns (uint256 result) {
		do {
			result = randomPrivateKey();
		} while (_markAsGenerated("uint256", groupId, result));
	}

	/// @dev Returns a random private key that can be used for ECDSA signing
	function randomUniquePrivateKey() internal returns (uint256 result) {
		result = randomUniquePrivateKey("");
	}

	/// @dev Returns a pseudorandom signer and its private key
	/// This function may return a previously returned result
	/// The signer may have dirty upper 96 bits
	function randomSigner() internal returns (address signer, uint256 privateKey) {
		privateKey = randomPrivateKey();
		signer = _toBrutalizedAddress(_getSigner(privateKey));
	}

	/// @dev Returns a pseudorandom signer and its private key
	/// The signer may have dirty upper 96 bits
	function randomUniqueSigner(uint256 groupId) internal returns (address signer, uint256 privateKey) {
		(signer, privateKey) = randomUniqueSigner(bytes32(groupId));
	}

	/// @dev Returns a pseudorandom signer and its private key
	/// The signer may have dirty upper 96 bits
	function randomUniqueSigner(bytes32 groupId) internal returns (address signer, uint256 privateKey) {
		privateKey = randomUniquePrivateKey(groupId);
		signer = _toBrutalizedAddress(_getSigner(privateKey));
	}

	/// @dev Returns a pseudorandom signer and its private key
	/// The signer may have dirty upper 96 bits
	function randomUniqueSigner() internal returns (address signer, uint256 privateKey) {
		(signer, privateKey) = randomUniqueSigner("");
	}

	/// @dev Returns a pseudorandom address
	/// The result may have dirty upper 96 bits
	/// This function will not return an existing contract
	/// This function may return a previously returned result
	function randomAddress() internal returns (address result) {
		uint256 r = randomUniform();
		assembly ("memory-safe") {
			result := xor(shl(0x9e, r), and(sub(0x07, shr(0xfc, r)), r))
		}
	}

	/// @dev Returns a pseudorandom address
	/// The result may have dirty upper 96 bits
	/// This function will not return an existing contract
	function randomUniqueAddress(uint256 groupId) internal returns (address result) {
		result = randomUniqueAddress(bytes32(groupId));
	}

	/// @dev Returns a pseudorandom address
	/// The result may have dirty upper 96 bits
	/// This function will not return an existing contract
	function randomUniqueAddress(bytes32 groupId) internal returns (address result) {
		do {
			result = randomAddress();
		} while (_markAsGenerated("address", groupId, uint160(result)));
	}

	/// @dev Returns a pseudorandom address
	/// The result may have dirty upper 96 bits
	/// This function will not return an existing contract
	function randomUniqueAddress() internal returns (address result) {
		result = randomUniqueAddress("");
	}

	/// @dev Returns a pseudorandom non-zero address
	/// The result may have dirty upper 96 bits
	/// This function will not return an existing contract
	/// This function may return a previously returned result
	function randomNonZeroAddress() internal returns (address result) {
		uint256 r = randomUniform();
		assembly ("memory-safe") {
			result := xor(shl(0x9e, r), and(sub(0x07, shr(0xfc, r)), r))
			if iszero(shl(0x60, result)) {
				mstore(0x00, result)
				result := keccak256(0x00, 0x30)
			}
		}
	}

	/// @dev Returns a pseudorandom non-zero address
	/// The result may have dirty upper 96 bits
	/// This function will not return an existing contract
	function randomUniqueNonZeroAddress(uint256 groupId) internal returns (address result) {
		result = randomUniqueNonZeroAddress(bytes32(groupId));
	}

	/// @dev Returns a pseudorandom non-zero address
	/// The result may have dirty upper 96 bits
	/// This function will not return an existing contract
	function randomUniqueNonZeroAddress(bytes32 groupId) internal returns (address result) {
		do {
			result = randomNonZeroAddress();
		} while (_markAsGenerated("address", groupId, uint160(result)));
	}

	/// @dev Returns a pseudorandom non-zero address
	/// The result may have dirty upper 96 bits
	/// This function will not return an existing contract
	function randomUniqueNonZeroAddress() internal returns (address result) {
		result = randomUniqueNonZeroAddress("");
	}

	/// @dev Cleans the upper 96 bits of the address
	function clean(address a) internal pure returns (address result) {
		assembly ("memory-safe") {
			result := shr(0x60, shl(0x60, a))
		}
	}

	/// @dev Returns a pseudorandom address
	/// The result may have dirty upper 96 bits
	/// This function may return a previously returned result
	function randomAddressWithVmVars() internal returns (address result) {
		if (randomChance(8)) result = _toBrutalizedAddress(randomVmVar());
		else result = randomAddress();
	}

	/// @dev Returns a pseudorandom non-zero address.
	/// The result may have dirty upper 96 bit
	/// This function may return a previously returned result
	function randomNonZeroAddressWithVmVars() internal returns (address result) {
		do {
			if (randomChance(8)) result = _toBrutalizedAddress(randomVmVar());
			else result = randomAddress();
		} while (result == address(0));
	}

	/// @dev Returns a random variable in the virtual machine
	function randomVmVar() internal returns (uint256 result) {
		uint256 r = randomUniform();
		uint256 t = r % 11;
		if (t <= 4) {
			if (t == 0) return uint160(address(this));
			if (t == 1) return uint160(tx.origin);
			if (t == 2) return uint160(msg.sender);
			if (t == 3) return uint160(VM_ADDRESS);
			if (t == 4) return uint160(0x000000000000000000636F6e736F6c652e6c6f67);
		}
		uint256 y = r >> 32;
		if (t == 5) {
			assembly ("memory-safe") {
				mstore(0x00, r)
				codecopy(0x00, mod(and(y, 0xffff), add(codesize(), 0x20)), 0x20)
				result := mload(0x00)
			}
			return result;
		}
		if (t == 6) {
			assembly ("memory-safe") {
				calldatacopy(0x00, mod(and(y, 0xffff), add(calldatasize(), 0x20)), 0x20)
				result := mload(0x00)
			}
			return result;
		}
		if (t == 7) {
			assembly ("memory-safe") {
				let m := mload(0x40)
				returndatacopy(m, 0x00, returndatasize())
				result := mload(add(m, mod(and(y, 0xffff), add(returndatasize(), 0x20))))
			}
			return result;
		}
		if (t == 8) {
			assembly ("memory-safe") {
				result := sload(and(y, 0xff))
			}
			return result;
		}
		if (t == 9) {
			assembly ("memory-safe") {
				result := mload(mod(y, add(mload(0x40), 0x40)))
			}
			return result;
		}
		result = _getSigner(randomPrivateKey());
	}

	/// @dev Returns a pseudorandom hashed address
	/// The result may have dirty upper 96 bits
	/// This function will not return an existing contract
	/// This function will not return a precompile address
	/// This function will not return a zero address
	/// This function may return a previously returned result
	function randomHashedAddress() internal returns (address result) {
		uint256 r = randomUniform();
		assembly ("memory-safe") {
			mstore(0x1f, and(sub(0x07, shr(0xfc, r)), r))
			calldatacopy(0x00, 0x00, 0x24)
			result := keccak256(0x00, 0x3f)
		}
	}

	/// @dev Returns a pseudorandom address
	function randomUniqueHashedAddress(uint256 groupId) internal returns (address result) {
		result = randomUniqueHashedAddress(bytes32(groupId));
	}

	/// @dev Returns a pseudorandom address
	function randomUniqueHashedAddress(bytes32 groupId) internal returns (address result) {
		do {
			result = randomHashedAddress();
		} while (_markAsGenerated("address", groupId, uint160(result)));
	}

	/// @dev Returns a pseudorandom address
	function randomUniqueHashedAddress() internal returns (address result) {
		result = randomUniqueHashedAddress("");
	}

	/// @dev Returns a random bytes string from 0 to 131071 bytes long
	/// This random bytes string may NOT be zero-right-padded
	/// This is intentional for memory robustness testing
	/// This function may return a previously returned result
	function randomBytes() internal returns (bytes memory result) {
		result = randomBytes(false);
	}

	/// @dev Returns a random bytes string from 0 to 131071 bytes long
	/// This function may return a previously returned result
	function randomBytesZeroRightPadded() internal returns (bytes memory result) {
		result = randomBytes(true);
	}

	/// @dev Private helper function for returning random bytes
	function randomBytes(bool zeroRightPad) internal returns (bytes memory result) {
		uint256 r = randomUniform();
		assembly ("memory-safe") {
			let n := and(r, 0x1ffff)
			let t := shr(0x18, r)
			// prettier-ignore
			for {} 0x01 {} {
				// With a 1/256 chance, just return the zero pointer as the result
				if iszero(and(t, 0xff0)) {
					result := 0x60
					break
				}
				result := mload(0x40)
				// With a 15/16 chance, set the length to be exponentially distributed in the range [0,255] (inclusive)
				if shr(0xfc, r) {
					n := shr(and(t, 0x7), byte(0x05, r))
				}
				// Store some fixed word at the start of the string
				// We want this function to sometimes return duplicates
				mstore(add(result, 0x20), xor(calldataload(0x00), RANDOMNESS_SLOT))
				// With a 1/2 chance, copy the contract code to the start and end
				if iszero(and(t, 0x1000)) {
					// Copy to the start
					if iszero(and(t, 0x2000)) {
						codecopy(result, byte(0x01, r), codesize())
					}
					// Copy to the end
					codecopy(add(result, n), byte(0x02, r), 0x40)
				}
				// With a 1/16 chance, randomize the start and end
				if iszero(and(t, 0xf0000)) {
					let y := mulmod(r, LPRNG_MULTIPLIER, LPRNG_MODULO)
					mstore(add(result, 0x20), y)
					mstore(add(result, n), xor(r, y))
				}
				// With a 1/256 chance, make the result entirely zero bytes
				if iszero(byte(0x04, r)) {
					codecopy(result, codesize(), add(n, 0x20))
				}
				// Skip the zero-right-padding if not required
				if iszero(zeroRightPad) {
					mstore(0x40, add(n, add(0x40, result))) // Allocate memory
					mstore(result, n) // Store the length
					break
				}
				mstore(add(add(result, 0x20), n), 0x00) // Zeroize the word after the result
				mstore(0x40, add(n, add(0x60, result))) // Allocate memory
				mstore(result, n) // Store the length
				break
			}
		}
	}

	/// @dev Private helper function to get the signer from a private key
	function _getSigner(uint256 privateKey) private view returns (uint256 result) {
		assembly ("memory-safe") {
			mstore(0x00, 0xffa18649) // addr(uint256)
			mstore(0x20, privateKey)
			result := mload(staticcall(gas(), VM_ADDRESS, 0x1c, 0x24, 0x01, 0x20))
		}
	}

	/// @dev Private helper to ensure an address is brutalized
	function _toBrutalizedAddress(address a) private pure returns (address result) {
		assembly ("memory-safe") {
			result := keccak256(0x00, 0x88)
			result := xor(shl(0xa0, xor(result, ADDRESS_BRUTALIZER)), a)
			mstore(0x10, result)
		}
	}

	/// @dev Private helper to ensure an address is brutalized
	function _toBrutalizedAddress(uint256 a) private pure returns (address result) {
		assembly ("memory-safe") {
			result := keccak256(0x00, 0x88)
			result := xor(shl(0xa0, xor(result, ADDRESS_BRUTALIZER)), a)
			mstore(0x10, result)
		}
	}

	/// @dev Returns whether the `value` has been generated for `typeId` and `groupId` before
	function _markAsGenerated(bytes32 typeId, bytes32 groupId, uint256 value) private returns (bool result) {
		assembly ("memory-safe") {
			let ptr := mload(0x40) // Cache the free memory pointer
			mstore(0x00, value)
			mstore(0x20, groupId)
			mstore(0x40, typeId)
			mstore(0x60, RANDOMNESS_SLOT)
			let slot := keccak256(0x00, 0x80)
			result := sload(slot)
			sstore(slot, 0x01)
			mstore(0x40, ptr) // Restore the free memory pointer
			mstore(0x60, 0x00) // Restore the zero pointer
		}
	}
}
