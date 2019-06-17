//
//  ImageGalleryViewController.swift
//  Image Gallery
//
//  Created by Aleksandar Ignatov on 11.06.19.
//  Copyright © 2019 MentorMate. All rights reserved.
//

import UIKit

class ImageGalleryViewController: UIViewController {
  
  // MARK: - Outlets
  
  @IBOutlet weak var collectionView: UICollectionView! {
    didSet {
      collectionView.dragInteractionEnabled = true
    }
  }
  
  // MARK: - Properties
  
  var document: ImageGalleryDocument?
  
  private let imageCellReuseIdentifier = "Image Cell"
  private let headerViewReuseIdentifier = "Image Gallery Header"
  private let dropPlaceholderReuseIdentifier = "Drop Placeholder"
  private let viewImageSegueIdentifier = "View Image"
  private let sectionInsets = UIEdgeInsets(top: 50.0, left: 20.0, bottom: 50.0, right: 20.0)
  private let itemMinimumWidth: CGFloat = 20.0
  
  private lazy var gallery: ImageGallery = ImageGallery([], title: "Untitled")
  
  private lazy var fetcher = URLFetcher.shared
  
  private var itemWidth: CGFloat = 200.0
  
  private var flowLayout: UICollectionViewFlowLayout? {
    return collectionView?.collectionViewLayout as? UICollectionViewFlowLayout
  }
  
  // MARK: - View Controller Lifecycle
  
  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    
    document?.open{ [weak self] (success) in
      guard let self = self else { return }
      if success {
        self.title = self.document?.localizedName
        self.gallery = self.document?.imageGallery ?? ImageGallery([], title: nil)
      } else {
        assert(false)
        // TODO
      }
      self.collectionView.reloadData()
    }
  }

  // MARK: - Actions
  
  @IBAction func onPinchView(_ sender: UIPinchGestureRecognizer) {
    let suggestedWidth = itemWidth * sender.scale
    if suggestedWidth <= (view.bounds.width - sectionInsets.left - sectionInsets.right) && suggestedWidth >= itemMinimumWidth {
      itemWidth = suggestedWidth
    }
    sender.scale = 1
    flowLayout?.invalidateLayout()
  }
  
  @IBAction func onTapSaveButton(_ sender: UIBarButtonItem) {
    save()
  }
  
  @IBAction func onTapDoneButton(_ sender: UIBarButtonItem) {
    save()
    document?.thumbnail = collectionView.snapshot
    dismiss(animated: true) {
      self.document?.close()
    }
  }
  
  // MARK: - Navigation
  
  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    if segue.identifier == viewImageSegueIdentifier,
      let destination = segue.destination as? ImageScrollViewController,
      let cell = sender as? ImageCell,
      let indexPath = collectionView.indexPath(for: cell) {
      destination.url = getImageData(at: indexPath).url
    }
  }
  
  // MARK: - Helper methods
  
  private func getImageData(at indexPath: IndexPath) -> ImageGallery.ImageData {
    return gallery[indexPath.row]
  }
  
  private func removeImage(at indexPath: IndexPath) {
    gallery.images.remove(at: indexPath.row)
  }
  
  private func insertImage(_ image: ImageGallery.ImageData, at indexPath: IndexPath) {
    let endIndex = gallery.images.endIndex
    let index = indexPath.row > endIndex ? endIndex : indexPath.row
    gallery.images.insert(image, at: index)
  }
  
  private func save() {
    document?.imageGallery = gallery
    if document?.imageGallery != nil {
      document?.updateChangeCount(.done)
    }
  }
}

// MARK: - Colection View Delegate

extension ImageGalleryViewController: UICollectionViewDelegate {}

// MARK: - Collection View Data Source

extension ImageGalleryViewController: UICollectionViewDataSource {
  func numberOfSections(in collectionView: UICollectionView) -> Int {
    return 1
  }
  
  func collectionView(_ collectionView: UICollectionView,
                      numberOfItemsInSection section: Int
  ) -> Int {
    return gallery.count
  }
  
  func collectionView(_ collectionView: UICollectionView,
                      cellForItemAt indexPath: IndexPath
  ) -> UICollectionViewCell {
    guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: imageCellReuseIdentifier,
                                                        for: indexPath) as? ImageCell else {
      return UICollectionViewCell()
    }
    
