//
//  TimerListViewController.swift
//  UIKitCaseStudiesiOS12
//
//  Created by Bioche on 01/08/2020.
//  Copyright © 2020 Point-Free. All rights reserved.
//

import UIKit

import ComposableArchitecture
import RxSwift

struct TimerState: Equatable, TCAIdentifiable {
  let id: String
  var time: Double
}

enum TimerAction {
  case playPause
}

struct TimerListState: Equatable {
  var timers: [TimerState]
  
  static var initial: Self {
    .init(timers: [])
  }
}

enum TimerListAction {
  case addCountdown
  case playPause(timerId: String)
}

let timerListReducer = Reducer<TimerListState, TimerListAction, Void> {
  state, action, _  in
  switch action {
  case .addCountdown:
    let newTimerId = UUID().uuidString
    state.timers.append(.init(id: newTimerId, time: 10))
    return Effect(value: .playPause(timerId: newTimerId))
  case .playPause(timerId: let timerId):
    break
  }
  return .none
}

class TimerCell: UITableViewCell {
  struct ViewState: Equatable {
    let timeText: String
  }
  typealias ViewAction = TimerAction
  
  @IBOutlet private weak var timeLabel: UILabel!
  
  var viewStore: ViewStore<ViewState, ViewAction>!
  var disposeBag = DisposeBag()
  
  func configure(viewStore: ViewStore<ViewState, ViewAction>) {
    self.viewStore = viewStore
    
    viewStore.driver.timeText.drive(onNext: { [weak self] in
      self?.timeLabel.text = $0
    })
    .disposed(by: disposeBag)
  }
  
  override func prepareForReuse() {
    super.prepareForReuse()
    disposeBag = DisposeBag()
  }
}

class TimerListViewController: UIViewController {
  
  enum ViewAction {
    case addCountdownTapped
  }
  
  static func create(store: Store<TimerListState, TimerListAction>) -> Self {
    guard let controller = UIStoryboard(name: "Main", bundle: .main)
      .instantiateViewController(withIdentifier: "timerList") as? Self else {
        fatalError()
    }
    
    controller.store = store
    controller.viewStore = ViewStore(store.stateless.scope(state: { $0 }, action: { .fromView($0) }), removeDuplicates: { _, _ in false })
    return controller
  }
  
  @IBOutlet private weak var addCountdownButton: UIButton!
  @IBOutlet private weak var tableView: UITableView!
  
  let disposeBag = DisposeBag()
  
  var store: Store<TimerListState, TimerListAction>!
  var viewStore: ViewStore<Void, ViewAction>!
  
  override func viewDidLoad() {
    super.viewDidLoad()
    
    addCountdownButton.rx.tap.subscribe(onNext: { [weak self] in
      self?.viewStore.send(.addCountdownTapped)
    })
    .disposed(by: disposeBag)
    
    let datasource = RxFlatStoreTableDataSource<TimerState, TimerAction>(cellCreation: { tableView, indexPath, store in
      guard let cell = tableView.dequeueReusableCell(withIdentifier: "timer") as? TimerCell else {
        fatalError()
      }
      cell.configure(viewStore: ViewStore(store.scope(state: { $0.view }, action: { $0 })))
      return cell
    })
    
    store
      .scope(state: { $0.timers }, action: { id, _ in .playPause(timerId: id) })
      .bind(tableView: tableView!, to: datasource)
      .disposed(by: disposeBag)
  }
  
  
}

extension TimerListAction {
  static func fromView(_ viewAction: TimerListViewController.ViewAction) -> Self {
    switch viewAction {
    case .addCountdownTapped:
      return .addCountdown
    }
  }
}

extension TimerState {
  var view: TimerCell.ViewState {
    let seconds = Int(time)
    let centiseconds = Int((time - Double(seconds)) * 100)
    let string = String(format: "%d:%02d", seconds, centiseconds)
    return .init(timeText: string)
  }
}
