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
