import Foundation

extension Reducer {
  /// Creates a reducer that will transform the specified action (`case`) into another action (`embed`).
  ///
  /// Typically, this will allow for redirection of actions from parent into a child
  ///
  ///     parentReducer
  ///       .resending(ParentAction.fooClient, to: { ParentAction.child1(.fooClient($0)) })
  ///       .resending(ParentAction.fooClient, to: { ParentAction.child2(.fooClient($0)) })
  ///
  ///
  /// - Parameters:
  ///   - case: The original action
  ///   - to: The destination action
  /// - Returns: The modified reducer
  public func resending<Value>(
    _ case: @escaping (Value) -> Action,
    to embed: @escaping (Value) -> Action
  ) -> Self {
    .combine(
      self,
      .init { state, action, _ in
        if let value = CasePath.case(`case`).extract(from: action) {
          return Effect(value: embed(value))
        } else {
          return .none
        }
      }
    )
  }
  
  /// Combines the current reducer with another one according to environment function
  /// Allows for dynamic combining.
  /// For example, we can condition the application of a reducer to a specific configuration
  ///
  ///      let fullReducer = partialReducer
  ///       .combined { $0.includeAnalytics ? analyticsReducer : .empty }
  ///
  /// - Parameter fromEnvironment: A function which may return a reducer to combine with
  /// - Returns: A single reducer.
  public func combined(with fromEnvironment: @escaping (Environment) -> Reducer) -> Reducer {
    Self { value, action, environment in
      self.combined(with: fromEnvironment(environment))(&value, action, environment)
    }
  }
}

extension Reducer {
  
  /// Creates a reducer that will perform work when a specific part of the state is altered.
  ///
  /// The main way to perfom work in TCA is to send a new action that the reducer will interpret
  /// to modify state & maybe trigger a new action via an effect.
  ///
  /// However, sometimes it makes more sense for a change of some piece of state
  /// to trigger a new action :
  /// instead of triggering this new action at all points where the state if altered
  /// in the reducer at the risk of forgetting one, we directly watch the interesting
  /// substate using this modifier
  ///
  /// - Parameters:
  ///   - value: Extracts the part of state that we want to watch for changes
  ///   - isEqual: Condition to trigger the `onChange` closure
  ///   - onChange: Performs work on the state and returns an effect based on current and previous
  ///   values of the substate.
  ///   Can be seen as a mini reducer where we react to a state change instead of an action
  /// - Returns: A reducer that will call `onChange` when the piece of state returned by `value`
  /// is altered by itself
  public func onChange<Value>(
    of value: @escaping (State) -> Value,
    isEqual: @escaping (Value, Value) -> Bool,
    _ onChange: @escaping (
      _ initial: Value,
      _ current: Value,
      inout State,
      Environment
    ) -> Effect<Action, Never>
  ) -> Reducer<State, Action, Environment> {
    var initialValue: Value!
    
    return .combine(
      Reducer { state, _, _ in
        initialValue = value(state)
        return .none
      },
      self,
      Reducer { state, _, environment in
        let currentValue = value(state)
        
        guard !isEqual(currentValue, initialValue) else {
          return .none
        }
        
        return onChange(initialValue, currentValue, &state, environment)
      }
    )
  }
  
  /// Simplified version of `onChange(of:isEqual:_:)` where the substate is `Equatable`
  public func onChange<Value: Equatable>(
    of value: @escaping (State) -> Value,
    _ onChange: @escaping (
      _ initial: Value,
      _ current: Value,
      inout State,
      Environment
    ) -> Effect<Action, Never>
  ) -> Reducer<State, Action, Environment> {
    self.onChange(of: value, isEqual: ==, onChange)
  }
}


