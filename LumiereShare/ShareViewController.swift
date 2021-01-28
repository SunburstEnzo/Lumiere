//
//  ShareViewController.swift
//  LumiereShare
//
//  Created by Aled Samuel on 26/01/2021.
//

import UIKit
import Social

import ComposableRequest
import ComposableRequestCrypto
import Swiftagram

final class ShareViewController: UIViewController {
	
	
	private let activityIndicator: UIActivityIndicatorView = {
		
		let activityIndicator = UIActivityIndicatorView(style: .large)
		activityIndicator.color = .label
		activityIndicator.sizeToFit()
		return activityIndicator
	}()
	
	private let emptyLabel: UILabel = {
		
		let label = UILabel()
		label.text = NSLocalizedString("\n\n", comment: "")
		label.textAlignment = .center
		label.font = .systemFont(ofSize: 28, weight: .semibold)
		label.textColor = .tertiaryLabel
		label.numberOfLines = 0
		label.sizeToFit()
		return label
	}()
	
	private var secret: Secret?
	
//	private static var secret: Secret? {
//
//		return ComposableRequestCrypto.KeychainStorage<Secret>(service: "com.aledsamuel.lumiere").all().first
//	}
	
	private var url: URL?
	
	
	// MARK: Init
	
	init(url: URL?) {
		
		self.url = url
		
		super.init(nibName: nil, bundle: nil)
	}
	
	
	required init?(coder: NSCoder) {
		fatalError("init(coder:) is not supported")
	}
	
	
	// MARK: View lifecycle
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		title = "Lumiere"
		
		view.backgroundColor = .systemBackground
		
		let closeButton = UIBarButtonItem(barButtonSystemItem: .stop, target: self, action: #selector(handleDismissButton(_:)))
		navigationItem.rightBarButtonItem = closeButton
		
		secret = ComposableRequestCrypto.KeychainStorage<Secret>(service: "com.aledsamuel.lumiere").all().first
		
		activityIndicator.startAnimating()
		view.addSubview(activityIndicator)
		
		emptyLabel.isHidden = true
		view.addSubview(emptyLabel)
	}
	
	
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		
		if let url = url {
			
			findInstagramContent(using: url)
		}
		else {
			
			guard let userInfo = extensionContext?.inputItems as? [NSExtensionItem],
				  !userInfo.isEmpty else {
				
				return loadingDidEnd(with: "Failed to get URL")
			}
			
			for item in userInfo {
				
				if let itemProviders = item.attachments {
					
					for itemProvider in itemProviders {
						
						if itemProvider.hasItemConformingToTypeIdentifier("public.url") {
							
							itemProvider.loadItem(forTypeIdentifier: "public.url", options: nil) { [weak self] (item, error) in
								
								guard let publicURL = item as? URL else {
									
									self?.loadingDidEnd(with: "public.url not a URL")
									return
								}
								
								if let error = error {
									
									self?.loadingDidEnd(with: error.localizedDescription)
									return
								}
								
								self?.findInstagramContent(using: publicURL)
							}
						}
						else {
							
							loadingDidEnd(with: "public.url not found")
						}
					}
				}
				else {
					
					loadingDidEnd(with: "Invalid inputItems")
				}
			}
		}
	}
	
	
	// MARK: Layout
	
	override func viewDidLayoutSubviews() {
		super.viewDidLayoutSubviews()
		
		let padding: CGFloat = 16
		
		emptyLabel.frame = CGRect(x: padding, y: view.bounds.height.half - emptyLabel.bounds.height.half, width: view.bounds.width - padding.twice, height: emptyLabel.bounds.height)
		
		activityIndicator.center = CGPoint(x: view.bounds.width.half, y: view.bounds.height.half)
	}
	
	
	// MARK: Instagram
	
	private func findInstagramContent(using url: URL) {
		
		let absoluteString = url.absoluteString.trimmingCharacters(in: .whitespacesAndNewlines)
		
		guard absoluteString != "" else { return loadingDidEnd(with: "Empty URL") }
		
		if absoluteString.contains("/p/") || absoluteString.contains("/reel/") || absoluteString.contains("/tv/") {
			
			/// Media post
			
			guard let mediaID = instagramDeepLinkFromHTTPLink(absoluteString) else {
				
				return loadingDidEnd(with: "Media ID fetch failed")
			}
			
			guard let secret = secret else {
				
				return loadingDidEnd(with: "Please log in using the Lumiere app")
			}
			
			DispatchQueue.main.async { [weak self] in
				
				self?.loadingDidEnd()
				
				let mediaViewController = MediaViewController(secret: secret, mediaID: mediaID)
				self?.navigationController?.pushViewController(mediaViewController, animated: false)
			}
		}
		else {
			
			loadingDidEnd(with: "Not a valid Instagram post")
		}
	}
	
	
	private func loadingDidEnd(with message: String? = nil) {
		
		DispatchQueue.main.async { [weak self] in
			
			self?.emptyLabel.text = message
			self?.emptyLabel.isHidden = false
			
			self?.activityIndicator.stopAnimating()
			self?.activityIndicator.isHidden = true
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
	
	@objc private func handleDismissButton(_ sender: UIBarButtonItem) {
		
		if let extensionContext = extensionContext {
			
			extensionContext.completeRequest(returningItems: nil, completionHandler: nil)
		}
		else {
			
			dismiss(animated: true, completion: nil)
		}
	}
}
