import Foundation
import PackagePlugin

@main
struct SwiftGenPlugin: BuildToolPlugin {
	private static let swiftGenConfigFilename = "swiftgen.yml"

	// We're not using PackagePlugins
	func createBuildCommands(context: PluginContext, target: Target) async throws -> [Command] {
		return []
	}
}

#if canImport(XcodeProjectPlugin)
import XcodeProjectPlugin

extension SwiftGenPlugin: XcodeBuildToolPlugin {
    func createBuildCommands(context: XcodePluginContext, target: XcodeTarget) throws -> [Command] {
        let fileManager = FileManager.default

		let path = context.xcodeProject.directory.appending(Self.swiftGenConfigFilename)
		guard fileManager.fileExists(atPath: path.string) else {
			// swiftlint:disable:next line_length
			Diagnostics.remark("No SwiftGen configurations found for target \(target.displayName). If you would like to generate sources for this target (\(target.displayName)), include a `swiftgen.yml` in the project's root directory.")
			return []
		}

		let targetName = target.product?.name ?? target.displayName
//		let outputFilesDirectory = context.xcodeProject.directory.appending([targetName, "Localization"])
		let outputFilesDirectory = context.pluginWorkDirectory.appending([targetName])
		try? fileManager.removeItem(atPath: outputFilesDirectory.string)
		try? fileManager.createDirectory(atPath: outputFilesDirectory.string, withIntermediateDirectories: false)

		let executable = try context.tool(named: "swiftgen")
		let command = Command.prebuildCommand(
			displayName: "Run SwiftGen",
			executable: executable.path,
			arguments: [
				"config",
				"run",
				"--verbose",
				"--config", path
			],
			environment: [
				"PROJECT_DIR": context.xcodeProject.directory.appending(targetName),
				"TARGET_NAME": target.displayName,
				"OUTPUT_DIR": outputFilesDirectory
			],
			outputFilesDirectory: outputFilesDirectory
		)
		return [command]
    }
}
#endif
