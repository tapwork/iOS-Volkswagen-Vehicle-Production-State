//
//  ViewController.swift
//  VWConnectAPI
//
//  Created by Christian Menschel on 11.04.21.
//

import UIKit
import Combine

class ViewController: UIViewController {

    var subscriptions = [AnyCancellable]()
    lazy var stackView = UIStackView()
    lazy var loadingIndicator = UIActivityIndicatorView(style: .large)


    override func viewDidLoad() {
        super.viewDidLoad()
        view.addSubview(loadingIndicator)
        loadingIndicator.hidesWhenStopped = true
        loadingIndicator.center = view.center
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        load()
        NotificationCenter.default.addObserver(forName: UIApplication.willEnterForegroundNotification, object: nil, queue: nil) { (notification) in
            self.load()
        }
    }

    func load() {
        loadingIndicator.startAnimating()
        let webViewController = WebViewController(target: .login)
        present(webViewController, animated: true, completion: nil)
        webViewController
            .tokenHandler
            .flatMap(fetchVehicleState)
            .sink { (error) in
                print(error)
                self.loadingIndicator.stopAnimating()
            } receiveValue: { states in
                self.createLabels(for: states)
            }
            .store(in: &subscriptions)
    }

    func createLabels(for states: [VehicleState]) {
        stackView.axis = .vertical
        stackView.spacing = 10
        stackView.arrangedSubviews.forEach { (view) in
            view.removeFromSuperview()
            stackView.removeArrangedSubview(view)
        }
        states.forEach { (state) in
            stackView.addArrangedSubview(createLabel(title: "brand", text: state.brand))
            stackView.addArrangedSubview(createLabel(title: "Name", text: state.name))
            stackView.addArrangedSubview(createLabel(title: "vin", text: state.vin ?? "n.a."))
            stackView.addArrangedSubview(createLabel(title: "commissionNumber", text: state.commissionNumber))
            stackView.addArrangedSubview(createLabel(title: "checkpointNumber", text: state.checkpointNumber))
            stackView.addArrangedSubview(createLabel(title: "detailStatus", text: state.detailStatus))
            stackView.addArrangedSubview(createLabel(title: "orderStatus", text: state.orderStatus))
            stackView.addArrangedSubview(createLabel(title: "deliveryDate", text: state.deliveryDateLocalized))
            stackView.addArrangedSubview(createLabel(title: "orderDate", text: state.orderDateLocalized))
            stackView.addArrangedSubview(createLabel(title: "modelCode", text: state.modelCode))
            stackView.addArrangedSubview(createLabel(title: "modelYear", text: state.modelYear))
        }
        view.addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            stackView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
        ])
        stackView.layoutMargins = UIEdgeInsets(top: 10, left: 20, bottom: 20, right: 20)
        stackView.isLayoutMarginsRelativeArrangement = true
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

    func fetchVehicleState(_ token: String) -> AnyPublisher<[VehicleState], Error> {
        URLSession.shared.dataTaskPublisher(for: URLTarget.state.request(accessToken: token))
            .map {$0.data}
            .decode(type: [VehicleState].self, decoder: JSONDecoder.shared)
            .receive(on: RunLoop.main)
            .eraseToAnyPublisher()
    }
}
