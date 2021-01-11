import Vapor

extension SlackCommand {
	struct Option {
		let value: String
		private init(_ value: String) {
			self.value = value
		}

		static let branch   = Option("branch")
		static let repo     = Option("repo")
		static let version  = Option("version")
	}
}

extension SlackCommand.Metadata {
	func value(forOption option: SlackCommand.Option) -> String? {
		let optionPrefix = option.value + ":"
		let branch = textComponents.dropFirst()
			.first { $0.hasPrefix(optionPrefix) }?
			.dropFirst(optionPrefix.count)
		return branch.map(String.init)
	}
}
