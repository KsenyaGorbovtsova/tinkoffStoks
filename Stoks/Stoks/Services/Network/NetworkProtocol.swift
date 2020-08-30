//
//  NetworkProtocol.swift
//  Stoks
//
//  Created by Gorbovtsova Ksenya on 30.08.2020.
//  Copyright © 2020 Tinkoff. All rights reserved.
//

import Foundation

protocol NetworkDelegate: AnyObject{
    func requestStocks()
    func requestImage(for symbol: String)
    func requestQuote(for symbol: String)
    func isInternetAvailable() -> Bool
}
