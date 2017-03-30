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
    struct KeySizes {
        static let PublicKeyCheckSum = 1
        static let PublicKey = crypto_box_publickeybytes()
        static let PrivateKey = crypto_box_secretkeybytes()
    }
    
    public struct KeyPair
    {
        struct ScryptParameters {
            static let N: UInt64 = UInt64(pow(2.0, 17.0))
            static let R: UInt32 = 8
            static let P: UInt32 = 1
            static let OutputLength = KeySizes.PrivateKey
        }
        
        static let Blake2SOutputLength = 32
        
        public let privateKey: [UInt8]
        public let publicId: MiniLock.Id
        
        /// Initializes a keypair from an existing private key
        ///
        /// - Returns: fails if privatekey length != KeySizes.PrivateKey
        public init?(fromPrivateKey privateKey: [UInt8]) {
            if privateKey.count != KeySizes.PrivateKey {
                return nil
            }
            
            // derive the public key from the private key
            let publicKey = [UInt8](repeating: 0, count: KeySizes.PublicKey + KeySizes.PublicKeyCheckSum)
            crypto_scalarmult_base(UnsafeMutablePointer(mutating: publicKey), privateKey)

            self.publicId = Id(fromBinaryPublicKey: publicKey)!
            self.privateKey = privateKey
        }
        
        /// Initializes a keypair using a user's email id and password
        ///
        /// - Returns: initialization can fail if scrypt algorithm fails
        public init?(fromEmail email: String, andPassword password: String) {
            // hash the password using blake2s
            let blake2sInput = [UInt8](password.utf8)
            let blake2sOutput = [UInt8](repeating: 0, count: KeyPair.Blake2SOutputLength)
            
            blake2s(UnsafeMutablePointer(mutating: blake2sOutput),
                    blake2sInput,
                    nil,
                    blake2sOutput.count,
                    blake2sInput.count,
                    0)
            
            // hash the result of the previous hash using scrypt with the email as the salt
            let scryptSalt: [UInt8] = Array(email.utf8)
            let scryptOutput = [UInt8](repeating: 0, count: ScryptParameters.OutputLength)
            let ret = crypto_pwhash_scryptsalsa208sha256_ll(blake2sOutput,
                                                            KeyPair.Blake2SOutputLength,
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
    }
    
}
