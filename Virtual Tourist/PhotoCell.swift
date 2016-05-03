//
//  PhotoCell.swift
//  Virtual Tourist
//


import UIKit

class PhotoCell: UICollectionViewCell {
    
    @IBOutlet weak var photoImageView: UIImageView!
    @IBOutlet weak var loadingIndicator: UIActivityIndicatorView!
    
    // Set cell appearance for selected state
    override var selected: Bool {
        get {
            return super.selected
        }
        set {
            if newValue {
                super.selected = true
                photoImageView.layer.borderWidth = 3.0
                photoImageView.alpha = 0.5
            } else {
                super.selected = false
                photoImageView.layer.borderWidth = 0
                photoImageView.alpha = 1.0
            }
        }
    }
}
