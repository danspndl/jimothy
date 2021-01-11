import Vapor

func routes(
	_ app: Application,
	commands: [SlackCommand]
) throws {
    app.get { req in
        return "It works!"
    }

	commands.forEach { command in
		app.post(PathComponent(stringLiteral: command.name)) { req -> EventLoopFuture<Response> in
			guard let slack = app.slack else {
				fatalError("Slack is not set up")
			}
			do {
				return try attempt {
					try slack.handle(command: command, on: req)
				}
			} catch {
				return SlackService.Response(error: error).encodeResponse(for: req)
			}
		}
	}
}
