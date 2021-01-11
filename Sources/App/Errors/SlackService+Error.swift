import Vapor

extension SlackService {
	public enum Error: Swift.Error, DebuggableError {
		case invalidToken
		case invalidChannel(String, allowed: Set<String>)
		case missingParameter(key: String)
		case invalidParameter(key: String, value: String, expected: String)

		public var identifier: String {
			"SlackService.Error"
		}

		public var reason: String {
			switch self {
				case .invalidToken:
					return "Invalid token"
				case let .invalidChannel(channel, allowed):
					return """
                    Invalid channel `\(channel)`. Command should be invoked from one of these channels:
                    \(allowed.map { "* `\($0)`" }.joined(separator: "\n"))
                    """
				case let .missingParameter(key):
					return "Missing parameter for `\(key)`"
				case let .invalidParameter(key, value, expected):
					return "Invalid parameter `\(value)` for `\(key)`. Expected \(expected)."
			}
		}
	}
}

#if !DEBUG
extension SlackService.Error {
	public var errorDescription: String? {
		reason
	}
}
#endif

extension SlackService.Response {
	public init(error: Error, visibility: Visibility = .user) {
		#if DEBUG
		self.init(String(describing: error), visibility: visibility)
		#else
		self.init(error.localizedDescription, visibility: visibility)
		#endif
	}
}
