//
//  Pin.swift
//  Virtual Tourist
//


import UIKit
import CoreData
import MapKit

class Pin: NSManagedObject {
    
    @NSManaged var latitude: Double
    @NSManaged var longitude: Double
    @NSManaged var photos: [Photo]
    
    // Keep track of whether method to get photos for the Pin has been called (initialize property to false)
    @NSManaged var getPhotosCompleted: Bool
    
    // Standard Core Data init method
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    init(coordinate: CLLocationCoordinate2D, getPhotosCompleted: Bool, context: NSManagedObjectContext) {
        
        // Initialize entity for Core Data context
        let entity = NSEntityDescription.entityForName("Pin", inManagedObjectContext: context)!
        super.init(entity: entity, insertIntoManagedObjectContext: context)
        
        latitude = coordinate.latitude
        longitude = coordinate.longitude
        self.getPhotosCompleted = getPhotosCompleted
    }
}
