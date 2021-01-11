import Vapor

protocol FailableService {
	associatedtype ServiceError: Error & Decodable & DebuggableError
}

extension FailableService {
	public func request<T: Decodable>(
		_ errorSource: ErrorSource,
		_ makeRequest: () throws -> EventLoopFuture<Response>
	) throws -> EventLoopFuture<T> {
		try makeRequest()
			.flatMapThrowing { response -> T in
				do {
					return try response.content
						.decode(T.self)
				} catch {
					throw try response.content
					.decode(ServiceError.self)
				}
			}
	}

	public func request(
		_ errorSource: ErrorSource,
		_ makeRequest: () throws -> EventLoopFuture<Response>
	) throws -> EventLoopFuture<Void> {
		try makeRequest()
			.flatMapThrowing { (response) in
				guard response.status == .noContent else {
					throw try response.content
					.decode(ServiceError.self)
				}
			}
			.catchError(.capture())
	}
}

public struct NilValueError: Error, DebuggableError {
	public let identifier = "nilValue"
	public let reason = "Unexpected nil value"
}

public struct ThrowError: Error, DebuggableError {
	public let error: Error
	public let identifier: String
	public let reason: String
	public let sourceLocation: ErrorSource?

	init(error: Error, sourceLocation: ErrorSource) {
		self.error = error

		let _sourceLocation: ErrorSource?
		if let throwError = error as? ThrowError {
			self.identifier = throwError.identifier
			self.reason = throwError.reason
			_sourceLocation = throwError.sourceLocation
		} else if let debuggable = error as? DebuggableError {
			self.identifier = "\(type(of: debuggable)).\(debuggable.identifier)"
			self.reason = debuggable.reason
			_sourceLocation = debuggable.source
		} else {
			self.identifier = "\(type(of: error))"
			self.reason = error.localizedDescription
			_sourceLocation = sourceLocation
		}

		#if DEBUG
		self.sourceLocation = _sourceLocation ?? sourceLocation
		#else
		self.sourceLocation = nil
		#endif
	}

	init(error: Error, file: String, line: UInt, column: UInt, function: String) {
		self.init(
			error: error,
			sourceLocation: ErrorSource(
				file: file,
				function: function,
				line: line,
				column: column,
				range: nil
			)
		)
	}
}

#if !DEBUG
extension ThrowError: LocalizedError {
	public var errorDescription: String? {
		reason
	}
}
#endif

public func attempt<T>(
	file: StaticString = #file,
	line: UInt = #line,
	column: UInt = #column,
	function: StaticString = #function,
	expr: () throws -> T?
) throws -> T {
	do {
		guard let value = try expr() else {
			throw NilValueError()
		}
		return value
	} catch {
		throw ThrowError(error: error, file: "\(file)", line: line, column: column, function: "\(function)")
	}
}

public func attempt<T>(
	file: StaticString = #file,
	line: UInt = #line,
	column: UInt = #column,
	function: StaticString = #function,
	expr: () throws -> T?
) throws -> T? {
	do {
		return try expr()
	} catch {
		throw ThrowError(error: error, file: "\(file)", line: line, column: column, function: "\(function)")
	}
}

extension EventLoopFuture {
	public func catchError(_ errorSource: ErrorSource) throws -> EventLoopFuture<Value> {
		catchFlatMap { (error) -> EventLoopFuture<Value> in
			throw ThrowError(error: error, sourceLocation: errorSource)
		}
	}

	private func catchFlatMap(
		_ callback: @escaping (Error) throws -> (EventLoopFuture<Value>)
	) -> EventLoopFuture<Value> {
		let promise = eventLoop.makePromise(of: Value.self)

		_ = self.always { result in
			switch result {
				case let .success(e):
					promise.succeed(e)
				case let .failure(error):
					do {
						try callback(error).cascade(to: promise)
					} catch {
						promise.fail(error)
					}
			}
		}

		return promise.futureResult
	}
}
