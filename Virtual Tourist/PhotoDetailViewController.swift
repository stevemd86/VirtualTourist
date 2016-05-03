//
//  PhotoDetailViewController.swift
//  Virtual Tourist
//


import UIKit
import CoreData

class PhotoDetailViewController: UIViewController, UIScrollViewDelegate {
    
    // MARK: - Properties
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var titleLabel: UILabel!
    var photoAlbum = [Photo]()
    var imageIndex = 0
    
    
    // MARK: - UI Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        automaticallyAdjustsScrollViewInsets = false
        
        // Configure scroll view
        scrollView.frame = CGRectMake(0, 0, view.frame.width, view.frame.height - navigationController!.navigationBar.frame.height - 150)
        let scrollViewWidth: CGFloat = scrollView.frame.width
        let scrollViewHeight: CGFloat = scrollView.frame.height
        
        let photoCount = photoAlbum.count
        
        for (index, photo) in photoAlbum.enumerate() {
            
            let imageView = UIImageView(frame: CGRectMake(scrollViewWidth * CGFloat(index), scrollView.frame.origin.y, scrollViewWidth, scrollViewHeight))
            imageView.image = photo.image
            imageView.contentMode = UIViewContentMode.ScaleAspectFit
            imageView.clipsToBounds = true
            
            scrollView.addSubview(imageView)
        }
        
        scrollView.contentSize = CGSizeMake(scrollView.frame.width * CGFloat(photoCount), 1.0)
        scrollView.contentOffset = CGPointMake(scrollViewWidth * CGFloat(imageIndex), 0)
        scrollView.delegate = self
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        titleLabel.text = photoAlbum[imageIndex].title
    }
    
    
    // MARK: - UIScrollViewDelegate Methods

    func scrollViewDidEndDecelerating(scrollView: UIScrollView) {
        // Test the offset and calculate the current page after scrolling ends
        let pageWidth:CGFloat = CGRectGetWidth(scrollView.frame)
        let currentPage:CGFloat = floor((scrollView.contentOffset.x - pageWidth / 2) / pageWidth) + 1
        let currentPhoto = photoAlbum[Int(currentPage)]
        titleLabel.text = currentPhoto.title
    }
}
