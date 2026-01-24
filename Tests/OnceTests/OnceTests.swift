import Once
import Testing

@Suite
struct OnceTests {}

// MARK: Sync

extension OnceTests {
	@Test
	func sync() async {
		func doSomethingOnce(_ confirmation: Confirmation) {
			#once {
				confirmation()
			}
		}

		await confirmation(expectedCount: 1) { confirmation in
			doSomethingOnce(confirmation)
			doSomethingOnce(confirmation)
			doSomethingOnce(confirmation)
		}

		await confirmation(expectedCount: 0) { confirmation in
			doSomethingOnce(confirmation)
		}
	}

	@Test
	func syncConcurrent() async {
		func doSomethingOnce(_ confirmation: Confirmation) {
			#once {
				confirmation()
			}
		}

		await confirmation(expectedCount: 1) { confirmation in
			await withTaskGroup(of: Void.self) { group in
				for _ in 0..<100 {
					group.addTask {
						doSomethingOnce(confirmation)
					}
				}
			}
		}

		await confirmation(expectedCount: 0) { confirmation in
			await withTaskGroup(of: Void.self) { group in
				for _ in 0..<100 {
					group.addTask {
						doSomethingOnce(confirmation)
					}
				}
			}
		}
	}

	@Test
	func syncReentrancy() async {
		func doSomethingOnce(_ confirmation: Confirmation) {
			func reentrant() {
				#once {
					reentrant() // re-entrant call
					confirmation()
				}
			}

			reentrant()
		}

		await confirmation(expectedCount: 1) { confirmation in
			doSomethingOnce(confirmation)
			doSomethingOnce(confirmation)
			doSomethingOnce(confirmation)
		}

		await confirmation(expectedCount: 0) { confirmation in
			doSomethingOnce(confirmation)
		}
	}

	@Test
	func syncConcurrentReentrancy() async {
		func doSomethingOnce(_ confirmation: Confirmation) {
			func reentrant() {
				#once {
					reentrant() // re-entrant call
					confirmation()
				}
			}

			reentrant()
		}

		await confirmation(expectedCount: 1) { confirmation in
			await withTaskGroup(of: Void.self) { group in
				for _ in 0..<100 {
					group.addTask {
						doSomethingOnce(confirmation)
					}
				}
			}
		}

		await confirmation(expectedCount: 0) { confirmation in
			await withTaskGroup(of: Void.self) { group in
				for _ in 0..<100 {
					group.addTask {
						doSomethingOnce(confirmation)
					}
				}
			}
		}
	}

	@Test
	func syncThrowing() async throws {
		func throwingFunction() throws {}

		func doSomethingOnce(_ confirmation: Confirmation) throws {
			try #once {
				try throwingFunction()
				confirmation()
			}
		}

		try await confirmation(expectedCount: 1) { confirmation in
			try doSomethingOnce(confirmation)
			try doSomethingOnce(confirmation)
			try doSomethingOnce(confirmation)
		}

		try await confirmation(expectedCount: 0) { confirmation in
			try doSomethingOnce(confirmation)
		}
	}

	@Test
	func syncConcurrentThrowing() async throws {
		func throwingFunction() throws {}

		func doSomethingOnce(_ confirmation: Confirmation) throws {
			try #once {
				try throwingFunction()
				confirmation()
			}
		}

		try await confirmation(expectedCount: 1) { confirmation in
			try await withThrowingTaskGroup(of: Void.self) { group in
				for _ in 0..<100 {
					group.addTask {
						try doSomethingOnce(confirmation)
					}
				}
				try await group.waitForAll()
			}
		}

		try await confirmation(expectedCount: 0) { confirmation in
			try await withThrowingTaskGroup(of: Void.self) { group in
				for _ in 0..<100 {
					group.addTask {
						try doSomethingOnce(confirmation)
					}
				}
				try await group.waitForAll()
			}
		}
	}

	@Test
	func syncMultiple() async throws {
		func throwingFunction() throws {}

		func doSomethingOnceThrowing(_ confirmation: Confirmation) throws {
			try #once {
				try throwingFunction()
				confirmation()
			}
		}

		func doSomethingOnce(_ confirmation: Confirmation) {
			#once {
				confirmation()
			}
		}

		try await confirmation(expectedCount: 2) { confirmation in
			doSomethingOnce(confirmation)
			try doSomethingOnceThrowing(confirmation)
		}

		try await confirmation(expectedCount: 0) { confirmation in
			doSomethingOnce(confirmation)
			try doSomethingOnceThrowing(confirmation)
		}
	}

	@Test
	func syncConcurrentMultiple() async throws {
		func throwingFunction() throws {}

		func doSomethingOnceThrowing(_ confirmation: Confirmation) throws {
			try #once {
				try throwingFunction()
				confirmation()
			}
		}

		func doSomethingOnce(_ confirmation: Confirmation) {
			#once {
				confirmation()
			}
		}

		try await confirmation(expectedCount: 2) { confirmation in
			try await withThrowingTaskGroup(of: Void.self) { group in
				for _ in 0..<100 {
					group.addTask {
						doSomethingOnce(confirmation)
					}
					group.addTask {
						try doSomethingOnceThrowing(confirmation)
					}
				}
				try await group.waitForAll()
			}
		}

		try await confirmation(expectedCount: 0) { confirmation in
			try await withThrowingTaskGroup(of: Void.self) { group in
				for _ in 0..<100 {
					group.addTask {
						doSomethingOnce(confirmation)
					}
					group.addTask {
						try doSomethingOnceThrowing(confirmation)
					}
				}
				try await group.waitForAll()
			}
		}
	}

	@Test
	func syncMultipleThrowing() async throws {
		func throwingFunctionA() throws {}
		func throwingFunctionB() throws {}

		func doSomethingOnceA(_ confirmation: Confirmation) throws {
			try #once {
				try throwingFunctionA()
				confirmation()
			}
		}

		func doSomethingOnceB(_ confirmation: Confirmation) throws {
			try #once {
				try throwingFunctionB()
				confirmation()
			}
		}

		try await confirmation(expectedCount: 2) { confirmation in
			try doSomethingOnceA(confirmation)
			try doSomethingOnceB(confirmation)
		}

		try await confirmation(expectedCount: 0) { confirmation in
			try doSomethingOnceA(confirmation)
			try doSomethingOnceB(confirmation)
		}
	}

	@Test
	func syncConcurrentMultipleThrowing() async throws {
		func throwingFunctionA() throws {}
		func throwingFunctionB() throws {}

		func doSomethingOnceA(_ confirmation: Confirmation) throws {
			try #once {
				try throwingFunctionA()
				confirmation()
			}
		}

		func doSomethingOnceB(_ confirmation: Confirmation) throws {
			try #once {
				try throwingFunctionB()
				confirmation()
			}
		}

		try await confirmation(expectedCount: 2) { confirmation in
			try await withThrowingTaskGroup(of: Void.self) { group in
				for _ in 0..<100 {
					group.addTask {
						try doSomethingOnceA(confirmation)
					}
					group.addTask {
						try doSomethingOnceB(confirmation)
					}
				}
				try await group.waitForAll()
			}
		}

		try await confirmation(expectedCount: 0) { confirmation in
			try await withThrowingTaskGroup(of: Void.self) { group in
				for _ in 0..<100 {
					group.addTask {
						try doSomethingOnceA(confirmation)
					}
					group.addTask {
						try doSomethingOnceB(confirmation)
					}
				}
				try await group.waitForAll()
			}
		}
	}
}

