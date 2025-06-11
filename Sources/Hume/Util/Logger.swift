import Foundation

struct Logger {
    enum LogLevel: String {
        case debug = "🤖 DEBUG"
        case info = "ℹ️ INFO"
        case warn = "⚠️ WARN"
        case error = "❌ ERROR"
    }
    
    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS"
        formatter.timeZone = TimeZone.current
        return formatter
    }()

    
    static func log(_ message: String, level: LogLevel = .info, fileName: String = #file, lineNumber: Int = #line) {
#if DEBUG
        let fileNameWithoutPath = (fileName as NSString).lastPathComponent
        let currentTime = dateFormatter.string(from: Date())
        let logMessage = "[Hume SDK][\(currentTime)] [\(level.rawValue)] [\(fileNameWithoutPath):\(lineNumber)]: \(message)"
        print(logMessage)
#endif
    }
    
    static func debug(_ message: String, fileName: String = #file, lineNumber: Int = #line) {
        log(message, level: .debug, fileName: fileName, lineNumber: lineNumber)
    }
    
    static func info(_ message: String, fileName: String = #file, lineNumber: Int = #line) {
        log(message, level: .info, fileName: fileName, lineNumber: lineNumber)
    }
    
    static func warn(_ message: String, fileName: String = #file, lineNumber: Int = #line) {
        log(message, level: .warn, fileName: fileName, lineNumber: lineNumber)
    }
    
    static func error(_ message: String, _ error: Error? = nil, fileName: String = #file, lineNumber: Int = #line) {
        log("\(message)\(error != nil ? " - \(String(describing: error!))" : "")", level: .error, fileName: fileName, lineNumber: lineNumber)
    }
}
