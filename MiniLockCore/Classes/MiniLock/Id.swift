//
//  Id.swift
//  MiniLockCore
//
//  Created by Mohak Shah on 26/03/17.
//
//

import Foundation
import libb2s

extension MiniLock
{
    /// A structure to hold a miniLock Id
    public struct Id: CustomStringConvertible, Equatable
    {
        /// The raw bytes of the id. These will be the Ed25519 public key followed by the key's checksum
        public let binary: [UInt8]
        
        /// Returns the base58 encoded id suitable for sharing
        public let description: String
        
        /// Returns the base58 encoded id suitable for sharing
        public var base58String: String {
            return description
        }
        
        /// Returns a MiniLock.Id initialized from a binary Ed25519 public key
        ///
        /// - Parameter binary: Ed25519 public key
        /// - Returns: nil on invalid input size
        public init?(fromBinaryPublicKey binary: [UInt8]) {
            guard binary.count == KeySizes.PublicKey else {
                return nil
            }
            
            // calculate the checksum of the key
            let checkSum = [UInt8](repeating: 0, count: KeySizes.PublicKeyCheckSum)
            blake2s(UnsafeMutablePointer(mutating: checkSum),
                    binary,
                    nil,
                    checkSum.count,
                    binary.count,
                    0)
            
            self.binary = binary + checkSum
            self.description = Base58.encode(bytes: self.binary)
        }
        
        
        /// Returns a MiniLock.Id initialized from a base58 encoded string
        ///
        /// - Parameter b58String: base58 encoded id
        /// - Returns: nil on invalid input string
        public init?(fromBase58String b58String: String) {
            // decode the base58 string
            guard let binary = Base58.decode(b58String),
                binary.count == (KeySizes.PublicKey + KeySizes.PublicKeyCheckSum) else {
                    return nil
            }
            
            // calculate hash of first KeySizes.PublicKey bytes
            let hash = [UInt8](repeating: 0, count: KeySizes.PublicKeyCheckSum)
            blake2s(UnsafeMutablePointer(mutating: hash), binary, nil, KeySizes.PublicKeyCheckSum, KeySizes.PublicKey, 0)
            
            // compare the newly calculated hash with the one stored
            for i in 0..<hash.count {
                if hash[i] != binary[KeySizes.PublicKey + i] {
                    return nil
                }
            }
            
            self.binary = binary
            self.description = b58String
        }
        
        public static func ==(lhs: Id, rhs: Id) -> Bool {
            return lhs.binary == rhs.binary
        }
    }
}
