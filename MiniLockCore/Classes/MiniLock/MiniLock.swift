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
        case RecepientListEmpty
        case NotAFileURL
        case FileNameEmpty
        case CouldNotCreateFile
        case SourceFileEmpty
        case CouldNotConstructHeader
    }

    public class func isEncryptedFile(url: URL) throws -> Bool {
        guard url.isFileURL else {
            throw Errors.NotAFileURL
        }
        
        let readHandle = try FileHandle(forReadingFrom: url)
        
        let fileBytes = [UInt8](readHandle.readData(ofLength: FileFormat.MagicBytes.count))
        
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
