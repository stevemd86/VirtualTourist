//
//  PointAnnotation.swift
//  Virtual Tourist
//


import UIKit
import MapKit

class PointAnnotation: MKPointAnnotation {
    
    var pin: Pin!
    
    init(pin: Pin) {
        self.pin = pin
    }
}
