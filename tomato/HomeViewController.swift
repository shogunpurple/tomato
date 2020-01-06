//
//  HomeViewController.swift
//  tomato
//
//  Created by Martin McKeaveney on 02/01/2020.
//  Copyright © 2020 Shogun Systems. All rights reserved.
//

import UIKit

enum PomodoroState: String {
    case pomodoro = "Pomodoro"
    case rest = "Break"
    case longRest = "Long Break"
}

private struct TimePeriod {
   static let POMODORO = 1 * 30
   static let REST = 1 * 10
   static let LONG_REST = 1 * 30
}

class HomeViewController: UIViewController {
    
    @IBOutlet weak var pomodoroStateLabel: UILabel!
    @IBOutlet weak var minuteLabel: UILabel!
    @IBOutlet weak var secondLabel: UILabel!
    @IBOutlet weak var startButton: UIButton!
    @IBOutlet weak var stopButton: UIButton!
    
    var timer: Timer? = nil
    var pomodoroState: PomodoroState = .pomodoro
    var numPomodoros: Int = 0
    var secondsLeft: Int = 0
    var finishTimestamp: Int? = nil

    override func viewDidLoad() {
        // Do any additional setup after loading the view.
        super.viewDidLoad()
        stopButton.isEnabled = false
        secondsLeft = TimePeriod.POMODORO
        pomodoroStateLabel.text = pomodoroState.rawValue + "."
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound]) { granted, error in
            // Enable or disable features based on authorization.
        }
        // TODO: Better way to do this? It didn't work with UNUserNotificationCenter
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(storeAppState),
            name: UIApplication.willResignActiveNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(restoreAppState),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )
        print("viewDidLoad")
    }
    
    @objc func storeAppState() {
        print("Application Resign Active")
        finishTimestamp = Int(NSDate().timeIntervalSince1970) + secondsLeft

        // Stop the timer
        invalidateTimer()
    }
    
    @objc func restoreAppState() {
        print("Application Foreground Active")
        // TODO: LEARN MORE ABOUT SWIFT OPTIONALS
        if finishTimestamp == nil {
            return
        }
        
        // Remaining time left in timer
        let remaining = finishTimestamp! - Int(NSDate().timeIntervalSince1970)
        
        // TODO: fix to figure out correct time
        secondsLeft = remaining
        self.calculateTimeUnits()
        
        // Start the timer again
        createTimer()
    }

    func scheduleTimerFinishedNotification() {
        // Create Notification Content
        let content = UNMutableNotificationContent()
        content.title = "\(self.pomodoroState.rawValue) Finished!"
        content.body = ""
        
        // Create the trigger
        let date = Date(timeIntervalSinceNow: Double(secondsLeft))
        let triggerDate = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .second], from: date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)
        
        // Wire it all up by creating the Notification Request
        let request = UNNotificationRequest(identifier: "pomodoroTimer", content: content, trigger: trigger)
        
        // Use notification center to schedule the request
        UNUserNotificationCenter.current().add(request) { error in
            if error != nil {
                print("Error when scheduling notification")
            }
        }
    }

    func showAlert() {
        let alert = UIAlertController(title: "\(self.pomodoroState.rawValue) Finished!", message: "", preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default) { action in
            self.dismiss(animated: true, completion: nil)
        }
        alert.addAction(okAction)
        present(alert, animated: true, completion: nil)
    }
    
    func calculateTimeUnits() -> Void {
        let minutes = secondsLeft / 60
        let seconds = secondsLeft % 60
        minuteLabel.text = String(minutes)
        secondLabel.text = String(seconds)
    }
    
    func updatePomodoroState() -> Void {
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
        
        pomodoroStateLabel.text = pomodoroState.rawValue
        calculateTimeUnits()
    }
    
    func createTimer() {
        invalidateTimer()
        scheduleTimerFinishedNotification()
        
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            print("Timer fired!")
            self.secondsLeft -= 1
            if self.secondsLeft < 0 {
                self.showAlert()
                self.stopTimerActions()
                self.updatePomodoroState()
                return
            }
            self.calculateTimeUnits()
        }
    }

    @IBAction func startTimer(_ sender: UIButton) {
        createTimer()
        stopButton.isEnabled = true
        startButton.isEnabled = false
    }
    
    func invalidateTimer() -> Void {
        timer?.invalidate()
        timer = nil
    }
    
    func stopTimerActions() {
        invalidateTimer()
        print("Timer stopped!")
        stopButton.isEnabled = false
        startButton.isEnabled = true
        // Prevent the timer notification being fired when the timer is stopped
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["pomodoroTimer"])
    }

    @IBAction func stopTimer(_ sender: UIButton) -> Void {
        stopTimerActions()
    }
}

