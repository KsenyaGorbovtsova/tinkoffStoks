//
//  ViewController.swift
//  Stoks
//
//  Created by Gorbovtsova Ksenya on 28.08.2020.
//  Copyright © 2020 Tinkoff. All rights reserved.
//

import UIKit


final class ViewController: UIViewController{
    @IBOutlet weak var companyLogo: UIImageView!
    
    @IBOutlet weak var priceChangeLabel: UILabel!
    @IBOutlet weak var priceLabel: UILabel!
    @IBOutlet weak var companySymbolLabel: UILabel!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var companyPickerView: UIPickerView!
    @IBOutlet weak var CompanyNameLabel: UILabel!
    
    private lazy var companies = [String:String]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(patternImage: UIImage(named: "background")!)
        self.requestStocks()
    
        companyPickerView.dataSource = self
        companyPickerView.delegate = self
        activityIndicator.color = .yellow
        activityIndicator.startAnimating()
        activityIndicator.hidesWhenStopped = true
    }
    
    private func requestImage(for symbol: String) {
    
        let token = "pk_d1b72adb3cec4786907c2b87293a5f95"
        guard let requestUrl = URL(string: "https://cloud.iexapis.com/stable/stock/\(symbol)/logo?token=\(token)") else {
            return
        }
        let dataTask = URLSession.shared.dataTask(with: requestUrl) {[weak self] (data, response, error) in
                   if let data = data,
                   (response as? HTTPURLResponse)?.statusCode == 200,
                       error == nil {
                    self?.parseImageURL(from: data)
                   } else {
                    self?.callAlert(alert: "Please check your connection and retry")
                       print("Network error!")
                   }
               }
               dataTask.resume()
        
    }
    
    private func requestQuote(for symbol: String) {
        let token = "pk_d1b72adb3cec4786907c2b87293a5f95"
        guard let url = URL(string: "https://cloud.iexapis.com/stable/stock/\(symbol)/quote?token=\(token)") else {
            return
        }
        let dataTask = URLSession.shared.dataTask(with: url) {[weak self] (data, response, error) in
            if let data = data,
            (response as? HTTPURLResponse)?.statusCode == 200,
                error == nil {
                self?.parseQuote(from: data)
            } else {
                self?.callAlert(alert: "Please check your connection and retry")
                print("Network error!")
            }
        }
        dataTask.resume()
    }
    
    private func parseImageURL(from data: Data) {
        // MARK: Changed to Swift Codable for parsing
               let decoder = JSONDecoder()
               do{
                let logoURL = try decoder.decode(Logo.self, from: data)
                    self.companyLogo.downloadImage(from: URL(string: logoURL.url)! )
            
               } catch {
                    self.callAlert(alert: "Some problems with data. Try again later.")
                    print("JSON parsing error: " + error.localizedDescription)
                }
    }
    
    private func parseQuote(from data: Data){
        // MARK: Changed to Swift Codable for parsing
        let decoder = JSONDecoder()
        do{
            let companyInfo = try decoder.decode(Company.self, from: data)
           
            DispatchQueue.main.async { [weak self] in
                self?.displayStockInfo(companyName: companyInfo.companyName,
                                       companySymbol: companyInfo.symbol,
                                       price: companyInfo.latestPrice,
                                       priceChange: companyInfo.change)
            }
        } catch {
            self.callAlert(alert: "Some problems with data. Try again later.")
            print("JSON parsing error: " + error.localizedDescription)
        
        }
    }
    
    private func displayStockInfo(companyName: String,
                                  companySymbol: String,
                                  price: Double,
                                  priceChange: Double) {
        activityIndicator.stopAnimating()
        CompanyNameLabel.text = companyName
        companySymbolLabel.text = companySymbol
        priceLabel.text = "\(price)"
        priceChangeLabel.text = "\(priceChange)"
        priceChangeLabel.textColor = (priceChange == 0) ? UIColor.white : (priceChange > 0) ? UIColor.green  : UIColor.red  }
    
    private func requestQuoteUpdate() {
        
        activityIndicator.startAnimating()
        CompanyNameLabel.text = "-"
        companySymbolLabel.text = "-"
        priceLabel.text = "-"
        priceChangeLabel.text = "-"
        priceChangeLabel.textColor = .white
        
        self.callAlert(alert: "Please check your connection and retry")
        
        let selectedRow = companyPickerView.selectedRow(inComponent: 0)
        let selectedSymbol = Array(companies.values)[selectedRow]
        requestQuote(for: selectedSymbol)
        requestImage(for: selectedSymbol)
    }
    
    private func requestStocks() {
        let token = "pk_d1b72adb3cec4786907c2b87293a5f95"
        let url = URL(string: "https://cloud.iexapis.com/stable/stock/market/list/mostactive?token=\(token)")!
        
        let dataTask = URLSession.shared.dataTask(with: url) { data, response, error in
            guard
                error == nil,
                (response as? HTTPURLResponse)?.statusCode == 200,
                let data = data
                else {
                    self.callAlert(alert: "Please check your connection and retry")
                    print("Network error!")
                    return
            }
            self.parseStocks(data: data)
        }
        
        dataTask.resume()
    }
    
    private func parseStocks(data: Data) {
        // MARK: Changed to Swift Codable for parsing
        let decoder = JSONDecoder()
        
        do {
            let companiesInfo = try decoder.decode([Company].self, from: data)
           
             DispatchQueue.main.async {
                for company in companiesInfo {
                    self.companies[company.companyName] = company.symbol
                }
                self.companyPickerView.reloadAllComponents();
                self.requestQuoteUpdate()
            }
            
        } catch {
            self.callAlert(alert: "Some problems with data. Try again later.")
            print("JSON parsing error: " + error.localizedDescription)
        }
    }

}




extension ViewController: UIPickerViewDataSource {
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return companies.keys.count
    }
    
    
}

extension ViewController: UIPickerViewDelegate {
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        
        requestQuoteUpdate()
    }
    
    func pickerView(_ pickerView: UIPickerView, attributedTitleForRow row: Int, forComponent component: Int) -> NSAttributedString? {
        return NSAttributedString(string: Array(companies.keys)[row], attributes: [NSAttributedString.Key.foregroundColor: UIColor.yellow])
    }
}

extension UIImageView {
   func getData(from url: URL, completion: @escaping (Data?, URLResponse?, Error?) -> ()) {
      URLSession.shared.dataTask(with: url, completionHandler: completion).resume()
   }
   func downloadImage(from url: URL) {
      getData(from: url) {
         data, response, error in
         guard let data = data, error == nil else {
            return
         }
         DispatchQueue.main.async() {
            self.image = UIImage(data: data)
         }
      }
   }
}

extension ViewController {
    
    func callAlert(alert: String){
        if !isInternetAvailable() {
                  let alert = UIAlertController(title: "Problem detected", message: alert, preferredStyle: .alert)
                  let action = UIAlertAction(title: "Retry", style: .default, handler: repeatAttempt)
                  alert.addAction(action)
            DispatchQueue.main.async{
                self.present(alert, animated: true, completion: nil)
            }
              }
    }

    func repeatAttempt (alert: UIAlertAction) {
        requestStocks()
    }
}
