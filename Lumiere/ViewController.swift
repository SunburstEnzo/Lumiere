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
	
	
	private var secret: Secret?
	
	private var currentUser: User?
	
	
	// MARK: View lifecycle
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		
	}
	
	
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		
		findUser()
	}
	
	
	private func findUser() {
		
		if let secret = KeychainStorage<Secret>(service: "com.aledsamuel.lumiere").all().first {
			
			self.secret = secret
			
			self.currentUser = UserDefaults.standard
				.data(forKey: secret.identifier)
				.flatMap { try? JSONDecoder().decode(User.self, from: $0) }
			
			guard let link = instagramDeepLinkFromHTTPLink("CKg54_Ch4HE") else { return }
			
			Endpoint.Media.summary(for: link)
				.unlocking(with: secret)
				.task { (result) in
					
					switch result {
					case .success(let media):
						
						if let content = media.media?.first?.content {
							
							switch content {
							case .picture(let picture):
								
								if let url = picture.images?.first?.url {
									
									print(url)
								}
								
							case .album(let album):
								
								for item in album {
									
									switch item {
									case .picture(let picture):
										
										if let url = picture.images?.first?.url {
											
											print(url)
										}
										
									default:
										break
									}
								}
								
							default:
								break
							}
						}
						
						break
						
					case .failure(let error):
						
						print(error.localizedDescription)
					}
				}
				.resume()
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
}
