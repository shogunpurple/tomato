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
    static let POMODORO = 60 * 25
    static let REST = 60 * 5
    static let LONG_REST = 60 * 15
}

struct PomodoroViewModel {
    var pomodoroState: PomodoroState
    var nextPomodoroState: PomodoroState
    var numPomodoros: Int
    var secondsLeft: Int
    var finishTimestamp: Int?
    var started: Bool
    
    init() {
        pomodoroState = .pomodoro
        nextPomodoroState = .rest
        numPomodoros = 0
        secondsLeft = TimePeriod.POMODORO
        finishTimestamp = nil
        started = false
    }
    
    mutating func updatePomodoroState() -> Void {
        switch pomodoroState {
            case .pomodoro:
                // Timer 25 minutes
                secondsLeft = numPomodoros == 3 ? TimePeriod.LONG_REST : TimePeriod.REST
                pomodoroState = numPomodoros == 3 ? .longRest : .rest
                nextPomodoroState = .pomodoro
                break
            case .rest:
                // Timer 5 minutes
                numPomodoros += 1
                secondsLeft = TimePeriod.POMODORO
                pomodoroState = .pomodoro
                nextPomodoroState = numPomodoros == 3 ? .longRest : .rest
                break
            case .longRest:
                numPomodoros = 0
                // Timer 15 minutes
                secondsLeft = TimePeriod.POMODORO
                pomodoroState = .pomodoro
                nextPomodoroState = .rest
            }
        }
}


