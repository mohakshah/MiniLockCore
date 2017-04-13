
//
//  FileEncryptor.swift
//  MiniLockCore
//
//  Created by Mohak Shah on 30/03/17.
//
//

import Foundation
import libsodium

extension MiniLock {
    public class FileEncryptor: MiniLockProcess {

        let fileURL: URL
        let sender: MiniLock.KeyPair
        let recipients: [MiniLock.Id]
        
        let paddedFileName: Data
        let fileSize: Double
        
        var bytesEncrypted: Int = 0 {
            didSet {
                processDelegate?.setProgress(to: Double(bytesEncrypted) / fileSize, process: self)
            }
        }

        public weak var processDelegate: MiniLockProcessDelegate?

        public init(fileURL url: URL, sender: MiniLock.KeyPair, recipients: [MiniLock.Id]) throws {
            guard url.isFileURL else {
                throw Errors.NotAFileURL
            }
            
            guard !url.lastPathComponent.isEmpty else {
                throw Errors.FileNameEmpty
            }

            self.fileURL = url
            self.sender = sender

            if recipients.isEmpty {
                throw Errors.RecepientListEmpty
            }

            self.recipients = recipients
            
            self.paddedFileName = FileEncryptor.paddedFileName(fromFileURL: url)
            
            self.fileSize = Double((try FileManager.default.attributesOfItem(atPath: self.fileURL.path))[FileAttributeKey.size] as! UInt64)
        }
        
        public func encrypt(destinationFileURL destination: URL, deleteSourceFile: Bool) throws {
            guard destination.isFileURL else {
                throw Errors.NotAFileURL
            }
            
            var encryptedSuccessfully = false
            let fileManager = FileManager.default

            // open destination file for writing
            var createdSuccessfully = fileManager.createFile(atPath: destination.path, contents: nil, attributes: nil)
            if !createdSuccessfully {
                throw Errors.CouldNotCreateFile
            }
            
            let destinationHandle = try FileHandle(forWritingTo: destination)
            defer {
                destinationHandle.closeFile()
                if !encryptedSuccessfully {
                    do {
                        try fileManager.removeItem(at: destination)
                    } catch (let error) {
                        print("Error deleting the destination: ", error)
                    }
                }
            }

            // open the source file for reading
            let sourceHandle = try FileHandle(forReadingFrom: fileURL)
            defer {
                sourceHandle.closeFile()
                if deleteSourceFile && fileManager.fileExists(atPath: fileURL.absoluteString) {
                    do {
                        try fileManager.removeItem(at: fileURL)
                    } catch (let error) {
                        print("Error deleting the source file: ", error)
                    }
                }
            }

            // create a temp file for encrypted payload
            let encryptedPayloadURL = getTempFile()
            
            createdSuccessfully = fileManager.createFile(atPath: encryptedPayloadURL.path, contents: nil, attributes: nil)
            if !createdSuccessfully {
                throw Errors.CouldNotCreateFile
            }

            // open that temp file for writing
            var payloadHandle: FileHandle
            do {
                payloadHandle = try FileHandle(forWritingTo: encryptedPayloadURL)
            } catch (let error) {
                // delete temp file
                do {
                    try fileManager.removeItem(at: encryptedPayloadURL)
                } catch (let error) {
                    print("Error deleting the temp payload file: ", error)
                }
                
                throw error
            }

            defer {
                // close and delete payload file
                payloadHandle.closeFile()
                do {
                    try FileManager.default.removeItem(at: encryptedPayloadURL)
                } catch (let error) {
                    print("Error deleting the temp payload file: ", error)
                }
            }
            
            // write symmetrically encrypted payload to payloadHandle
            let encryptor = StreamEncryptor()
            let encryptedBlock = try encryptor.encrypt(messageBlock: paddedFileName, isLastBlock: false)

            payloadHandle.write(encryptedBlock)

            var currentBlock = sourceHandle.readData(ofLength: MiniLock.FileFormat.PlainTextBlockMaxBytes)
            if currentBlock.isEmpty {
                throw Errors.SourceFileEmpty
            }
            
            while !currentBlock.isEmpty {
                try autoreleasepool {
                    let nextBlock = sourceHandle.readData(ofLength: MiniLock.FileFormat.PlainTextBlockMaxBytes)
                    let encryptedBlock = try encryptor.encrypt(messageBlock: currentBlock, isLastBlock: nextBlock.isEmpty)

                    payloadHandle.write(encryptedBlock)
                    
                    bytesEncrypted += currentBlock.count
                    
                    currentBlock = nextBlock
                }
            }
            
            sourceHandle.closeFile()
            
            // delete source file
            if deleteSourceFile {
                do {
                    try fileManager.removeItem(at: fileURL)
                } catch (let error) {
                    print("Error deleting the source file: ", error)
                }
            }

            // re-open payload file for reading
            payloadHandle.closeFile()
            payloadHandle = try FileHandle(forReadingFrom: encryptedPayloadURL)
            
            // write magic bytes to destination
            destinationHandle.write(Data(MiniLock.FileFormat.MagicBytes))
            
            // create header
            let header = Header(sender: sender,
                                recipients: recipients,
                                fileInfo: Header.FileInfo(key: encryptor.key, nonce: encryptor.fileNonce, hash: encryptor.cipherTextHash))
            
            guard let headerData = header?.toJSONStringWithoutEscapes()?.data(using: .utf8) else {
                throw Errors.CouldNotConstructHeader
            }

            // write header length to destination
            let headerSize = headerData.count
            
            var headerSizeBytes = Data()
            for i in 0..<FileFormat.HeaderBytesLength {
                let byte = UInt8((headerSize >> (8 * i)) & 0xff)
                headerSizeBytes.append(byte)
            }
            
            destinationHandle.write(headerSizeBytes)

            // write the header to destination
            destinationHandle.write(headerData)
            
            // copy over the payloadHandle to destination
            currentBlock = payloadHandle.readData(ofLength: MiniLock.FileFormat.PlainTextBlockMaxBytes)
            
            while !currentBlock.isEmpty {
                autoreleasepool {
                    destinationHandle.write(currentBlock)
                    currentBlock = payloadHandle.readData(ofLength: MiniLock.FileFormat.PlainTextBlockMaxBytes)
                }
            }
            
            encryptedSuccessfully = true
        }
        
        class func paddedFileName(fromFileURL url: URL) -> Data {
            var filename = [UInt8](url.lastPathComponent.utf8)
            
            if filename.count > FileFormat.FileNameMaxLength {
                // keep just the first FileFormat.FileNameMaxLength bytes
                filename.removeLast(filename.count - FileFormat.FileNameMaxLength)
            }

            // pad to fit FileFormat.FileNameMaxLength bytes
            filename += [UInt8](repeating: 0, count: FileFormat.FileNameMaxLength - filename.count + 1)
            
            return Data(filename)
        }
    }
}
