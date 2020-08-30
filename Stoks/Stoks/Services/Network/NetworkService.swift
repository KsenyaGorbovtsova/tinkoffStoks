//
//  NetworkService.swift
//  Stoks
//
//  Created by Gorbovtsova Ksenya on 29.08.2020.
//  Copyright © 2020 Tinkoff. All rights reserved.
//
import UIKit
import SystemConfiguration

final class NetworkService: NetworkDelegate {
    
    // MARK: Private properties
    
    private weak var delegate: StocksMonitoringProtocol?
    
    // MARK: Private data structures
    
    private enum Constants {
        static let token = "pk_d1b72adb3cec4786907c2b87293a5f95"
    }
    
    init (delegate: StocksMonitoringProtocol) {
        self.delegate = delegate
    }
  
    
    func requestStocks() {
        guard let url = URL(string: "https://cloud.iexapis.com/stable/stock/market/list/mostactive?token=\(Constants.token)") else {
            delegate?.callAlert(alert: "We've got some erros. Please, try again")
            return
        }
        
        let dataTask = URLSession.shared.dataTask(with: url) { [self] data, response, error in
            guard error == nil,
                  (response as? HTTPURLResponse)?.statusCode == 200,
                  let data = data else {
                    delegate?.callAlert(alert: "Please check your connection and retry")
                    print("Network error!")
                    return
            }
            delegate?.parseStocks(data: data)
        }
        dataTask.resume()
    }
    
    func requestImage(for symbol: String) {
        guard let requestUrl = URL(string: "https://cloud.iexapis.com/stable/stock/\(symbol)/logo?token=\(Constants.token)") else {
            delegate?.callAlert(alert: "We've got some erros. Please, try again")
            return
        }
        let dataTask = URLSession.shared.dataTask(with: requestUrl) { [weak self] (data, response, error) in
            if let data = data,
               (response as? HTTPURLResponse)?.statusCode == 200,
               error == nil {
                self?.delegate?.parseImageURL(from: data)
                } else {
                    self?.delegate?.callAlert(alert: "Please check your connection and retry")
                    print("Network error!")
                }
            }
        dataTask.resume()
    }
    
    func requestQuote(for symbol: String) {
        guard let url = URL(string: "https://cloud.iexapis.com/stable/stock/\(symbol)/quote?token=\(Constants.token)") else {
            delegate?.callAlert(alert: "We've got some erros. Please, try again")
            return
        }
        let dataTask = URLSession.shared.dataTask(with: url) {[weak self] (data, response, error) in
            if let data = data,
               (response as? HTTPURLResponse)?.statusCode == 200,
                error == nil {
                self?.delegate?.parseQuote(from: data)
            } else {
                self?.delegate?.callAlert(alert: "Please check your connection and retry")
                    print("Network error!")
            }
        }
        dataTask.resume()
    }
    
    
    internal func isInternetAvailable() -> Bool {
        var zeroAddress = sockaddr_in()
        zeroAddress.sin_len = UInt8(MemoryLayout.size(ofValue: zeroAddress))
        zeroAddress.sin_family = sa_family_t(AF_INET)
           
        let defaultRouteReachability = withUnsafePointer(to: &zeroAddress) {
               $0.withMemoryRebound(to: sockaddr.self, capacity: 1) { zeroSockAddress in
                   SCNetworkReachabilityCreateWithAddress(nil, zeroSockAddress)
            }
        }
           
        var flags = SCNetworkReachabilityFlags()
        if !SCNetworkReachabilityGetFlags(defaultRouteReachability!, &flags) {
            return false
        }
        let isReachable = flags.contains(.reachable)
        let needsConnection = flags.contains(.connectionRequired)
        return (isReachable && !needsConnection)
    }
}


