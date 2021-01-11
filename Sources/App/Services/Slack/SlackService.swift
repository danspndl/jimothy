import Vapor

// MARK: - SlackService

public struct SlackService {
	/// Verification Token (see SlackBot App settings)
	let verificationToken: String
	/// Bot User OAuth Access Token (see SlackBot App settings)
	let oauthToken: String

	public init(verificationToken: String, oauthToken: String) {
		self.verificationToken = verificationToken
		self.oauthToken = oauthToken
	}

	public func handle(
		command: SlackCommand,
		on request: Request
	) throws -> EventLoopFuture<Vapor.Response> {
		let metadata = try request.content
			.decode(SlackCommand.Metadata.self)

		guard metadata.token == verificationToken else {
			throw ThrowError(
				error: Error.invalidToken,
				sourceLocation: .capture()
			)
		}

		guard command.allowedChannels.isEmpty || command.allowedChannels.contains(metadata.channelName) else {
			throw ThrowError(
				error: Error.invalidChannel(metadata.channelName, allowed: command.allowedChannels),
				sourceLocation: .capture()
			)
		}

		if metadata.text == "help" {
			return try request.eventLoop
				.future(SlackService.Response(command.help))
				.catchError(.capture())
				.recover { SlackService.Response(error: $0) }
				.encodeResponse(for: request)
		} else {
			return try command.run(metadata, request)
				.catchError(.capture())
				.recover { SlackService.Response(error: $0) }
				.encodeResponse(for: request)
		}
	}

	public func post(
		message: Message,
		on request: Request
	) throws -> EventLoopFuture<Vapor.Response> {
		let fullURL = URI(string: "https://slack.com/api/chat.postMessage")
		let headers: HTTPHeaders = [
			"Authorization": "Bearer \(self.oauthToken)"
		]

		return try request.client
			.post(fullURL, headers: headers) {
				try $0.content.encode(message)
			}
			.catchError(.capture())
			.encodeResponse(for: request)
	}
}

// MARK: `replyLater`

extension EventLoopFuture where Value == SlackService.Response {
	public func replyLater(
		withImmediateResponse now: SlackService.Response,
		responseURL: String?,
		on request: Request
	) -> EventLoopFuture<SlackService.Response> {
		guard let responseURL = responseURL else {
			return request.eventLoop.future(now)
		}

		_ = self
			.recover { SlackService.Response(error: $0) }
			.flatMapThrowing { response in
				try request.client
					.post(URI(string: responseURL)) {
						try $0.content.encode(response)
					}
					.catchError(.capture())
			}

		return request.eventLoop.future(now)
	}
}
