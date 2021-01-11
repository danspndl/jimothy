import Vapor

public struct SlackCommand {
	/// Command name
	public let name: String

	/// Command usage instructions
	public let help: String

	/// Channels from which this command is allowed to be triggered.
	/// If empty the command will be allowed in all channels
	public let allowedChannels: Set<String>

	/// Closure that performs the actual action of the command.
	/// If sub commands are provided, it will first try to select the appropriate sub-command
	/// by the first word in the command text, and if it finds one then this command will be executed,
	/// otherwise this closure is called
	public let run: (SlackCommand.Metadata, Request) throws -> EventLoopFuture<SlackService.Response>

	public init(
		name: String,
		help: String,
		allowedChannels: Set<String>,
		subCommands: [SlackCommand] = [],
		run: @escaping (SlackCommand.Metadata, Request) throws -> EventLoopFuture<SlackService.Response>
	) {
		self.name = name
		self.allowedChannels = allowedChannels
		if subCommands.isEmpty {
			self.help = help
		} else {
			self.help = help +
				"""
            Sub-commands:
            \(subCommands.map({ "- \($0.name)" }).joined(separator: "\n"))

            Run `/\(name) <sub-command> help` for help on a sub-command.
            """
		}
		self.run = { (metadata, request) throws -> EventLoopFuture<SlackService.Response> in
			guard let subCommand = subCommands.first(where: { metadata.text.hasPrefix($0.name) }) else {
				return try run(metadata, request)
			}

			if metadata.textComponents[1] == "help" {
				return request.eventLoop.future(SlackService.Response(subCommand.help))
			} else {
				let metadata = SlackCommand.Metadata(
					token: metadata.token,
					channelName: metadata.channelName,
					command: metadata.command,
					text: metadata.textComponents.dropFirst().joined(separator: " "),
					responseURL: metadata.responseURL
				)
				return try subCommand.run(metadata, request)
			}
		}
	}
}

extension SlackCommand {
	public struct Metadata: Content {
		public let token: String
		public let channelName: String
		public let command: String
		public let text: String
		public let textComponents: [String.SubSequence]
		public let responseURL: String?

		public init(
			token: String,
			channelName: String,
			command: String,
			text: String,
			responseURL: String?
		) {
			self.token = token
			self.channelName = channelName
			self.command = command
			self.text = text
			self.textComponents = text.split(separator: " ")
			self.responseURL = responseURL
		}

		enum CodingKeys: String, CodingKey {
			case token
			case channelName = "channel_name"
			case command
			case text
			case responseURL = "response_url"
		}

		public init(from decoder: Decoder) throws {
			let container = try decoder.container(keyedBy: CodingKeys.self)
			self = try SlackCommand.Metadata(
				token:          container.decode(String.self, forKey: .token),
				channelName:    container.decode(String.self, forKey: .channelName),
				command:        container.decode(String.self, forKey: .command),
				text:           container.decode(String.self, forKey: .text),
				responseURL:    container.decodeIfPresent(String.self, forKey: .responseURL)
			)
		}
	}
}
