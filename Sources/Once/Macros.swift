/// A macro that ensures the specified block is only executed once per program run.
@discardableResult
@freestanding(expression)
public macro once<T>(block: () throws -> T) -> T? = #externalMacro(module: "OnceMacroPlugin", type: "OnceMacro")

/// A macro that ensures the specified block is only executed once per program run.
@discardableResult
@freestanding(expression)
public macro once<T>(block: () async throws -> T) -> T? = #externalMacro(module: "OnceMacroPlugin", type: "OnceMacro")
