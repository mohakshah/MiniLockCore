//
//  StreamEncryptor.swift
//  MiniLockCore
//
//  Created by Mohak Shah on 23/03/17.
//  Copyright © 2017 Mohak Shah. All rights reserved.
//

import Foundation
import libsodium
import libb2s

extension MiniLock
{
    public class StreamEncryptor: StreamCryptoBase
    {
        /// Initialize with a random encryption key and nonce
        convenience init() {
            // create a random fileKey
            let fileKey = [UInt8](repeating: 0, count: CryptoBoxSizes.SecretKey)
            randombytes_buf(UnsafeMutableRawPointer(mutating: fileKey), CryptoBoxSizes.SecretKey)

            // no need to throw since use has not provided any input
            try! self.init(key: fileKey)
        }

        /// Initialize with key and a random nonce
        ///
        /// - Parameter key: encryptionkey to use
        /// - Throws: throws if size of key is invalid
        convenience init(key: [UInt8]) throws {
            // create a random file nonce
            let fileNonce = [UInt8](repeating: 0, count: MiniLock.FileFormat.FileNonceBytes)
            randombytes_buf(UnsafeMutableRawPointer(mutating: fileNonce), fileNonce.count)

            // throw in case "key" is improper
            try self.init(key: key, fileNonce: fileNonce)
        }


        /// Encrypts block with the key and nonce that the object was initalized with.
        /// The cipher text is preceded by block length tag and followed by the MAC
        ///
        /// - Parameters:
        ///   - block: [UInt8] to encrypt. Size should lie between (0, MiniLock.FileFormat.PlainTextBlockMaxBytes]
        ///   - isLastBlock: set to true if this is the last block
        /// - Returns: (cipher text + mac) is returned in form of [UInt8]
        /// - Throws: MiniLockStreamCryptor.CryptoError
        func encrypt(block: [UInt8], isLastBlock: Bool) throws -> [UInt8] {
            if processStatus != .incomplete  {
                throw CryptoError.processComplete
            }

            guard block.count > 0,
                block.count <= MiniLock.FileFormat.PlainTextBlockMaxBytes else {
                    throw CryptoError.inputSizeInvalid
            }

            if isLastBlock {
                // set MSB of the block counter
                fullNonce[fullNonce.count - 1] |= 0x80

                _processStatus = .succeeded
            }

            // write block to message buffer
            messageBuffer.overwrite(with: block, atIndex: CryptoBoxSizes.MessagePadding)

            // encrypt the message and extract the cipherText from cipherBuffer
            crypto_secretbox(UnsafeMutablePointer(mutating: cipherBuffer).advanced(by: MiniLock.FileFormat.BlockSizeTagLength),
                             messageBuffer,
                             UInt64(block.count),
                             fullNonce,
                             key)
            var cipherText = Array(cipherBuffer[CryptoBoxSizes.CipherTextPadding..<(CryptoBoxSizes.CipherTextPadding
                                                                                    + MiniLock.FileFormat.BlockSizeTagLength
                                                                                    + block.count
                                                                                    + CryptoBoxSizes.MAC )])

            incrementNonce()

            // set the block length tag
            for i in 0..<MiniLock.FileFormat.BlockSizeTagLength {
                cipherText[i] = UInt8((block.count >> (8 * i)) & 0xff)
            }

            // update blake2s
            _ = withUnsafeMutablePointer(to: &blake2SState) { (statePointer) in
                blake2s_update(statePointer, cipherText, cipherText.count)
            }

            if isLastBlock {
                // finalize and extract the hash
                _ = withUnsafeMutablePointer(to: &blake2SState) { (statePointer) in
                    blake2s_final(statePointer,
                                  UnsafeMutablePointer(mutating: _cipherTextHash),
                                  StreamCryptoBase.Blake2sOutputLength)
                }
            }

            return cipherText
        }
    }
}
