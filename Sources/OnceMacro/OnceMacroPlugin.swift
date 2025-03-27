import SwiftCompilerPlugin
import SwiftSyntaxMacros

@main
struct OnceMacroPlugin: CompilerPlugin {
	let providingMacros: [any Macro.Type] = [
		OnceMacro.self,
	]
}
