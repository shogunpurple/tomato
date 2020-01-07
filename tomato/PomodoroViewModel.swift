//
//  PomodoroViewModel.swift
//  tomato
//
//  Created by Martin McKeaveney on 07/01/2020.
//  Copyright © 2020 Shogun Systems. All rights reserved.
//

import Foundation

enum PomodoroState: String {
    case pomodoro = "Pomodoro"
    case rest = "Break"
    case longRest = "Long Break"
}

private struct TimePeriod {
    static let POMODORO = 1 * 5
    static let REST = 1 * 5
    static let LONG_REST = 1 * 5
}

struct PomodoroViewModel {
    var pomodoroState: PomodoroState
    var numPomodoros: Int
    var secondsLeft: Int
    var finishTimestamp: Int?
    var started: Bool
    
    init() {
        pomodoroState = .pomodoro
        numPomodoros = 5
        secondsLeft = TimePeriod.POMODORO
        finishTimestamp = nil
        started = false
    }
    
    mutating func updatePomodoroState() -> Void {
        switch pomodoroState {
            case .pomodoro:
                numPomodoros += 1
                // Timer 25 minutes
                secondsLeft = TimePeriod.POMODORO
                pomodoroState = .rest
                break
            case .rest:
                // Timer 5 minutes
                secondsLeft = TimePeriod.REST
                pomodoroState = numPomodoros == 5 ? .longRest : .pomodoro
                break
            case .longRest:
                // Timer 15 minutes
                secondsLeft = TimePeriod.LONG_REST
                pomodoroState = .pomodoro
                numPomodoros = 0
            }
        }

    func startTimer() {
        
    }
    
    func stopTimer() {
        
    }
}
