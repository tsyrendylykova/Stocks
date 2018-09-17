//
//  ViewController.swift
//  Stocks
//
//  Created by Цырендылыкова Эржена on 11.09.2018.
//  Copyright © 2018 Tinkoff. All rights reserved.
//

import UIKit

class ViewController: UIViewController, UIPickerViewDataSource, UIPickerViewDelegate {
    
    // MARK: - IBOutlets
    
    @IBOutlet weak var companyPickerView: UIPickerView!
    @IBOutlet weak var companyNameLabel: UILabel!
    @IBOutlet weak var companySymbolLabel: UILabel!
    @IBOutlet weak var priceLabel: UILabel!
    @IBOutlet weak var priceChangeLabel: UILabel!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var logoImage: UIImageView!
    
    // MARK: - View lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.companyPickerView.dataSource = self
        self.companyPickerView.delegate = self
        
        self.activityIndicator.hidesWhenStopped = true
        
        self.requestSymbols()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - private properties
    
    private var companies: [String: String] = [:]

    // MARK: - UIPickerViewDataSource
    
    func numberOfComponents(in pickerView: UIPickerView) ->Int {
        return 1;
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return self.companies.keys.count
    }
    
    // MARK: - UIPickerViewDelegate
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return Array(self.companies.keys)[row]
    }
    
    // MARK: - Private methods
    
    private func requestQuoteUpdate() {
        
        self.activityIndicator.startAnimating()
        self.logoImage.isHidden = true
        self.companyNameLabel.text = "-"
        self.companySymbolLabel.text = "-"
        self.priceLabel.text = "-"
        self.priceChangeLabel.text = "-"
        
        self.companyNameLabel.textColor = UIColor.black
        self.companySymbolLabel.textColor = UIColor.black
        self.priceLabel.textColor = UIColor.black
        self.priceChangeLabel.textColor = UIColor.black
        
        let selectedRow = self.companyPickerView.selectedRow(inComponent: 0)
        let selectedSymbol = Array(self.companies.values)[selectedRow]
        self.requestQuote(for: selectedSymbol)
        self.requestLogo(for: selectedSymbol)
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        self.requestQuoteUpdate()
    }
    
    private func requestLogo(for symbol: String) {
        let urlLogo = URL(string: "https://api.iextrading.com/1.0/stock/\(symbol)/logo")!
        
        let logoTask = URLSession.shared.dataTask(with: urlLogo) { data, response, error in guard
            error == nil,
            (response as? HTTPURLResponse)?.statusCode == 200,
            let data = data
            else {
                print("❗️Network error")
                return
            }
            
            self.parseLogo(data: data)
        }
        
        logoTask.resume()
    }
    
    private func parseLogo(data: Data) {
        do {
            let jsonObject = try JSONSerialization.jsonObject(with: data)
            
            guard
                let json = jsonObject as? [String: Any],
                let imageUrl = json["url"] as? String
                else {
                    print("❗️Invalid JSON format")
                    return
            }
            
            drawLogo(for: imageUrl)
        } catch {
            print("❗️ JSON parsing error: " + error.localizedDescription)
        }
    }
    
    private func drawLogo(for imageUrl: String) {
        let url = URL(string: imageUrl)!
        let dataTask = URLSession.shared.dataTask(with: url) { data, response, error in guard
            error == nil,
            (response as? HTTPURLResponse)?.statusCode == 200,
            let image = UIImage(data: data!)
            else {
                print("❗️Network error")
                return
            }
            DispatchQueue.main.async {
                self.logoImage.image = image
            }
        }
        
        dataTask.resume()
    }
    
    private func requestQuote(for symbol: String) {
        let url = URL(string: "https://api.iextrading.com/1.0/stock/\(symbol)/quote")!
        
        let dataTask = URLSession.shared.dataTask(with: url) { data, response, error in guard
            error == nil,
            (response as? HTTPURLResponse)?.statusCode == 200,
            let data = data
            else {
                print("❗️Network error")
                return
            }
            
            self.parseQuote(data: data)
        }
        
        dataTask.resume()
    }
    
    private func requestSymbols() {
        
        let url = URL(string: "https://api.iextrading.com/1.0/stock/market/list/infocus")!
        
        let dataTask = URLSession.shared.dataTask(with: url) { data, response, error in guard
            error == nil,
            (response as? HTTPURLResponse)?.statusCode == 200,
            let data = data
            else {
                print("❗️Network error")
                return
            }
            
            self.parseSymbols(data: data)
        }
        
        dataTask.resume()
    }
    
    private func parseQuote(data: Data) {
        do {
            let jsonObject = try JSONSerialization.jsonObject(with: data)
            
            guard
                let json = jsonObject as? [String: Any],
                let companyName = json["companyName"] as? String,
                let companySymbol = json["symbol"] as? String,
                let price = json["latestPrice"] as? Double,
                let priceChange = json["change"] as? Double
            else {
                print("❗️Invalid JSON format")
                return
            }
            DispatchQueue.main.async {
                self.displayStockInfo(companyName: companyName,
                                      symbol: companySymbol,
                                      price: price,
                                      priceChange: priceChange)
            }
        } catch {
                print("❗️ JSON parsing error: " + error.localizedDescription)
        }
    }
    
    private func parseSymbols(data: Data) {

        do {
            let json = try JSONSerialization.jsonObject(with: data, options: []) as? [[String:Any]]
            
            for obj in json!{
                guard
                    let symbol = obj["symbol"] as? String,
                    let companyName = obj["companyName"] as? String
                else {
                        print("❗️Invalid JSON format")
                        return
                }
                
                self.companies[companyName] = symbol
            }
            
            DispatchQueue.main.async {
                self.companyPickerView.reloadAllComponents()
            }
            
            self.requestQuoteUpdate()
        } catch {
            print("❗️ JSON parsing error: " + error.localizedDescription)
        }
    }
    
    private func displayStockInfo(companyName: String, symbol: String,
                                  price: Double, priceChange: Double) {
        self.activityIndicator.stopAnimating()
        self.logoImage.isHidden = false
        self.companyNameLabel.text = companyName
        self.companySymbolLabel.text = symbol
        self.priceLabel.text = "\(price)"
        self.priceChangeLabel.text = "\(priceChange)"
        
        if (priceChange > 0) {
            self.priceChangeLabel.textColor = UIColor.green
        } else if (priceChange < 0){
            self.priceChangeLabel.textColor = UIColor.red
        }
        else {
            self.priceChangeLabel.textColor = UIColor.black
        }
    }
}