// MARK: Async

extension OnceTests {
	@Test
	func async() async {
		func doSomethingOnce(_ confirmation: Confirmation) async {
			await #once {
				await Task.yield() // force async context
				confirmation()
			}
		}

		await confirmation(expectedCount: 1) { confirmation in
			await doSomethingOnce(confirmation)
			await doSomethingOnce(confirmation)
			await doSomethingOnce(confirmation)
		}

		await confirmation(expectedCount: 0) { confirmation in
			await doSomethingOnce(confirmation)
		}
	}

	@Test
	func asyncConcurrent() async {
		func doSomethingOnce(_ confirmation: Confirmation) async {
			await #once {
				await Task.yield() // force async context
				confirmation()
			}
		}

		await confirmation(expectedCount: 1) { confirmation in
			await withTaskGroup(of: Void.self) { group in
				for _ in 0..<100 {
					group.addTask {
						await doSomethingOnce(confirmation)
					}
				}
			}
		}

		await confirmation(expectedCount: 0) { confirmation in
			await withTaskGroup(of: Void.self) { group in
				for _ in 0..<100 {
					group.addTask {
						await doSomethingOnce(confirmation)
					}
				}
			}
		}
	}

	@Test
	func asyncReentrancy() async {
		func doSomethingOnce(_ confirmation: Confirmation) async {
			func reentrant() async {
				await #once {
					await reentrant()
					confirmation()
				}
			}

			await reentrant()
		}

		await confirmation(expectedCount: 1) { confirmation in
			await doSomethingOnce(confirmation)
			await doSomethingOnce(confirmation)
			await doSomethingOnce(confirmation)
		}

		await confirmation(expectedCount: 0) { confirmation in
			await doSomethingOnce(confirmation)
		}
	}

	@Test
	func asyncConcurrentReentrancy() async {
		func doSomethingOnce(_ confirmation: Confirmation) async {
			func reentrant() async {
				await #once {
					await reentrant()
					confirmation()
				}
			}

			await reentrant()
		}

		await confirmation(expectedCount: 1) { confirmation in
			await withTaskGroup(of: Void.self) { group in
				for _ in 0..<100 {
					group.addTask {
						await doSomethingOnce(confirmation)
					}
				}
			}
		}

		await confirmation(expectedCount: 0) { confirmation in
			await withTaskGroup(of: Void.self) { group in
				for _ in 0..<100 {
					group.addTask {
						await doSomethingOnce(confirmation)
					}
				}
			}
		}
	}

	@Test
	func asyncThrowing() async throws {
		func throwingFunction() async throws {}

		func doSomethingOnce(_ confirmation: Confirmation) async throws {
			try await #once {
				try await throwingFunction()
				confirmation()
			}
		}

		try await confirmation(expectedCount: 1) { confirmation in
			try await doSomethingOnce(confirmation)
			try await doSomethingOnce(confirmation)
			try await doSomethingOnce(confirmation)
		}

		try await confirmation(expectedCount: 0) { confirmation in
			try await doSomethingOnce(confirmation)
		}
	}

	@Test
	func asyncConcurrentThrowing() async throws {
		func throwingFunction() async throws {}

		func doSomethingOnce(_ confirmation: Confirmation) async throws {
			try await #once {
				try await throwingFunction()
				confirmation()
			}
		}

		try await confirmation(expectedCount: 1) { confirmation in
			try await withThrowingTaskGroup(of: Void.self) { group in
				for _ in 0..<100 {
					group.addTask {
						try await doSomethingOnce(confirmation)
					}
				}
				try await group.waitForAll()
			}
		}

		try await confirmation(expectedCount: 0) { confirmation in
			try await withThrowingTaskGroup(of: Void.self) { group in
				for _ in 0..<100 {
					group.addTask {
						try await doSomethingOnce(confirmation)
					}
				}
				try await group.waitForAll()
			}
		}
	}

	@Test
	func asyncMultiple() async throws {
		func throwingFunction() async throws {}

		func doSomethingOnceThrowing(_ confirmation: Confirmation) async throws {
			try await #once {
				try await throwingFunction()
				confirmation()
			}
		}

		func doSomethingOnce(_ confirmation: Confirmation) async {
			await #once {
				await Task.yield()
				confirmation()
			}
		}

		try await confirmation(expectedCount: 2) { confirmation in
			await doSomethingOnce(confirmation)
			try await doSomethingOnceThrowing(confirmation)
		}

		try await confirmation(expectedCount: 0) { confirmation in
			await doSomethingOnce(confirmation)
			try await doSomethingOnceThrowing(confirmation)
		}
	}

	@Test
	func asyncConcurrentMultiple() async throws {
		func throwingFunction() async throws {}

		func doSomethingOnceThrowing(_ confirmation: Confirmation) async throws {
			try await #once {
				try await throwingFunction()
				confirmation()
			}
		}

		func doSomethingOnce(_ confirmation: Confirmation) async {
			await #once {
				await Task.yield()
				confirmation()
			}
		}

		try await confirmation(expectedCount: 2) { confirmation in
			try await withThrowingTaskGroup(of: Void.self) { group in
				for _ in 0..<100 {
					group.addTask {
						await doSomethingOnce(confirmation)
					}
					group.addTask {
						try await doSomethingOnceThrowing(confirmation)
					}
				}
				try await group.waitForAll()
			}
		}

		try await confirmation(expectedCount: 0) { confirmation in
			try await withThrowingTaskGroup(of: Void.self) { group in
				for _ in 0..<100 {
					group.addTask {
						await doSomethingOnce(confirmation)
					}
					group.addTask {
						try await doSomethingOnceThrowing(confirmation)
					}
				}
				try await group.waitForAll()
			}
		}
	}
}
