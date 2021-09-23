//
//  LoginViewController.swift
//  Lumiere
//
//  Created by Aled Samuel on 25/01/2021.
//

import UIKit
import WebKit

import ComposableRequestCrypto
import Swiftagram
import SwiftagramCrypto

final class LoginViewController: UIViewController {
	
	
	var completion: ((Secret) -> Void)?
	
	var webView: WKWebView? {
		
		didSet {
			
			guard let webView = webView else { return }
			webView.frame = view.bounds
			view.addSubview(webView)
		}
	}
	
	
	// MARK: View lifecycle
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		WebViewAuthenticator(storage: KeychainStorage<Secret>(service: "com.aledsamuel.lumiereapp")) {
			
			self.webView = $0
			
		}.authenticate { [weak self] result in
			
			switch result {
			case .failure(let error):
				
				print(error.localizedDescription)
				
			case .success(let secret):
				
				self?.dismiss(animated: true, completion: { [weak self] in
					
					self?.completion?(secret)
				})
			}
		}
	}
	
	
	// MARK: Layout
	
	override func viewDidLayoutSubviews() {
		super.viewDidLayoutSubviews()
		
		webView?.frame = view.bounds
	}
}
