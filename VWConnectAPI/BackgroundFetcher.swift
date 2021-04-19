//
//  BackgroundFetcher.swift
//  VWConnectAPI
//
//  Created by Christian Menschel on 17.04.21.
//

import UIKit
import BackgroundTasks

class BackgroundFetcher {
    let backgroundFetchIdentifier = "de.tapwork.vwconnectapi.backgroundrefresh"
    static var shared = BackgroundFetcher()

    var update: (() -> Void)? {
        didSet {
            if task != nil {
                update?()
            }
        }
    }
    private var task: BGAppRefreshTask?

    func register() {
        BGTaskScheduler.shared.register(forTaskWithIdentifier: backgroundFetchIdentifier,
                                        using: DispatchQueue.main,
                                        launchHandler: handleAppRefreshTask)

        NotificationCenter.default.addObserver(forName: UIApplication.didEnterBackgroundNotification, object: nil, queue: nil) { (notification) in
            self.scheduleBackgroundRefresher()
        }
    }

    private func scheduleBackgroundRefresher() {
        let task = BGAppRefreshTaskRequest(identifier: backgroundFetchIdentifier)
        task.earliestBeginDate = Date(timeIntervalSinceNow: 60)
        do {
          try BGTaskScheduler.shared.submit(task)
        } catch {
            let message = "Unable to submit task: \(error.localizedDescription)"
            print(message)
        }
    }

    private func handleAppRefreshTask(task: BGTask) {
        guard let bgTask = task as? BGAppRefreshTask else {
            return task.setTaskCompleted(success: false)
        }
        bgTask.expirationHandler = {
            URLSession.shared.invalidateAndCancel()
        }
        self.task = bgTask
        update?()
    }

    func completed(_ success: Bool) {
        task?.setTaskCompleted(success: success)
        task = nil
    }
}
