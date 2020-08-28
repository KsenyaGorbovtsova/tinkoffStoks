//
//  ViewController.swift
//  Stoks
//
//  Created by Gorbovtsova Ksenya on 28.08.2020.
//  Copyright © 2020 Tinkoff. All rights reserved.
//

import UIKit

final class ViewController: UIViewController{

    @IBOutlet weak var priceChangeLabel: UILabel!
    @IBOutlet weak var priceLabel: UILabel!
    @IBOutlet weak var companySymbolLabel: UILabel!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var companyPickerView: UIPickerView!
    @IBOutlet weak var CompanyNameLabel: UILabel!
    
    private lazy var companies = [
        "Apple" : "AAPL",
        "Microsoft": "MSFT",
        "Google": "GOOG",
        "Amazon": "AMZN",
        "Facebook" : "FB"
    ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        companyPickerView.dataSource = self
        companyPickerView.delegate = self
        activityIndicator.startAnimating()
        activityIndicator.hidesWhenStopped = true
        requestQuoteUpdate()
    }
    
    private func requestQuote(for symbol: String) {
        let token = "pk_d1b72adb3cec4786907c2b87293a5f95 "
        guard let url = URL(string: "https://cloud.iexapis.com/stable/stock/\(symbol)/quote?token=\(token)") else {
            return
        }
        let dataTask = URLSession.shared.dataTask(with: url) {[weak self] (data, response, error) in
            if let data = data,
            (response as? HTTPURLResponse)?.statusCode == 200,
                error == nil {
                self?.parseQuote(from: data)
            } else {
                print("Network error!")
            }
        }
        dataTask.resume()
    }
    
    private func parseQuote(from data: Data){
        do{
            let jsonObject = try JSONSerialization.jsonObject(with: data)
            guard
                let json = jsonObject as? [String : Any],
                let companyName = json["companyName"] as? String,
                let companySymbol = json["symbol"] as? String,
                let price = json["latestPrice"] as? Double,
                let priceChange = json["change"] as? Double
            else {
                    return print("Invalid JSON")
                    }
            print( "Company name is " + companyName)
        } catch {
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
        priceLabel.text = "\(priceChangeLabel)"
        priceChangeLabel.text = "\(priceChange)"
    }
    
    private func requestQuoteUpdate() {
        
        activityIndicator.startAnimating()
        CompanyNameLabel.text = "-"
        companySymbolLabel.text = "-"
        priceLabel.text = "-"
        priceChangeLabel.text = "-"
        
        let selectedRow = companyPickerView.selectedRow(inComponent: 0)
        let selectedSymbol = Array(companies.values)[selectedRow]
        requestQuote(for: selectedSymbol)
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
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return Array(companies.keys)[row]
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        
        requestQuoteUpdate()
    }
}


