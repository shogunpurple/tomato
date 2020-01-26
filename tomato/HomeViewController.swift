//
//  HomeViewController.swift
//  tomato
//
//  Created by Martin McKeaveney on 02/01/2020.
//  Copyright © 2020 Shogun Systems. All rights reserved.
//

import UIKit


class HomeViewController: UIViewController {
    
    
    @IBOutlet weak var pomodoroStateIcon: UIImageView!
    @IBOutlet weak var startStopButton: UIButton!
    @IBOutlet weak var pomodoroStateLabel: UILabel!
    @IBOutlet weak var nextPomodoroStateLabel: UILabel!
    @IBOutlet weak var numPomodorosLabel: UILabel!
    @IBOutlet weak var minuteLabel: UILabel!
    @IBOutlet weak var secondLabel: UILabel!

    private var viewModel: PomodoroViewModel = PomodoroViewModel()
    
    var timer: Timer? = nil

    override func viewDidLoad() {
        // Do any additional setup after loading the view.
        super.viewDidLoad()

        // Create notification center
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
        
        updateView(with: viewModel)
    }
    
    func updateView(with state: PomodoroViewModel) {
        // Update time left
        let minutes = state.secondsLeft / 60
        let seconds = state.secondsLeft % 60
        minuteLabel.text = String(minutes)
        secondLabel.text = String(seconds)
        
        // Update pomodoro state
        pomodoroStateLabel.text = "\(state.pomodoroState.rawValue)."
        nextPomodoroStateLabel.text = state.nextPomodoroState.rawValue
        numPomodorosLabel.text = (state.numPomodoros + 1).asWord.capitalized
        pomodoroStateIcon.image = UIImage(named: "\(state.pomodoroState.rawValue).png")
        
        // Update stop and start buttons
        let buttonType = viewModel.started ? "Pause" : "Play"
        startStopButton.setBackgroundImage(UIImage(named: "\(buttonType)Button.png"), for: UIControl.State.normal)
    }
    
    @objc func storeAppState() {
        print("Application Resign Active")
        viewModel.finishTimestamp = Int(NSDate().timeIntervalSince1970) + viewModel.secondsLeft

        // Stop the timer
        invalidateTimer()
    }
    
    @objc func restoreAppState() {
        print("Application Foreground Active")

        guard viewModel.finishTimestamp != nil || viewModel.started else { return }

        // Remaining time left in timer
        let remaining = viewModel.finishTimestamp! - Int(NSDate().timeIntervalSince1970)
        
        viewModel.secondsLeft = remaining <= 0 ? 0 : remaining

        updateView(with: viewModel)

        createTimer()
    }

    func scheduleTimerFinishedNotification() {
        // Create Notification Content
        let content = UNMutableNotificationContent()
        content.title = "\(viewModel.pomodoroState.rawValue) Finished!"
        content.body = ""
        content.sound = UNNotificationSound.default
        
        // Create the trigger
        let date = Date(timeIntervalSinceNow: Double(viewModel.secondsLeft))
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
        let alert = UIAlertController(title: "\(viewModel.pomodoroState.rawValue) Finished!", message: "", preferredStyle: .alert)
        let okAction = UIAlertAction(title: "OK", style: .default) { action in
            self.dismiss(animated: true, completion: nil)
        }
        alert.addAction(okAction)
        present(alert, animated: true, completion: nil)
    }
    
    func createTimer() {
        // Stop the current timer
        invalidateTimer()
        
        // Update the buttons
        viewModel.started = true
        updateView(with: self.viewModel)
        
        scheduleTimerFinishedNotification()
        
        // Start the timer
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            print("Timer fired!")
            self.viewModel.secondsLeft -= 1
            if self.viewModel.secondsLeft <= 0 {
                self.showAlert()
                self.stopTimerActions()
                self.viewModel.updatePomodoroState()
                self.viewModel.started = false
            }
            self.updateView(with: self.viewModel)
        }
    }

    func invalidateTimer() -> Void {
        timer?.invalidate()
        timer = nil
    }
    
    func stopTimerActions() {
        invalidateTimer()
        // Prevent the timer notification being fired when the timer is stopped
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["pomodoroTimer"])
    }
    
    @IBAction func startTimer(_ sender: UIButton) {
        if viewModel.started {
            stopTimerActions()
            viewModel.started = false
            updateView(with: viewModel)
        } else {
            createTimer()
        }
    }
}

public extension Int {
  var asWord: String {
    let numberValue = NSNumber(value: self)
    let formatter = NumberFormatter()
    formatter.numberStyle = .spellOut
    return formatter.string(from: numberValue)!
  }
}
