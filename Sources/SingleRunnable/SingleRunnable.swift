public protocol SingleRunnable {}

public extension SingleRunnable {
    @discardableResult
    static func singleRun<T>(name: String = "\(Self.self)" ,runner: @escaping () async throws -> T) async throws -> T {
        try await SingleRunCache.shared.run(name: name, runner: runner)
    }
}
