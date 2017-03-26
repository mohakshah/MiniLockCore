//
//  KeyPair.swift
//  MiniLockCore
//
//  Created by Mohak Shah on 26/03/17.
//
//

import Foundation
import libsodium
import libb2s

extension MiniLock
{
    public struct KeyPair
    {
        struct Sizes {
            static let PublicKeyCheckSum = 1
            static let PublicKey = crypto_box_publickeybytes()
            static let PrivateKey = crypto_box_secretkeybytes()
            
            static let Blake2sOutput = 32
        }
        
        struct ScryptParameters {
            static let N: UInt64 = UInt64(pow(2.0, 17.0))
            static let R: UInt32 = 8
            static let P: UInt32 = 1
            static let OutputLength = Sizes.PrivateKey
        }
        
        let privateKey, publicKey: [UInt8]
        
        // base58 encoded public key for sharing purposes
        let printablePublicKey: String
        
        /// Initializes a keypair from an existing private key
        ///
        /// - Returns: fails if privatekey length != Sizes.PrivateKey
        init?(fromPrivateKey privateKey: [UInt8]) {
            if privateKey.count != Sizes.PrivateKey {
                return nil
            }
            
            // derive the public key from the private key
            let publicKey = [UInt8](repeating: 0, count: Sizes.PublicKey + Sizes.PublicKeyCheckSum)
            crypto_scalarmult_base(UnsafeMutablePointer(mutating: publicKey), privateKey)
            
            // append the checksum to the public key
            blake2s(UnsafeMutablePointer(mutating: publicKey).advanced(by: Sizes.PublicKey),
                    publicKey,
                    nil,
                    Sizes.PublicKeyCheckSum,
                    Sizes.PublicKey,
                    0)
            
            self.publicKey = [UInt8](UnsafeBufferPointer(start: publicKey, count: Sizes.PublicKey + Sizes.PublicKeyCheckSum))
            self.privateKey = privateKey
            printablePublicKey = Base58.encode(bytes: self.publicKey)
        }
        
        /// Initializes a keypair using a user's email id and password
        ///
        /// - Returns: initialization can fail if scrypt algorithm fails
        init?(fromEmail email: String, andPassword password: String) {
            // hash the password using blake2s
            let blake2sInput = [UInt8](password.utf8)
            let blake2sOutput = [UInt8](repeating: 0, count: Sizes.Blake2sOutput)
            
            blake2s(UnsafeMutablePointer(mutating: blake2sOutput),
                    blake2sInput,
                    nil,
                    Sizes.Blake2sOutput,
                    blake2sInput.count,
                    0)
            
            // hash the result of the previous hash using scrypt with the email as the salt
            let scryptSalt: [UInt8] = Array(email.utf8)
            let scryptOutput = [UInt8](repeating: 0, count: ScryptParameters.OutputLength)
            let ret = crypto_pwhash_scryptsalsa208sha256_ll(blake2sOutput,
                                                            Sizes.Blake2sOutput,
                                                            scryptSalt,
                                                            scryptSalt.count,
                                                            ScryptParameters.N,
                                                            ScryptParameters.R,
                                                            ScryptParameters.P,
                                                            UnsafeMutablePointer(mutating: scryptOutput),
                                                            ScryptParameters.OutputLength)
            
            guard ret == 0 else {
                return nil
            }
            
            // create a [UInt8] from scrypt's output and use it to generate a keypair
            let privateKey: [UInt8] = Array(UnsafeBufferPointer(start: scryptOutput,
                                                                count: ScryptParameters.OutputLength))
            self.init(fromPrivateKey: privateKey)
        }
        
        
        /// Decodes a base58 encoded public key and verifies its checksum
        ///
        /// - Parameter b58String: base58 encoded public key
        /// - Returns: [UInt8] containing raw bits of the key on success or nil on failure.
        func decodePublicKey(fromBase58String b58String: String) -> [UInt8]? {
            guard let binary = Base58.decode(b58String),
                binary.count == (Sizes.PublicKey + Sizes.PublicKeyCheckSum) else {
                    return nil
            }
            
            let hash = [UInt8](repeating: 0, count: Sizes.PublicKeyCheckSum)
            
            blake2s(UnsafeMutablePointer(mutating: hash), binary, nil, Sizes.PublicKeyCheckSum, Sizes.PublicKey, 0)
            
            // compare the newly calculated hash with the one stored
            for i in 0..<hash.count {
                if hash[i] != binary[Sizes.PublicKey + i] {
                    return nil
                }
            }
            
            
            return binary
        }
    }
}
