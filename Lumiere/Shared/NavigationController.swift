//
//  NavigationController.swift
//  Lumiere
//
//  Created by Aled Samuel on 26/01/2021.
//

import UIKit

final class NavigationController: UINavigationController {
	
	
	// MARK: Init
	
	override init(rootViewController: UIViewController) {
		super.init(rootViewController: rootViewController)
		
		setupAppearance()
	}
	
	
	override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
		super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
		
		setupAppearance()
	}
	
	
	required init?(coder aDecoder: NSCoder) {
		super.init(coder: aDecoder)
		
		setupAppearance()
	}
	
	
	private func setupAppearance() {
		
		navigationBar.prefersLargeTitles = true
		
		navigationBar.tintColor = #colorLiteral(red: 0.9607843137, green: 0.631372549, blue: 0.2588235294, alpha: 1)
		
		let standardAppearance = UINavigationBarAppearance()
		let scrollEdgeAppearance = UINavigationBarAppearance()
		
		standardAppearance.configureWithOpaqueBackground()
		scrollEdgeAppearance.configureWithTransparentBackground()	/// Eliminates the nav bar shadow for large titles (iOS 13 style)
		
		standardAppearance.titleTextAttributes = [.foregroundColor: UIColor(patternImage: #imageLiteral(resourceName: "GradientImage"))]
		scrollEdgeAppearance.titleTextAttributes = [.foregroundColor: UIColor(patternImage: #imageLiteral(resourceName: "GradientImage"))]
		
		standardAppearance.largeTitleTextAttributes = [.foregroundColor: UIColor(patternImage: #imageLiteral(resourceName: "GradientImage"))]
		scrollEdgeAppearance.largeTitleTextAttributes = [.foregroundColor: UIColor(patternImage: #imageLiteral(resourceName: "GradientImage"))]
		
		let backButtonAppearance = UIBarButtonItemAppearance()
		backButtonAppearance.normal.titleTextAttributes = [.foregroundColor: UIColor(patternImage: #imageLiteral(resourceName: "GradientImage"))]
		
		standardAppearance.backButtonAppearance = backButtonAppearance
		scrollEdgeAppearance.backButtonAppearance = backButtonAppearance
		
		navigationBar.standardAppearance = standardAppearance
		navigationBar.scrollEdgeAppearance = scrollEdgeAppearance
	}
}
