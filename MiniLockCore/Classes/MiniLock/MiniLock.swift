//
//  MiniLock.swift
//  MiniLockCore
//
//  Created by Mohak Shah on 19/03/17.
//  Copyright © 2017 Mohak Shah. All rights reserved.
//

import Foundation
import libsodium
import libb2s

public class MiniLock
{
    public enum Errors: Error {
        case recepientListEmpty
        case notAFileURL
        case fileNameEmpty
        case couldNotCreateFile
        case sourceFileEmpty
        case couldNotConstructHeader
        case notAMiniLockFile
        case corruptMiniLockFile
        case notARecipient
        case couldNotDecodeFileName
        case headerParsingError
        case processAlreadyComplete
    }
    
    public enum ProcessStatus {
        case incomplete, succeeded, failed
    }

    public class func isEncryptedFile(url: URL) throws -> Bool {
        guard url.isFileURL else {
            throw Errors.notAFileURL
        }
        
        // read magic bytes from the file
        let readHandle = try FileHandle(forReadingFrom: url)
        let fileBytes = [UInt8](readHandle.readData(ofLength: FileFormat.MagicBytes.count))

        readHandle.closeFile()
        
        // compare to minilock's magic bytes
        if fileBytes == FileFormat.MagicBytes {
            return true
        }
        
        return false
    }
}

public protocol MiniLockProcessDelegate: class {
    
    /// Implement this function to get updates on a MiniLock process
    /// such as file encryption/decryption
    ///
    /// - Parameters:
    ///   - progress: values in the range [0.0, 1.0]
    ///   - process: the process calling the funcion
    func setProgress(to progress: Double, process: MiniLockProcess)
}

public protocol MiniLockProcess {
    var processDelegate: MiniLockProcessDelegate? { get set }
}
