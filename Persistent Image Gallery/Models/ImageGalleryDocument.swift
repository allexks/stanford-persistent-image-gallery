//
//  ImageGalleryDocument.swift
//  Persistent Image Gallery
//
//  Created by Aleksandar Ignatov on 17.06.19.
//  Copyright © 2019 MentorMate. All rights reserved.
//

import UIKit

class ImageGalleryDocument: UIDocument {
  
  var imageGallery: ImageGallery?
  var thumbnail: UIImage?
  
  override func contents(forType typeName: String) throws -> Any {
    return imageGallery?.json ?? Data()
  }
  
  override func load(fromContents contents: Any, ofType typeName: String?) throws {
    if let json = contents as? Data {
      imageGallery = try? JSONDecoder().decode(ImageGallery.self, from: json)
    }
  }
  
  override func fileAttributesToWrite(to url: URL, for saveOperation: UIDocument.SaveOperation) throws -> [AnyHashable : Any] {
    var result = try super.fileAttributesToWrite(to: url, for: saveOperation)
    if let thumbnail = self.thumbnail {
      result[URLResourceKey.thumbnailDictionaryKey] = [URLThumbnailDictionaryItem.NSThumbnail1024x1024SizeKey : thumbnail]
    }
    return result
  }
}