    cell.backgroundColor = .clear
    let url = getImageData(at: indexPath).url
    fetcher.fetchImage(from: url){ (_, image) in
      DispatchQueue.main.async {
        cell.image.image = image
      }
    }
    return cell
  }
}

// MARK: - Collection View Flow Layout Delegate

extension ImageGalleryViewController: UICollectionViewDelegateFlowLayout {
  func collectionView(_ collectionView: UICollectionView,
                      layout collectionViewLayout: UICollectionViewLayout,
                      sizeForItemAt indexPath: IndexPath
  ) -> CGSize {
    let ratio = getImageData(at: indexPath).aspectRatio
    let itemHeight = itemWidth / CGFloat(ratio)
    
    return CGSize(width: itemWidth, height: itemHeight)
  }
  
  func collectionView(_ collectionView: UICollectionView,
                      layout collectionViewLayout: UICollectionViewLayout,
                      insetForSectionAt section: Int
  ) -> UIEdgeInsets {
    return sectionInsets
  }
  
  func collectionView(_ collectionView: UICollectionView,
                      layout collectionViewLayout: UICollectionViewLayout,
                      minimumLineSpacingForSectionAt section: Int
  ) -> CGFloat {
    return sectionInsets.left
  }
}

// MARK: - Collection View Drag Delegate

extension ImageGalleryViewController: UICollectionViewDragDelegate {
  func collectionView(_ collectionView: UICollectionView,
                      itemsForBeginning session: UIDragSession,
                      at indexPath: IndexPath
  ) -> [UIDragItem] {
    session.localContext = collectionView
    let url = UIDragItem(itemProvider: NSItemProvider(contentsOf: getImageData(at: indexPath).url)!)
    return [url]
  }
}

// MARK: - Collection View Drop Delegate

extension ImageGalleryViewController: UICollectionViewDropDelegate {
  func collectionView(_ collectionView: UICollectionView,
                      canHandle session: UIDropSession
  ) -> Bool {
    return session.canLoadObjects(ofClass: UIImage.self) || session.canLoadObjects(ofClass: URL.self)
  }
  
  func collectionView(_ collectionView: UICollectionView,
                      dropSessionDidUpdate session: UIDropSession,
                      withDestinationIndexPath destinationIndexPath: IndexPath?
    ) -> UICollectionViewDropProposal {
    let operation: UIDropOperation = (session.localDragSession?.localContext as? UICollectionView) == collectionView ? .move : .copy
    return UICollectionViewDropProposal(operation: operation, intent: .insertAtDestinationIndexPath)
  }
  
  func collectionView(_ collectionView: UICollectionView,
                      performDropWith coordinator: UICollectionViewDropCoordinator) {
    
    coordinator.items.forEach { dropItem in
      if let sourceIndexPath = dropItem.sourceIndexPath {
        // local drag n drop
        let destinationIndexPath = coordinator.destinationIndexPath ?? IndexPath(row: gallery.count-1, section: 0)
          collectionView.performBatchUpdates({
            let imageData = getImageData(at: sourceIndexPath)
            removeImage(at: sourceIndexPath)
            insertImage(imageData, at: destinationIndexPath)
            collectionView.deleteItems(at: [sourceIndexPath])
            collectionView.insertItems(at: [destinationIndexPath])
          }, completion: { _ in
            coordinator.drop(dropItem.dragItem, toItemAt: destinationIndexPath)
          })
      } else {
        // drop from outer space
        let destinationIndexPath = coordinator.destinationIndexPath ?? IndexPath(row: gallery.count, section: 0)
        let placeholder = coordinator.drop(dropItem.dragItem, to: UICollectionViewDropPlaceholder(insertionIndexPath: destinationIndexPath, reuseIdentifier: dropPlaceholderReuseIdentifier))
        let _ = dropItem.dragItem.itemProvider.loadObject(ofClass: URL.self) {(url, err) in
          guard let url = url,
            err == nil else {
              DispatchQueue.main.async {
                placeholder.deletePlaceholder()
              }
              print("Error fetching image for destination index path \(destinationIndexPath).")
              return
          }
          self.fetcher.fetchImage(from: url) { (url, image) in
            let aspectRatio = Double(image.size.width / image.size.height)
            let newImageData = ImageGallery.ImageData(url: url, aspectRatio: aspectRatio)
            DispatchQueue.main.async {
              placeholder.commitInsertion { [weak self] indexPath in
                self?.insertImage(newImageData, at: indexPath)
              }
            }
          }
        }
      }
    }
  }
}
