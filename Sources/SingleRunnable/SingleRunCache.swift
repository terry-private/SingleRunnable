import Foundation

final actor SingleRunCache {
    private init() {}
    static let shared = SingleRunCache()
    private var tasks: [String: Any] = [:]
    
    @discardableResult
    func run<T>(name: String, runner: @escaping () async throws -> T) async throws -> T {
        if tasks[name] == nil {
            print("タスク登録!!")
            tasks[name] = Task { try await runner() }
        } else {
            print("先に実行してるのがある！")
        }
        let task = tasks[name] as! Task<T, Error>
        let value = try await task.value
        tasks[name] = nil
        return value
    }
}
