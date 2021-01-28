//
//  ViewController.swift
//  Lumiere
//
//  Created by Aled Samuel on 25/01/2021.
//

import UIKit
import WebKit
import SDWebImage

import ComposableRequest
import ComposableRequestCrypto
import Swiftagram

final class ViewController: UIViewController {
	
	
	@IBOutlet weak var pasteClipboardButton: UIButton!
	
	@IBOutlet weak var textField: UITextField!
	
	@IBOutlet weak var searchButton: UIButton!
	
	private var secret: Secret? {
		
		didSet {
			
			navigationItem.rightBarButtonItem?.menu = createMoreMenu()
		}
	}
	
	private var currentUser: User?
	
	
	// MARK: View lifecycle
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		title = "Lumiere"
		
		view.backgroundColor = .systemBackground
		
		navigationController?.navigationBar.prefersLargeTitles = true
		
		let moreButton = UIBarButtonItem(title: nil, image: UIImage(systemName: "ellipsis.circle"), primaryAction: nil, menu: createMoreMenu())
		navigationItem.rightBarButtonItem = moreButton
		
		textField.addTarget(self, action: #selector(handleTextFieldReturn(_:)), for: .editingDidEndOnExit)
		
		pasteClipboardButton.setTitleColor(UIColor.systemBlue.withAlphaComponent(0.8), for: .normal)
		
		searchButton.setTitleColor(.systemBackground, for: .normal)
		searchButton.backgroundColor = UIColor(patternImage: #imageLiteral(resourceName: "GradientImage"))
		searchButton.layer.cornerRadius = 6
		
		let backgroundTap = UITapGestureRecognizer(target: self, action: #selector(handleBackgroundTap(_:)))
		view.addGestureRecognizer(backgroundTap)
	}
	
	
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		
		findUser()
	}
	
	
	// MARK: Instagram
	
	private func findUser() {
		
		if let secret = KeychainStorage<Secret>(service: "com.aledsamuel.lumiere").all().first {
			
			self.secret = secret
			
			print("Secret found: \(self.secret != nil)")
			
			Endpoint.User.summary(for: secret.identifier)
				.unlocking(with: secret)
				.task { [weak self] (result) in
					
					switch result {
					case .success(let user):
						
						self?.currentUser = user.user
						
						print("User found: \(self?.currentUser != nil)")
						
					case .failure(let error):
						
						print("Failed to find user, error: \(error.localizedDescription)")
					}
					
				}.resume()
		}
		else {
			
			let loginViewController = LoginViewController()
			
			loginViewController.completion = { [weak self] in
				
				self?.secret = $0
				self?.findUser()
			}
			
			present(loginViewController, animated: true, completion: nil)
		}
	}
	
	
	private func instagramDeepLinkFromHTTPLink(_ link: String) -> String? {
		
		/// Swift code written by SamB at https://stackoverflow.com/a/50788526/1241153
		
		guard let linkURL = URL(string: link) else { return nil }
		
		let shortcode = linkURL.lastPathComponent
		
		let alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_"
		var mediaId = 0
		
		for char in shortcode {
			
			guard let index = alphabet.firstIndex(of: char) else { continue }
			
			mediaId = (mediaId * 64) + index.utf16Offset(in: alphabet)
		}
		
		return String(mediaId)
	}
	
	
	// MARK: Handlers
	
	@IBAction func handlePasteClipboardAction(_ sender: UIButton) {
		
		textField.text = UIPasteboard.general.string
	}
	
	
	@objc private func handleTextFieldReturn(_ sender: UITextField) {
		
		textField.resignFirstResponder()
		
		guard let text = sender.text,
			  let url = URL(string: text) else { return }
		
		let shareViewController = ShareViewController(url: url)
		present(NavigationController(rootViewController: shareViewController), animated: true, completion: nil)
	}
	
	
	@IBAction func handleSearchButton(_ sender: UIButton) {
		
		handleTextFieldReturn(textField)
	}
	
	
	@objc private func handleBackgroundTap(_ sender: UIGestureRecognizer) {
		
		textField.resignFirstResponder()
	}
	
	
	private func createMoreMenu() -> UIMenu {
		 
		let aboutAction = UIAction(title: NSLocalizedString("About", comment: ""), image: UIImage(systemName: "info.circle")) { [weak self] _ in
			
			/// About
			
			let versionString = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "N/A"
			let buildString = (Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "N/A")
			
			let message = versionString + " (" + buildString + ")"
			
			let alert = UIAlertController(title: NSLocalizedString("About", comment: ""), message: message, preferredStyle: .alert)
			
			alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
			
			self?.present(alert, animated: true, completion: nil)
		}
		
		let clearCacheAction = UIAction(title: NSLocalizedString("Clear Cache", comment: ""), image: UIImage(systemName: "trash")) { [weak self] _ in
			
			/// Empty Cache
			
			SDImageCache.shared.clearMemory()
			SDImageCache.shared.clearDisk { [weak self] in
				
				let alert = UIAlertController(title: NSLocalizedString("Image Cache Cleared", comment: ""), message: nil, preferredStyle: .alert)
				
				alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
				
				self?.present(alert, animated: true, completion: nil)
			}
		}
		
		let accountAction: UIAction
		
		if secret == nil {
			
			accountAction = UIAction(title: NSLocalizedString("Sign In", comment: ""), image: UIImage(systemName: "person.badge.plus")) { [weak self] _ in
				
				/// Sign In
				
				self?.findUser()
			}
		}
		else {
			
			accountAction = UIAction(title: NSLocalizedString("Sign Out", comment: ""), image: UIImage(systemName: "person.badge.minus")) { [weak self] _ in
				
				/// Sign Out
				
				KeychainStorage<Secret>(service: "com.aledsamuel.lumiere").removeAll()
				
				self?.currentUser = nil
				self?.secret = nil
			}
		}
		
		return UIMenu(title: "", image: nil, identifier: nil, options: .displayInline, children: [aboutAction, clearCacheAction, accountAction])
	}
}
