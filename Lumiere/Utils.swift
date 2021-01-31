//
//  Utils.swift
//  Lumiere
//
//  Created by Aled Samuel on 31/01/2021.
//

import Foundation

final class Utils {
	
	
	// MARK: Singleton
	
	static var shared = Utils()
	
	
	// MARK: Properties
	
	let byteCountFormatter: ByteCountFormatter = {
		
		let formatter = ByteCountFormatter()
		return formatter
	}()
}
