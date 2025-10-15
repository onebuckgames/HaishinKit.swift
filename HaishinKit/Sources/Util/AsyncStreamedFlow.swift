import Foundation

@propertyWrapper
package struct AsyncStreamedFlow<T: Sendable & Equatable> {
    package var wrappedValue: AsyncStream<T> {
        get {
            return stream
        }
        @available(*, unavailable)
        set { _ = newValue }
    }
    private let stream: AsyncStream<T>
    private let continuation: AsyncStream<T>.Continuation

    package init(_ bufferingPolicy: AsyncStream<T>.Continuation.BufferingPolicy = .unbounded) {
        let (stream, continuation) = AsyncStream.makeStream(of: T.self, bufferingPolicy: bufferingPolicy)
        self.stream = stream
        self.continuation = continuation
    }
}
