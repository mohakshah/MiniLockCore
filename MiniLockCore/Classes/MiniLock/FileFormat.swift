//
//  FileFormat.swift
//  Pods
//
//  Created by Mohak Shah on 26/03/17.
//
//

import Foundation

extension MiniLock {
    struct FileFormat {
        static let PlainTextBlockMaxBytes = 1048576
        static let FileNonceBytes = 16
        static let BlockSizeTagLength = 4
    }
}
