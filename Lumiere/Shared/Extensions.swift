//
//  Extensions.swift
//  Lumiere
//
//  Created by Aled Samuel on 27/01/2021.
//

import UIKit


extension Array {
	
	/// The second element of the collection.
	///
	/// If the collection is empty, the value of this property is `nil`.
	///
	///     let numbers = [10, 20, 30, 40, 50]
	///     if let secondNumber = numbers.second {
	///         print(secondNumber)
	///     }
	///     // Prints "20"
	var second: Element? {
		
		if count > 2 {
			
			return self[1]
		}
		
		return nil
	}
	
	
	var isNotEmpty: Bool {
		
		return !isEmpty
	}
}


extension CGFloat {
	
	
	var half: CGFloat {
		
		return self * 0.5
	}
	
	
	var twice: CGFloat {
		
		return self * 2
	}
}
