//
//  ViewController.swift
//  VWConnectAPI
//
//  Created by Christian Menschel on 11.04.21.
//

import UIKit
import WebKit
import Combine

class WebViewController: UIViewController, WKNavigationDelegate, WKUIDelegate {
    var webView: WKWebView!
    var subscriptions = [AnyCancellable]()
    var tokenHandler = PassthroughSubject<String, Error>()
    let target: URLTarget

    init(target: URLTarget) {
        self.target = target
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        let config = WKWebViewConfiguration()
        let userScript = WKUserScript(source: ajaxInjectScript, injectionTime: .atDocumentStart, forMainFrameOnly: false)
        config.userContentController.addUserScript(userScript)
        config.userContentController.add(self, name: "handler")

        webView = WKWebView(frame: .zero, configuration: config)
        view = webView
        webView.navigationDelegate = self
        webView.uiDelegate = self
        webView.load(URLRequest(url: target.url))
    }

    var ajaxInjectScript: String {
        if let filepath = Bundle.main.path(forResource: "ajaxinject", ofType: "js") {
            return (try? String(contentsOfFile: filepath)) ?? ""
        } else {
            print("ajaxinject.js not found!")
        }
        return ""
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        tokenHandler.send(completion: .finished)
    }
}

extension WebViewController: WKScriptMessageHandler {
    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        guard let dict = message.body as? [String: Any],
              let responseURL = dict["responseURL"] as? String,
              let responseText = dict["responseText"] as? String else {
            return
        }

        if responseURL == URLTarget.token.url.absoluteString, let data = responseText.data(using: .utf8) {
            let tokenDict = try? JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: String]
            let token = tokenDict?["access_token"] ?? ""
            if !token.isEmpty {
                tokenHandler.send(token)
                presentingViewController?.dismiss(animated: true, completion: nil)
            }
        }
    }
}

struct WebviewAjax: Codable {
    let responseURL: URL
    let responseText: String
}
