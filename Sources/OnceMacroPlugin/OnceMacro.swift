public import SwiftSyntax
public import SwiftSyntaxMacros

public struct OnceMacro: ExpressionMacro {
	public static func expansion(
		of node: some FreestandingMacroExpansionSyntax,
		in context: some MacroExpansionContext
	) throws -> ExprSyntax {
		guard let block = node.arguments.first?.expression.as(ClosureExprSyntax.self) ?? node.trailingClosure else {
			throw MacroError.missingArgument("block")
		}

		let throwingFinder = ThrowingFinder()
		throwingFinder.walk(block)
		let tryKeyword = throwingFinder.found ? "try " : ""

		let asyncFinder = AsyncFinder()
		asyncFinder.walk(block)
		if !asyncFinder.found {
			return """
			{
				final class Once: @unchecked Sendable {
					static let shared = Once()

					private var hasRun = false
					private var isRunning = false
					private let lock = NSLock()

					@discardableResult
					func run<T>(_ block: () throws -> T) rethrows -> T? {
						lock.lock()
						if hasRun || isRunning {
							lock.unlock()
							return nil
						}
						isRunning = true
						lock.unlock()

						defer {
							lock.lock()
							isRunning = false
							hasRun = true
							lock.unlock()
						}

						return try block()
					}
				}

				return \(raw: tryKeyword)Once.shared.run \(block)
			}()
			"""
		} else {
			return """
			{
				actor Once {
					static let shared = Once()

					private var hasRun = false
					private var isRunning = false

					@discardableResult
					func run<T: Sendable>(_ block: () async throws -> T) async rethrows -> T? {
						guard !hasRun && !isRunning else {
							return nil
						}
						isRunning = true

						defer {
							isRunning = false
							hasRun = true
						}

						return try await block()
					}
				}

				return \(raw: tryKeyword)await Once.shared.run \(block)
			}()
			"""
		}
	}
}

final class AsyncFinder: SyntaxVisitor {
	private var atRoot = true
	private(set) var found = false

	init() {
		super.init(viewMode: .sourceAccurate)
	}

	override func visit(_ node: ClosureExprSyntax) -> SyntaxVisitorContinueKind {
		if atRoot {
			atRoot = false
			return .visitChildren
		} else {
			return .skipChildren
		}
	}

	override func visit(_ node: ClosureSignatureSyntax) -> SyntaxVisitorContinueKind {
		if node.effectSpecifiers?.asyncSpecifier != nil {
			found = true
		}
		return .skipChildren
	}

	override func visit(_ node: AwaitExprSyntax) -> SyntaxVisitorContinueKind {
		found = true
		return .skipChildren
	}

	override func visit(_ node: FunctionDeclSyntax) -> SyntaxVisitorContinueKind {
		.skipChildren
	}
}

final class ThrowingFinder: SyntaxVisitor {
	private var atRoot = true
	private(set) var found = false

	init() {
		super.init(viewMode: .sourceAccurate)
	}

	override func visit(_ node: ClosureExprSyntax) -> SyntaxVisitorContinueKind {
		if atRoot {
			atRoot = false
			return .visitChildren
		} else {
			return .skipChildren
		}
	}

	override func visit(_ node: ClosureSignatureSyntax) -> SyntaxVisitorContinueKind {
		if node.effectSpecifiers?.throwsClause != nil {
			found = true
		}
		return .skipChildren
	}

	override func visit(_ node: TryExprSyntax) -> SyntaxVisitorContinueKind {
		if node.questionOrExclamationMark == nil {
			found = true
		}
		return .skipChildren
	}

	override func visit(_ node: DoStmtSyntax) -> SyntaxVisitorContinueKind {
		.skipChildren
	}

	override func visit(_ node: FunctionDeclSyntax) -> SyntaxVisitorContinueKind {
		.skipChildren
	}
}

enum MacroError: Error {
	case missingArgument(String)
}
