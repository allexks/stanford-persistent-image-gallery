//
//  URLFetcher.swift
//  Image Gallery
//
//  Created by Aleksandar Ignatov on 12.06.19.
//  Copyright © 2019 MentorMate. All rights reserved.
//

import UIKit

class URLFetcher {
  static let shared = URLFetcher()
  private init() {}
  
  private lazy var cache = URLCache(memoryCapacity: 1024 * 1024 * 50, diskCapacity: 1024 * 1024 * 50, diskPath: nil)
  
  func fetchImage(from url: URL, handler: @escaping (URL, UIImage, Data?, URLResponse?, Error?) -> Void) {
    URLSession.shared.dataTask(with: url.imageURL) { data, response, error in
      if error == nil, let data = data, let image = UIImage(data: data) {
        handler(url, image, data, response, error)
      } else {
        print("Fetch failed.")
        let image = UIImage(imageLiteralResourceName: "question-mark")
        let url = image.storeLocallyAsJPEG(named: String(Date().timeIntervalSinceReferenceDate))!
        handler(url, image, data, response, error)
      }
    }.resume()
  }
  
  func getCachedImage(from url: URL, handler: @escaping (UIImage)->Void) {
    let request = URLRequest(url: url.imageURL)
    
    if let cachedResponse = cache.cachedResponse(for: request), let image = UIImage(data: cachedResponse.data) {
      handler(image)
    } else {
      fetchImage(from: url){ [weak self] (_, image, data, response, error) in
        handler(image)
        if error == nil, let response = response, let data = data {
          self?.cache.storeCachedResponse(CachedURLResponse(response: response, data: data), for: request)
        }
      }
    }
  }
}
