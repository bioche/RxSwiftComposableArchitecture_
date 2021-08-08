#if canImport(Combine)
import Combine

@available(iOS 13, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
extension Store {
  /// Calls one of two closures depending on whether a store's optional state is `nil` or not, and
  /// whenever this condition changes for as long as the cancellable lives.
  ///
  /// If the store's state is non-`nil`, it will safely unwrap the value and bundle it into a new
  /// store of non-optional state that is passed to the first closure. If the store's state is
  /// `nil`, the second closure is called instead.
  ///
  /// This method is useful for handling navigation in UIKit. The state for a screen the user wants
  /// to navigate to can be held as an optional value in the parent, and when that value goes from
  /// `nil` to non-`nil`, or non-`nil` to `nil`, you can update the navigation stack accordingly:
  ///
  ///     class ParentViewController: UIViewController {
  ///       let store: Store<ParentState, ParentAction>
  ///       var cancellables: Set<AnyCancellable> = []
  ///       ...
  ///       func viewDidLoad() {
  ///         ...
  ///         self.store
  ///           .scope(state: \.optionalChild, action: ParentAction.child)
  ///           .ifLet(
  ///             then: { [weak self] childStore in
  ///               self?.navigationController?.pushViewController(
  ///                 ChildViewController(store: childStore),
  ///                 animated: true
  ///               )
  ///             },
  ///             else: { [weak self] in
  ///               guard let self = self else { return }
  ///               self.navigationController?.popToViewController(self, animated: true)
  ///             }
  ///           )
  ///           .store(in: &self.cancellables)
  ///       }
  ///     }
  ///
  /// - Parameters:
  ///   - unwrap: A function that is called with a store of non-optional state when the store's
  ///     state is non-`nil`, or whenever it goes from `nil` to non-`nil`.
  ///   - else: A function that is called when the store's optional state is `nil`, or whenever it
  ///     goes from non-`nil` to `nil`.
  /// - Returns: A cancellable that maintains a subscription to updates whenever the store's state
  ///   goes from `nil` to non-`nil` and vice versa, so that the caller can react to these changes.
  public func ifLet<Wrapped>(
    then unwrap: @escaping (Store<Wrapped, Action>) -> Void,
    else: @escaping () -> Void = {}
  ) -> Cancellable where State == Wrapped? {
    ifLet(then: unwrap, else: `else`)
      .asCancellable()
  }
  
  /// An overload of `ifLet(then:else:)` for the times that you do not want to handle the `else`
  /// case.
  ///
  /// - Parameter unwrap: A function that is called with a store of non-optional state whenever the
  ///   store's optional state goes from `nil` to non-`nil`.
  /// - Returns: A Cancellable associated with the underlying subscription.
  public func ifLet<Wrapped>(
    then unwrap: @escaping (Store<Wrapped, Action>) -> Void
  ) -> Cancellable where State == Wrapped? {
    ifLet(then: unwrap, else: {})
  }
  
  /// Similar to `ifLet(then:else:)` where we add a condition on the wrapped state for `unwrap` to
  /// be called. When the state is `nil` or `condition` is not met, `else` gets called.
  ///
  /// - Parameters:
  ///   - condition: An extra condition on the wrapped state that needs to be true for `unwrap`
  ///    to be called
  ///   - unwrap: A function that is called with a store of non-optional state whenever the store's
  ///     optional state goes from `nil` to non-`nil` or `condition(state)` goes from `false` to
  ///     `true`
  ///   - else: A function that is called whenever the store's optional state goes from non-`nil` to
  ///     `nil` or `condition(state)` goes from `true` to `false`.
  /// - Returns: A Cancellable associated with the underlying subscription.
  public func ifLet<Wrapped>(
    and condition: @escaping (Wrapped) -> Bool,
    then unwrap: @escaping (Store<Wrapped, Action>) -> Void,
    else: @escaping () -> Void
  ) -> Cancellable where State == Wrapped? {
    ifLet(and: condition, then: unwrap, else: `else`)
      .asCancellable()
  }
  
  /// An overload of `ifLet(condition:then:else:)` for the times that you do not want to handle
  /// the `else` case.
  ///
  public func ifLet<Wrapped>(
      and condition: @escaping (Wrapped) -> Bool,
      then unwrap: @escaping (Store<Wrapped, Action>) -> Void
  ) -> Cancellable where State == Wrapped? {
    ifLet(and: condition, then: unwrap, else: {})
  }
}

/// An extension for onceAvailable variants
@available(iOS 13, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
extension Store {
  
  /// Variant of ifLet useful to perform push/pop or present/dismiss navigation operations
  /// between UIKit controllers. Once the state becomes non-`nil`, `unwrap` gets called with store
  /// of unwrapped state and returns a result. After that when the state goes back to being `nil`,
  /// `else` gets called with the previously produced result. The result is captured by the closures
  /// and is only released after `else` is called or the subscription is disposed.
  ///
  ///      store.scope(state: { $0.welcome },
  ///                  action: { .welcome($0) })
  ///      .onceAvailable({ [weak router] store -> Presentable in
  ///          let presentable = presentableFactory.buildWelcomePresentable(store: store)
  ///          router?.push(presentable: presentable, displayBackButton: false)
  ///          return presentable
  ///      }, thenWhenNil: { [weak router] in
  ///          router?.pop(presentable: $0, options: .init())
  ///      })
  ///      .store(in: &self.cancellables)
  ///
  /// - Parameters:
  ///   - unwrap: A function that is called with a store of non-optional state whenever the store's
  ///   optional state goes from `nil` to non-`nil`. It returns a result that will be given to the
  ///   `else` closure as soon as the store's optional state becomes `nil` again.
  ///   - else: A function that is called whenever the store's optional state goes from non-`nil`
  ///   to `nil`. It takes as parameter the result returned by `unwrap` when the state got populated.
  ///   It is not called before a result has been produced aka before the state has been non-`nil`.
  /// - Returns: A Disposable associated with the underlying subscription.
  public func onceAvailable<Wrapped, Result>(
    _ unwrap: @escaping (Store<Wrapped, Action>) -> Result,
    thenWhenNil else: @escaping (Result) -> Void
  ) -> Cancellable where State == Wrapped? {
    onceAvailable(unwrap, thenWhenNil: `else`)
      .asCancellable()
  }
  
  /// Variant of ifLet to perform push/pop or present/dismiss navigation operations between
  /// UIKit controllers. Useful when the optional substate's reducer needs to perform loading
  /// actions before it's ready to be displayed.
  ///
  /// Its behavior is similar to `onceAvailable(unwrap:thenWhenNil:)` where :
  ///
  /// `unwrap` is called once the state is non-`nil` & meets `condition`
  ///
  /// `else` is called once the state is `nil` again or `condition` is not met anymore.
  ///
  ///     selectionStore.onceAvailable(
  ///         and: { $0.informationDisplayed },
  ///         then: { [weak router] store in
  ///             router?.present(
  ///               presentable: presentableFactory.buildDislikedFoodInfo(store: store),
  ///               onDismiss: { store.send(.information(.modalDismissal)) }
  ///             )
  ///         },
  ///         else: { [weak router] in
  ///             router?.dismissPresented(onCompletion: nil)
  ///         }
  ///     )
  ///     .store(in: &self.cancellables)
  ///
  /// - Parameters:
  ///   - condition: The condition to be met in addition to state being non-`nil`
  ///   - unwrap: A function that is called with a store of non-optional state whenever the store's
  ///   optional state goes from `nil` to non-`nil` & `condition` is met. It returns a result that
  ///   will be given to the `else` closure as soon as the store's optional state becomes `nil`
  ///   again or `condition` is not met anymore.
  ///   - else: A function that is called whenever the store's optional state goes from non-`nil`
  ///   to `nil` or `condition(state)` goes from `true` to `false`.
  ///   It takes as parameter the result returned by `unwrap` when the state got populated.
  ///   It is not called before a result has been produced aka before the state has been non-`nil`
  ///   & `condition(state)` has been true.
  /// - Returns: A Disposable associated with the underlying subscription.
  public func onceAvailable<Wrapped, Result>(
    and condition: @escaping (Wrapped) -> Bool,
    then unwrap: @escaping (Store<Wrapped, Action>) -> Result,
    else: @escaping (Result) -> Void
  ) -> Cancellable where State == Wrapped? {
    onceAvailable(and: condition, then: unwrap, else: `else`)
      .asCancellable()
  }
  
  /// Utility method that builds a result once `condition` is met.
  /// Once the state matches `condition`, `buildResult` gets called with `self` and returns
  /// a result. After that, when the state goes back to not matching `condition`,
  /// `else` gets called with the previously produced result.
  /// The result is captured by the closures and is only released after `else` is called or the
  /// subscription is disposed.
  ///
  /// - Parameters:
  ///   - condition: The condition that will trigger the building of result
  ///   - buildResult: A function that is called with current store once its state matches
  ///   `condition`. It returns a result that will be given to the `else` closure as soon as the
  ///   store's state doesn't match condition again.
  ///   - else: A function that is called whenever the store's state stops matching `condition`.
  ///   It takes as parameter the result returned by `buildResult` when the state last
  ///   matched `condition`. It is not called before a result has been produced aka
  ///   before `condition(state) == true`.
  /// - Returns: A Disposable associated with the underlying subscription.
  public func once<Result>(
      _ condition: @escaping (State) -> Bool,
      _ buildResult: @escaping (Store) -> Result,
      thenWhenFalse else: @escaping (Result) -> Void
  ) -> Cancellable {
      scope(state: { condition($0) ? $0 : nil })
        .onceAvailable(buildResult, thenWhenNil: `else`)
  }
  
}
#endif
