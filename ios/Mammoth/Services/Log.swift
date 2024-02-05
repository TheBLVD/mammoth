//
//  File.swift
//  Mammoth
//
//  Created by Riley Howard on 2/12/23.
//  Copyright © 2023 The BLVD. All rights reserved.
//

import Foundation

let log = Log()

class Log {
    
    // Example usage:
    //
    //      log.debug("M_NETWORK", "Request sent to \(url)")
    //      log.debug("Starting up")
    //
    //      log.warning("Somewhat unexpected")
    //
    //      log.error("Unexpected isssue")
    //
    // To enable the argument-based use:
    //      In Product > Scheme > Edit Scheme > Arguments Passed on Launch, add "-M_NETWORK"
    //
    //
    // For the command line arguments, it's suggested to use a M_ prefix to avoid clashing
    // with other launch arguments.
    
    var writeToFile = true
    var fileHandle: FileHandle? = nil
    let dateFormater = DateFormatter()

    
    init() {
        self.dateFormater.dateFormat = "dd-MMM-yyyy HH:mm:ss.SSS"
    }
    
    
    public func writeToFile(_ write: Bool) {
        writeToFile = write
    }
    
    
    public func debug(_ argument: String, _ message: String) {
        if CommandLine.arguments.contains("-"+argument) {
            self.debug(message)
        }
    }
    
    
    public func debug(_ message: String) {
        log(message)
    }
    
    
    public func warning(_ message: String) {
        log("⚠️ " + message)
    }
    
    
    public func error(_ message: String) {
        log("⛔️ " + message)
    }
    
    
    private func log(_ message: String) {
        print(message)
        if writeToFile {
            // Create the file if necessary
            // Append env details
            if fileHandle == nil {
                let filePath = Log.filePathURL?.path
                if filePath != nil && FileManager.default.createFile(atPath: filePath!, contents: nil, attributes: nil) {
                    do {
                        fileHandle = try FileHandle(forUpdating: Log.filePathURL!)
#if !NOTIFICATION_EXTENSION
                        if let messageAsData = ("Device: \(Bundle.main.deviceType)\n" + "iOS: \(Bundle.main.systemVersion)\n" + "Version: \(Bundle.main.appVersion)(\(Bundle.main.appBuild))" + "\n\n").data(using: String.Encoding.utf8) {
                            fileHandle!.write(messageAsData)
                        }
#endif
                    } catch {
                        print("file error:\(error)")
                    }
                }
            }
            // Append message to the existing file
            if fileHandle != nil {
                fileHandle!.seekToEndOfFile()
                if let messageAsData = (dateFormater.string(from: Date()) + " " + message + "\n").data(using: String.Encoding.utf8) {
                    fileHandle!.write(messageAsData)
                }
            }
        }
    }
    
    static let filePathURL: URL? = getFilePathURL()
    static private func getFilePathURL() -> URL? {
        #if NOTIFICATION_EXTENSION
            return pushLogFilePathURL()
        #else
            return appLogFilePathURL()
        #endif
    }
    
    static private func appLogFilePathURL() -> URL? {
        // For the app, use the /tmp/ directory
        return FileManager.default.temporaryDirectory.appendingPathComponent("Mammoth Log.txt")
    }
    
    static func pushLogFilePathURL() -> URL? {
        // For the notification extension, use a shared file location
        let sharedGroupContainerDirectory = FileManager().containerURL(
            forSecurityApplicationGroupIdentifier: "group.com.theblvd.mammoth.wormhole")
        if let fileURL = sharedGroupContainerDirectory?.appendingPathComponent("Mammoth Push Log.txt") {
            return fileURL
        } else {
            print("ERROR - bad path for push log")
            return nil
        }
    }

    public func appFileData() -> Data {
        if let logPathURL = Log.appLogFilePathURL() {
            return fileData(filePathURL: logPathURL)
        } else {
            return Data()
        }
    }
    
    public func pushFileData() -> Data {
        if let logPathURL = Log.pushLogFilePathURL() {
            return fileData(filePathURL: logPathURL)
        } else {
            return Data()
        }
    }

    public func fileData(filePathURL: URL) -> Data {
        var fileData: Data
        if let data = NSData(contentsOf: filePathURL) {
            fileData = data as Data
        } else {
            fileData = Data()
        }
        return fileData
    }
    
    
}

