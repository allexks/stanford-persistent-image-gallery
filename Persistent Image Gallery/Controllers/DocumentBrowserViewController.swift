//
//  DocumentBrowserViewController.swift
//  Persistent Image Gallery
//
//  Created by Aleksandar Ignatov on 17.06.19.
//  Copyright © 2019 MentorMate. All rights reserved.
//

import UIKit


class DocumentBrowserViewController: UIDocumentBrowserViewController, UIDocumentBrowserViewControllerDelegate {
  
  // MARK: - Properties
  
  private let navControllerID = "Image Gallery Navigation Controller"
  var template: URL?
  
  // MARK: - View Controller Lifecycle
  
  override func viewDidLoad() {
    super.viewDidLoad()
    delegate = self
    allowsDocumentCreation = false
    allowsPickingMultipleItems = false
    
    if UIDevice.current.userInterfaceIdiom == .pad {
      template = try?  FileManager.default.url(for: .applicationSupportDirectory,
                                               in: .userDomainMask,
                                               appropriateFor: nil,
                                               create: true
        ).appendingPathComponent("Untitled.json")
      
      if let template = template {
        allowsDocumentCreation = FileManager.default.createFile(atPath: template.path,
                                                                contents: Data(),
                                                                attributes: nil)
      }
    }
  }
  
  
  // MARK: - Document Browser View Controller Delegate
  
  func documentBrowser(_ controller: UIDocumentBrowserViewController, didRequestDocumentCreationWithHandler importHandler: @escaping (URL?, UIDocumentBrowserViewController.ImportMode) -> Void) {
    importHandler(template, .copy)
  }
  
  func documentBrowser(_ controller: UIDocumentBrowserViewController, didPickDocumentsAt documentURLs: [URL]) {
    guard let sourceURL = documentURLs.first else { return }
    
    // Present the Document View Controller for the first document that was picked.
    // If you support picking multiple items, make sure you handle them all.
    presentDocument(at: sourceURL)
  }
  
  func documentBrowser(_ controller: UIDocumentBrowserViewController, didImportDocumentAt sourceURL: URL, toDestinationURL destinationURL: URL) {
    // Present the Document View Controller for the new newly created document
    presentDocument(at: destinationURL)
  }
  
  func documentBrowser(_ controller: UIDocumentBrowserViewController, failedToImportDocumentAt documentURL: URL, error: Error?) {
    // Make sure to handle the failed import appropriately, e.g., by presenting an error message to the user.
  }
  
  // MARK: - Document Presentation
  
  func presentDocument(at documentURL: URL) {
    let storyboard = UIStoryboard(name: "Main", bundle: nil)
    if let navigationController = storyboard.instantiateViewController(withIdentifier: navControllerID) as? UINavigationController,
      let imageGalleryVC = navigationController.visibleViewController as? ImageGalleryViewController {
      imageGalleryVC.document = ImageGalleryDocument(fileURL: documentURL)
      present(navigationController, animated: true)
    }
  }
}

