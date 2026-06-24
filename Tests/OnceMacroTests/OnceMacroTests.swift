#if canImport(OnceMacro)
import MacroTesting
@testable import OnceMacro
import SnapshotTesting
import SwiftSyntax
import Testing

@Suite(
	.macros(
		["once": OnceMacro.self],
		indentationWidth: .tab,
		record: .missing,
	),
)
struct OnceMacroTests {}

// MARK: Sync

extension OnceMacroTests {
	@Test
	func `sync macro expands to lock backed helper`() {
		assertMacro {
			"""
			#once {
				print("Hello, world!")
			}
			"""
		} expansion: {
			"""
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

				return Once.shared.run {
				print("Hello, world!")
				}
			}()
			"""
		}
	}

	@Test
	func `sync throwing macro preserves try`() {
		assertMacro {
			"""
			try #once {
				try print("Hello, world!")
			}

			try #once { () throws in
				print("Hello, world!")
			}
			"""
		} expansion: {
			"""
			try {
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

				return try Once.shared.run {
				try print("Hello, world!")
				}
			}()

			try {
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

				return try Once.shared.run { () throws in
				print("Hello, world!")
				}
			}()
			"""
		}
	}

	@Test
	func `sync macro preserves complex body`() {
		assertMacro {
			"""
			#once {
				try! doSomething() {
					try foo()
				}
				bar()
				let bazResult = try? baz()
				func somethingThrowsInside() throws {
					try something()
				}
				do {
					try something()
				}
				do {
					try something()
				} catch {}
			}
			"""
		} expansion: {
			"""
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

				return Once.shared.run {
				try! doSomething() {
					try foo()
				}
				bar()
				let bazResult = try? baz()
				func somethingThrowsInside() throws {
					try something()
				}
				do {
					try something()
				}
				do {
					try something()
				} catch {
				}
				}
			}()
			"""
		}
	}
}

// MARK: Async

extension OnceMacroTests {
	@Test
	func `async macro expands to actor backed helper`() {
		assertMacro {
			"""
			await #once { () async in
				print("Hello, async world!")
			}
			"""
		} expansion: {
			"""
			await {
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

				return await Once.shared.run { () async in
				print("Hello, async world!")
				}
			}()
			"""
		}
	}

	@Test
	func `async throwing macro preserves try await`() {
		assertMacro {
			"""
			try await #once {
				try await doSomething()
				print("Hello, throwing async world!")
			}
			"""
		} expansion: {
			"""
			try await {
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

				return try await Once.shared.run {
				try await doSomething()
				print("Hello, throwing async world!")
				}
			}()
			"""
		}
	}

	@Test
	func `async macro preserves complex body`() {
		assertMacro {
			"""
			await #once {
				do {
					try await risky()
				} catch {
					handle(error)
				}
			}
			"""
		} expansion: {
			"""
			await {
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

				return await Once.shared.run {
				do {
					try await risky()
				} catch {
					handle(error)
				}
				}
			}()
			"""
		}
	}
}
#endif
