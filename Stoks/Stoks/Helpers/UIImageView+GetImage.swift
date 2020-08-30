//
//  UIImageView+GetImage.swift
//  Stoks
//
//  Created by Gorbovtsova Ksenya on 30.08.2020.
//  Copyright © 2020 Tinkoff. All rights reserved.
//
import UIKit

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
