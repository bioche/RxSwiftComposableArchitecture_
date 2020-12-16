import Foundation
import RxSwift

extension Store {
  /// Subscribes to updates when a store containing optional state goes from `nil` to non-`nil` or
  /// non-`nil` to `nil`.
  ///
  /// This is useful for handling navigation in UIKit. The state for a screen that you want to
  /// navigate to can be held as an optional value in the parent, and when that value switches
  /// from `nil` to non-`nil` you want to trigger a navigation and hand the detail view a `Store`
  /// whose domain has been scoped to just that feature:
  ///
  ///     class MasterViewController: UIViewController {
  ///       let store: Store<MasterState, MasterAction>
  ///       let disposeBag = DisposeBag()
  ///       ...
  ///       func viewDidLoad() {
  ///         ...
  ///         self.store
  ///           .scope(state: \.optionalDetail, action: MasterAction.detail)
  ///           .ifLet(
  ///             then: { [weak self] detailStore in
  ///               self?.navigationController?.pushViewController(
  ///                 DetailViewController(store: detailStore),
  ///                 animated: true
  ///               )
  ///             },
  ///             else: { [weak self] in
  ///               guard let self = self else { return }
  ///               self.navigationController?.popToViewController(self, animated: true)
  ///             }
  ///           )
  ///           .disposed(by: disposeBag)
  ///       }
  ///     }
  ///
  /// - Parameters:
  ///   - unwrap: A function that is called with a store of non-optional state whenever the store's
  ///     optional state goes from `nil` to non-`nil`.
  ///   - else: A function that is called whenever the store's optional state goes from non-`nil` to
  ///     `nil`.
  /// - Returns: A Disposable associated with the underlying subscription.
  public func ifLet<Wrapped>(
    then unwrap: @escaping (Store<Wrapped, Action>) -> Void,
    else: @escaping () -> Void
  ) -> Disposable where State == Wrapped? {
    
    let elseDisposable = self
      .scope(
        state: { (state: Observable<Wrapped?>) in
          state
            .distinctUntilChanged { ($0 != nil) == ($1 != nil) }
        }
      )
      .subscribe(onNext: { store in
        if store.state == nil { `else`() }
      })
  
    let thenDisposable = scope { (state: Observable<Wrapped?>) in
      state
        .distinctUntilChanged { ($0 != nil) == ($1 != nil) }
        .compactMap { $0 }
    }
    .subscribe(onNext: unwrap)
    
    return Disposables.create([thenDisposable, elseDisposable])
  }
  
  /// An overload of `ifLet(then:else:)` for the times that you do not want to handle the `else`
  /// case.
  ///
  /// - Parameter unwrap: A function that is called with a store of non-optional state whenever the
  ///   store's optional state goes from `nil` to non-`nil`.
  /// - Returns: A Disposable associated with the underlying subscription.
  public func ifLet<Wrapped>(
    then unwrap: @escaping (Store<Wrapped, Action>) -> Void
  ) -> Disposable where State == Wrapped? {
    ifLet(then: unwrap, else: {})
  }
  
  /// Variant of ifLet useful to perform push/pop or present/dismiss navigation operations between UIKit controllers.
  ///  Once the state becomes non-`nil`, `unwrap` gets called with store of unwrapped state and returns a result.
  ///  When the state goes back to being `nil`, `else` gets called with the previously produced result.
  ///  The result is captured by the closures and is only released after `else` is called or the subscription is disposed.
  ///
  /// - Parameters:
  ///   - unwrap: A function that is called with a store of non-optional state whenever the store's optional state goes from `nil` to non-`nil`. It returns a result that will be given to the `else` closure as soon as the store's optional state becomes `nil` again.
  ///   - else: A function that is called whenever the store's optional state goes from non-`nil` to `nil`.
  ///   It takes as parameter the result returned by `unwrap` when the state got populated.
  ///   It is not called before a result has been produced aka before the state has been non-`nil`.
  /// - Returns: A Disposable associated with the underlying subscription.
  public func onceAvailable<Wrapped, Result>(
    _ unwrap: @escaping (Store<Wrapped, Action>) -> Result,
    thenWhenNil else: @escaping (Result) -> Void
  ) -> Disposable where State == Wrapped? {
    var result: Result?
    return ifLet(then: {
      result = unwrap($0)
    }, else: {
      guard let unwrappedResult = result else {
        return
      }
      `else`(unwrappedResult)
      result = nil
    })
  }
}
