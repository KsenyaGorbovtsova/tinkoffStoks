//
//  companiesList.swift
//  Stoks
//
//  Created by Gorbovtsova Ksenya on 28.08.2020.
//  Copyright © 2020 Tinkoff. All rights reserved.
//
import Foundation

struct Company: Codable {
    let companyName: String
    let symbol: String
    let latestPrice: Double
    let change: Double
}

