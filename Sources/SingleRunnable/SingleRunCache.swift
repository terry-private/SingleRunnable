import Foundation

final actor SingleRunCache {
    private init() {}
    static let shared = SingleRunCache()
    private var tasks: [String: Any] = [:]
    
    @discardableResult
    func run<T>(name: String, runner: @escaping () async throws -> T) async throws -> T {
        print("🅰️start run")
        if tasks[name] == nil {
            print("🅰️create")
            tasks[name] = Task { try await runner() }
        }
        let task = tasks[name] as! Task<T, Error>
        let value = try await task.value
        tasks[name] = nil
        return value
    }
}
