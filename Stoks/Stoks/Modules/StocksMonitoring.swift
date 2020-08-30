//
//  StocksMonitoring.swift
//  Stocks
//
//  Created by Gorbovtsova Ksenya on 28.08.2020.
//  Copyright © 2020 Tinkoff. All rights reserved.
//
import UIKit

protocol  StocksMonitoringProtocol: AnyObject {
    func callAlert(alert: String)
    func parseStocks(data: Data)
    func parseQuote(from data: Data)
    func parseImageURL(from data: Data)
}

final class StocksMonitoring: UIViewController, StocksMonitoringProtocol {

    // MARK: Private data structures
    
    private enum Constants {
        static let numberOfComponents = 1
        static let defaultPlaceHolder = "-"
        static let token = "pk_d1b72adb3cec4786907c2b87293a5f95"
    }
    // MARK: Outlets
    
    @IBOutlet weak var companyLogo: UIImageView!
    @IBOutlet weak var priceChangeLabel: UILabel!
    @IBOutlet weak var priceLabel: UILabel!
    @IBOutlet weak var companySymbolLabel: UILabel!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var companyPickerView: UIPickerView!
    @IBOutlet weak var CompanyNameLabel: UILabel!
    
    // MARK: Private properties
    
    private lazy var companies = [String:String]()
    private var companiesArray = [String]()
    private var delegate: NetworkDelegate?
    
    // MARK: Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        delegate = NetworkService(delegate: self)
        view.backgroundColor = UIColor(patternImage: UIImage(named: "background")!)
        delegate?.requestStocks()
        
        companyPickerView.dataSource = self
        companyPickerView.delegate = self
        activityIndicator.color = .yellow
        activityIndicator.startAnimating()
        activityIndicator.hidesWhenStopped = true
    }
    
    // MARK: Private methods
    
    private func displayStockInfo(companyName: String,
                                  companySymbol: String,
                                  price: Double,
                                  priceChange: Double) {
        activityIndicator.stopAnimating()
        CompanyNameLabel.text = companyName
        companySymbolLabel.text = companySymbol
        priceLabel.text = "\(price)"
        priceChangeLabel.text = "\(priceChange)"
        priceChangeLabel.textColor = (priceChange == 0) ? UIColor.white : (priceChange > 0) ? UIColor.green  : UIColor.red
    }
    private func requestQuoteUpdate() {
        
        activityIndicator.startAnimating()
        CompanyNameLabel.text = Constants.defaultPlaceHolder
        companySymbolLabel.text = Constants.defaultPlaceHolder
        priceLabel.text = Constants.defaultPlaceHolder
        priceChangeLabel.text = Constants.defaultPlaceHolder
        priceChangeLabel.textColor = .white
        
        self.callAlert(alert: "Please check your connection and retry")
        
        let selectedRow = companyPickerView.selectedRow(inComponent: 0)
        let selectedSymbol = Array(companies.values)[selectedRow]
        delegate?.requestQuote(for: selectedSymbol)
        delegate?.requestImage(for: selectedSymbol)
    }
   
    internal func parseStocks(data: Data) {
        // MARK: Changed to Swift Codable for parsing
        let decoder = JSONDecoder()
        
        do {
            let companiesInfo = try decoder.decode([Company].self, from: data)
           
             DispatchQueue.main.async {
                for company in companiesInfo {
                    self.companies[company.companyName] = company.symbol
                    self.companiesArray.append(company.companyName)
                }
                self.companiesArray.sort()
                self.companyPickerView.reloadAllComponents()
                self.requestQuoteUpdate()
            }
            
        } catch {
            self.callAlert(alert: "Some problems with data. Try again later.")
            print("JSON parsing error: " + error.localizedDescription)
        }
    }
    
    
    internal func parseImageURL(from data: Data) {
        // MARK: Changed to Swift Codable for parsing
        let decoder = JSONDecoder()
        do {
            let logoURL = try decoder.decode(Logo.self, from: data)
            self.companyLogo.downloadImage(from: URL(string: logoURL.url)!)
        } catch {
            self.callAlert(alert: "Some problems with data. Try again later.")
            print("JSON parsing error: " + error.localizedDescription)
        }
    }
    
    internal func parseQuote(from data: Data){
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
}

extension StocksMonitoring: UIPickerViewDataSource {
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return Constants.numberOfComponents
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return companies.keys.count
    }
}

extension StocksMonitoring: UIPickerViewDelegate {
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        self.requestQuoteUpdate()
    }
    
    func pickerView(_ pickerView: UIPickerView, attributedTitleForRow row: Int, forComponent component: Int) -> NSAttributedString? {
        return NSAttributedString(string: companiesArray[row], attributes: [NSAttributedString.Key.foregroundColor: UIColor.yellow])
    }
}

extension StocksMonitoring {
    
     func callAlert(alert: String) {
        if let isAvailable = delegate?.isInternetAvailable(), isAvailable == false {
                  let alert = UIAlertController(title: "Problem detected", message: alert, preferredStyle: .alert)
                  let action = UIAlertAction(title: "Retry", style: .default, handler: repeatAttempt)
                  alert.addAction(action)
            DispatchQueue.main.async {
                self.present(alert, animated: true, completion: nil)
            }
        }
    }

    private func repeatAttempt (alert: UIAlertAction) {
        delegate?.requestStocks()
    }
}
