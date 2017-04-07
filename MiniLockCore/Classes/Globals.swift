//
//  Globals.swift
//  MiniLockCore
//
//  Created by Mohak Shah on 26/03/17.
//
//

import Foundation

extension Array {
    /// Copies all elements of "array" to self, starting from "index"
    ///
    /// - Parameters:
    ///   - array: Array of elements to copy from
    ///   - index: index of self to start copying from
    mutating func overwrite(with array: [Element], atIndex index: Int) {
        overwrite(with: ArraySlice(array), atIndex: index)
    }
    
    
    /// Copies all elements of "slice" to self, starting from "index"
    ///
    /// - Parameters:
    ///   - slice: ArraySlice of elements to copy from
    ///   - index: index of self to start copying from
    mutating func overwrite(with slice: ArraySlice<Element>, atIndex index: Int) {
        let sliceStart = slice.startIndex
        for i in 0..<slice.count {
            self[index + i] = slice[sliceStart + i]
        }
    }
}

// TODO: replace with mkstemp
func getTempFile() -> URL {
    var filePath: URL
    var exists: Bool

    repeat {
        filePath = URL(string: "file://" + NSTemporaryDirectory())!.appendingPathComponent(UUID().uuidString, isDirectory: false)
        exists = FileManager.default.fileExists(atPath: filePath.absoluteString)
    } while (exists)

    return filePath
}
