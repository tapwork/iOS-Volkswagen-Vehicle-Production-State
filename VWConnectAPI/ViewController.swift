//
//  ViewController.swift
//  VWConnectAPI
//
//  Created by Christian Menschel on 11.04.21.
//

import UIKit
import Combine
import BackgroundTasks

class ViewController: UIViewController {
    let backgroundFetchIdentifier = "de.tapwork.vwconnectapi.backgroundrefresh"
    var subscriptions = [AnyCancellable]()
    lazy var scrollView = UIScrollView()
    lazy var stackView = UIStackView()
    lazy var loadingIndicator = UIActivityIndicatorView(style: .large)
    lazy var refreshButton = UIButton()
    var refreshTask: BGAppRefreshTask?

    // MARK: View Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()

        setupScrollView()
        setupStackView()
        setupLoadingIndicator()
        setupRefreshButton()

        load()
        NotificationCenter.default.addObserver(forName: UIApplication.willEnterForegroundNotification, object: nil, queue: nil) { (notification) in
            self.load()
        }
        NotificationCenter.default.addObserver(forName: UIApplication.didEnterBackgroundNotification, object: nil, queue: nil) { (notification) in
            self.scheduleBackgroundRefresher()
        }
        registerBackgroundRefresher()
    }

    private func setupScrollView() {
        view.addSubview(scrollView)
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func setupStackView() {
        stackView.axis = .vertical
        stackView.spacing = 10
        stackView.alignment = .fill
        stackView.distribution = .equalSpacing
        scrollView.addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor),
            stackView.topAnchor.constraint(equalTo: scrollView.topAnchor),
            stackView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor),
            stackView.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
        ])
        stackView.layoutMargins = UIEdgeInsets(top: 10, left: 20, bottom: 20, right: 20)
        stackView.isLayoutMarginsRelativeArrangement = true
    }

    private func setupLoadingIndicator() {
        view.addSubview(loadingIndicator)
        loadingIndicator.hidesWhenStopped = true
        loadingIndicator.center = view.center
    }

    private func setupRefreshButton() {
        view.addSubview(refreshButton)
        refreshButton.translatesAutoresizingMaskIntoConstraints = false
        refreshButton.setTitle("Reload", for: .normal)
        refreshButton.backgroundColor = UIColor.systemFill
        refreshButton.layer.cornerRadius = 8.0
        refreshButton.setTitleColor(UIColor.darkText, for: .normal)
        NSLayoutConstraint.activate([
            refreshButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -10),
            refreshButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            refreshButton.widthAnchor.constraint(equalToConstant: 150)
        ])
        refreshButton.addTarget(self, action: #selector(refresh), for: .primaryActionTriggered)
    }

    func createLabel(title: String, text: String) -> UIStackView {
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.font = .systemFont(ofSize: 14, weight: .bold)

        let textLabel = UILabel()
        textLabel.text = text
        textLabel.font = .systemFont(ofSize: 14)
        textLabel.numberOfLines = 0
        textLabel.translatesAutoresizingMaskIntoConstraints = false

        let stackView = UIStackView(arrangedSubviews: [titleLabel, textLabel])
        stackView.spacing = 5
        stackView.axis = .vertical
        stackView.translatesAutoresizingMaskIntoConstraints = false

        return stackView
    }

    func createSpacer() -> UIView {
        let view = UIView()
        view.heightAnchor.constraint(equalToConstant: 40).isActive = true
        return view
    }

    func createContentViews(for states: [VehicleState]) {
        stackView.arrangedSubviews.forEach { (view) in
            view.removeFromSuperview()
            stackView.removeArrangedSubview(view)
        }
        states.forEach { (state) in
            stackView.addArrangedSubview(createLabel(title: "Brand", text: state.brand))
            stackView.addArrangedSubview(createLabel(title: "Name", text: state.name))
            stackView.addArrangedSubview(createLabel(title: "VIN", text: state.vin ?? "n.a."))
            stackView.addArrangedSubview(createLabel(title: "Commission Number", text: state.commissionNumber))
            stackView.addArrangedSubview(createLabel(title: "Checkpoint Number", text: state.checkpointNumber))
            stackView.addArrangedSubview(createLabel(title: "Detail Status", text: state.detailStatus))
            stackView.addArrangedSubview(createLabel(title: "Order Status", text: state.orderStatus))
            stackView.addArrangedSubview(createLabel(title: "Delivery Date", text: state.deliveryDateLocalized))
            stackView.addArrangedSubview(createLabel(title: "Order Date", text: state.orderDateLocalized))
            stackView.addArrangedSubview(createLabel(title: "Model Code", text: state.modelCode))
            stackView.addArrangedSubview(createLabel(title: "Model Year", text: state.modelYear))
            stackView.addArrangedSubview(createSpacer())
        }
    }

    // MARK: Loading
    @objc func refresh() {
        load()
    }

    func load() {
        loadingIndicator.startAnimating()
        let webViewController = WebViewController(target: .login)
        webViewController.modalPresentationStyle = .fullScreen
        present(webViewController, animated: true, completion: nil)
        webViewController
            .tokenHandler
            .flatMap(fetchVehicleState)
            .sink { result in
                var success = true
                switch result {
                case .finished: break
                case .failure: success = false
                }
                self.loadingIndicator.stopAnimating()
                self.refreshTask?.setTaskCompleted(success: success)
            } receiveValue: { states in
                self.createContentViews(for: states)
            }
            .store(in: &subscriptions)
    }

    func fetchVehicleState(_ token: String) -> AnyPublisher<[VehicleState], Error> {
        URLSession.shared.dataTaskPublisher(for: URLTarget.state.request(accessToken: token))
            .map {$0.data}
            .decode(type: [VehicleState].self, decoder: JSONDecoder.shared)
            .receive(on: RunLoop.main)
            .map(sort)
            .map(checkForLocalNotification)
            .tryMap { try $0.store() }
            .eraseToAnyPublisher()
    }

    func sort(_ states: [VehicleState]) -> [VehicleState] {
        states.sorted(by: {$0.commissionNumber < $1.commissionNumber})
    }

    func checkForLocalNotification(_ newStates: [VehicleState]) -> [VehicleState] {
        guard let stored = try? [VehicleState].self.load() else {
            return newStates
        }
        if stored != newStates {
            triggerLocalNotification()
        }

        return newStates
    }

    func triggerLocalNotification() {
        let content = UNMutableNotificationContent()
        content.title = "New status"
        content.body = "The production status of your vehicle has changed. Check now!"
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1, repeats: false)
        let request = UNNotificationRequest(identifier: Date().description, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request) {
            if let error = $0 {
                 print(error)
            }
        }
    }

    func registerBackgroundRefresher() {
        BGTaskScheduler.shared.register(forTaskWithIdentifier: backgroundFetchIdentifier, using: nil) { (task) in
            self.handleAppRefreshTask(task: task as! BGAppRefreshTask)
        }
    }

    func scheduleBackgroundRefresher() {
        let task = BGAppRefreshTaskRequest(identifier: backgroundFetchIdentifier)
        task.earliestBeginDate = Date(timeIntervalSinceNow: 60)
        do {
          try BGTaskScheduler.shared.submit(task)
        } catch {
          print("Unable to submit task: \(error.localizedDescription)")
        }
    }

    func handleAppRefreshTask(task: BGAppRefreshTask) {
        task.expirationHandler = {
            URLSession.shared.invalidateAndCancel()
        }
        refreshTask = task
        load()
    }
}
