//
//  Globals.swift
//  MiniLockCore
//
//  Created by Mohak Shah on 26/03/17.
//
//

import Foundation

class GlobalUtils
{
    /// Creates a temp file through mkstemp using 'tempFileTemplate' as a template
    ///
    /// - Returns: (fileDescriptor: Int32, filePath: [CChar])
    ///             The fileDescriptor points to a temp file open for reading and writing.
    ///             In case of error fileDescriptor will be -1
    class func getTempFileDescriptorAndPath() -> (Int32, [CChar]) {
        let mutableTemplate = tempFileTemplate
        let fd = mkstemp(UnsafeMutablePointer(mutating: mutableTemplate))
        return (fd, mutableTemplate)
    }

    /// A template for a temp file under the 'NSTemporaryDirectory'.
    ///  Suitable for passing to mktemp/mkstemp. (Entropy = 62 ^ 10)
    fileprivate static let tempFileTemplate: [Int8] = {
        let template = URL(string: "file://" + NSTemporaryDirectory())!.appendingPathComponent("XXXXXXXXXX", isDirectory: false) as NSURL
        print("Template URL:", template)
        let fsRepresentation = template.fileSystemRepresentation
        return Array(UnsafeBufferPointer(start: fsRepresentation, count: Int(strlen(fsRepresentation))))
    }()

    /// Creates a new file in 'dir' of name 'name'. If a file wih that name
    /// exists already, it tries to use a different name by appending copy 1, copy 2, copy 3, etc.
    ///
    /// - Parameters:
    ///   - dir: Directory inside which the file is to be placed
    ///   - name: Preferred name of the file
    /// - Returns: URL to the file finally created
    /// - Throws: MiniLock.Errors.CouldNotCreateFile if FileManager failes to create the file
    class func createNewFile(inDirectory dir: URL, withName name: String) throws -> URL {
        let initialPath = dir.appendingPathComponent(name)
        var fullPath = initialPath
        var copyIndex = 1
        
        while FileManager.default.fileExists(atPath: fullPath.path) {
            fullPath = initialPath.deletingLastPathComponent().appendingPathComponent(newName(for: initialPath, withIndex: copyIndex))
            copyIndex += 1
        }
        
        let createdSuccessfully = FileManager.default.createFile(atPath: fullPath.path, contents: nil, attributes: nil)
        
        if !createdSuccessfully {
            throw MiniLock.Errors.CouldNotCreateFile
        }
        
        return fullPath
    }

    class func newName(for oldFilename: URL, withIndex index: Int) -> String {
        let ext = "." + oldFilename.pathExtension
        let nameWithoutExt = oldFilename.deletingPathExtension().lastPathComponent
        
        return nameWithoutExt + " copy" + (index > 1 ? " \(index)" : "") + ext
    }
}
