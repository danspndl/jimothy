import Vapor

extension SlackCommand {
	static let jimothy = { (app: Application) in
		SlackCommand(
			name: "jimothy",
			help: """
            Invokes lane, beta or AppStore build or runs arbitrary workflow.

            Parameters:
            - name of the workflow or sub command to run
            - list of workflow or sub command parameters in the fastlane format (e.g. `param:value`)
            - `branch`: name of the branch to run the lane on. Default is `develop`

            Example:
            `/jimothy beta param:value \(Option.branch.value):develop`
            """,
			allowedChannels: [],
			subCommands: [],
			run: { (metadata, container) -> EventLoopFuture<SlackService.Response>in
				#warning("TODO connect to other service")
				return app.client.eventLoop.makeSucceededFuture(SlackService.Response("ok"))
			}
		)
	}
}
