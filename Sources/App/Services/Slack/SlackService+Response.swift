import Vapor

extension SlackService {
	public struct Response: Content {
		public let text: String
		public let attachments: [Attachment]?
		public let visibility: Visibility

		public enum Visibility: String, Content {
			/// Response message visible only to the user who triggered the command
			case user = "ephemeral"
			/// Response message visible to all members of the channel where the command was triggered
			case channel = "in_channel"
		}

		enum CodingKeys: String, CodingKey {
			case text
			case attachments
			case visibility = "response_type"
		}

		public init(_ text: String, attachments: [Attachment]? = nil, visibility: Visibility = .user) {
			self.text = text
			self.attachments = attachments
			self.visibility = visibility
		}
	}

	public struct Message: Content {
		public let channelID: String
		public let text: String
		public let attachments: [Attachment]?

		enum CodingKeys: String, CodingKey {
			case channelID = "channel"
			case text
			case attachments
		}

		public init(channelID: String, text: String, attachments: [Attachment]? = nil) {
			self.channelID = channelID
			self.text = text
			self.attachments = attachments
		}
	}

	public struct Attachment: Content {
		let text: String
		let color: String
		public init(text: String, color: String) {
			self.text = text
			self.color = color
		}
		public static func success(_ text: String) -> Attachment {
			.init(text: text, color: "36a64f")
		}
		public static func warning(_ text: String) -> Attachment {
			.init(text: text, color: "fff000")
		}
		public static func error(_ text: String) -> Attachment {
			.init(text: text, color: "ff0000")
		}
	}
}
