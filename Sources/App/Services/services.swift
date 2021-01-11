import Vapor

// MARK: - Slack
extension Application {
	struct SlackServiceKey: StorageKey {
		typealias Value = SlackService
	}

	public var slack: SlackService? {
		get {
			self.storage[SlackServiceKey.self]
		}
		set {
			self.storage[SlackServiceKey.self] = newValue
		}
	}
}
