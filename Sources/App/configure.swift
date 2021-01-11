import Vapor

public func configure(_ app: Application) throws {
	app.slack = .init(
		verificationToken: try attempt { Environment.slackToken },
		oauthToken: try attempt { Environment.slackOAuthToken }
	)

	guard app.slack != nil else {
		fatalError("Services are not set up")
	}

	try routes(
		app,
		commands: [
			.jimothy(app)
		]
	)
}

extension Environment {
	/// Verification Token (see SlackBot App settings)
	static let slackToken       = Environment.get("SLACK_TOKEN")
	/// Bot User OAuth Access Token (see SlackBot App settings)
	static let slackOAuthToken  = Environment.get("SLACK_OAUTH_TOKEN")
}
