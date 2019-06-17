//
//  ImageGallery.swift
//  Image Gallery
//
//  Created by Aleksandar Ignatov on 11.06.19.
//  Copyright © 2019 MentorMate. All rights reserved.
//

import Foundation

class ImageGallery: Codable {
  var images: [ImageData] = []
  var title: String?
  
  var json: Data? {
    return try? JSONEncoder().encode(self)
  }
  
  var count: Int {
    return images.count
  }
  
  init(_ arr: [ImageData] = [], title: String? = nil) {
    images = arr
    self.title = title
  }
  
  subscript(index: Int) -> ImageData {
    return images[index]
  }
}

extension ImageGallery {
  struct ImageData: Codable {
    var url: URL
    var aspectRatio: Double
  }
}
