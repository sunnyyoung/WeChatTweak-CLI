//
//  Command.swift
//
//  Created by Sunny Young.
//

import Foundation
import Alamofire
import PromiseKit
import ArgumentParser
import insert_dylib

struct Command {
    static func check() -> Promise<Void> {
        return getuid() == 0 ? .value(()) : .init(error: CLIError.permission)
    }

    static func cleanup() -> Guarantee<Void> {
        return Guarantee { seal in
            try? FileManager.default.removeItem(atPath: Temp.zip)
            try? FileManager.default.removeItem(atPath: Temp.binary)
            seal(())
        }
    }

    static func backup() -> Promise<Void> {
        print("------ Backup ------")
        return Promise { seal in
            do {
                if FileManager.default.fileExists(atPath: App.backup) {
                    print("WeChat.bak exists, skip it...")
                } else {
                    try FileManager.default.copyItem(atPath: App.binary, toPath: App.backup)
                    print("Created WeChat.bak...")
                }
                seal.fulfill(())
            } catch {
                seal.reject(error)
            }
        }
    }

    static func restore() -> Promise<Void> {
        print("------ Restore ------")
        return Promise { seal in
            do {
                if FileManager.default.fileExists(atPath: App.backup) {
                    try FileManager.default.removeItem(atPath: App.binary)
                    try FileManager.default.moveItem(atPath: App.backup, toPath: App.binary)
                    try? FileManager.default.removeItem(atPath: App.framework)
                    print("Restored WeChat...")
                } else {
                    print("WeChat.bak not exists, skip it...")
                }
                seal.fulfill(())
            } catch {
                seal.reject(error)
            }
        }
    }

    static func download() -> Promise<Void> {
        print("------ Download ------")
        return Promise { seal in
            let destination: DownloadRequest.DownloadFileDestination = { _, _ in
                return (.init(fileURLWithPath: Temp.zip), [.removePreviousFile])
            }
            Alamofire.download(Constant.url, to: destination).response { response in
                if let error = response.error {
                    seal.reject(CLIError.downloading(error))
                } else {
                    seal.fulfill(())
                }
            }
        }
    }

    static func unzip() -> Promise<Void> {
        print("------ Unzip ------")
        return Command.execute(command: "rm -rf \(App.framework); unzip \(Temp.zip) -d \(App.macos)")
    }

    static func insert() -> Promise<Void> {
        print("------ Insert Dylib ------")
        return Promise { seal in
            insert_dylib.insert("@executable_path/WeChatTweak.framework/WeChatTweak", App.binary) == EXIT_SUCCESS ? seal.fulfill(()) : seal.reject(CLIError.insertDylib)
        }
    }

    static func removeCodesign() -> Promise<Void> {
        print("------ Remove Codesign ------")
        return Command.execute(command: "codesign --remove-sign \(App.binary)")
    }

    static func addCodesign() -> Promise<Void> {
        print("------ Add Codesign ------")
        return Command.execute(command: "codesign --force --deep --sign - \(App.binary)")
    }

    static func resetPermission() -> Promise<Void> {
        print("------ Reset ScreenCapture privacy permission ------")
        return Command.execute(command: "tccutil reset ScreenCapture com.tencent.xinWeChat")
    }

    private static func execute(command: String) -> Promise<Void> {
        return Promise { seal in
            print("Execute command: \(command)")
            var error: NSDictionary?
            guard let script = NSAppleScript(source: "do shell script \"\(command)\"") else {
                return seal.reject(CLIError.executing(command: command, error: ["error": "Create script failed."]))
            }
            script.executeAndReturnError(&error)
            if let error = error {
                seal.reject(CLIError.executing(command: command, error: error))
            } else {
                seal.fulfill(())
            }
        }
    }
}
