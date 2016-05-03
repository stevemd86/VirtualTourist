//
//  Photo.swift
//  Virtual Tourist
//


import UIKit
import CoreData

class Photo: NSManagedObject {
    
    struct Keys {
        static let Title = "title"
        static let ID = "id"
        static let ImageURL = "url_z"
    }
    
    @NSManaged var title: String
    @NSManaged var imageID: String
    @NSManaged var imageURLString: String
    @NSManaged var imagePath: String
    @NSManaged var pin: Pin?
    
    // Standard Core Data init method
    override init(entity: NSEntityDescription, insertIntoManagedObjectContext context: NSManagedObjectContext?) {
        super.init(entity: entity, insertIntoManagedObjectContext: context)
    }
    
    init(dictionary: [String : AnyObject], context: NSManagedObjectContext) {
        
        // Initialize entity for Core Data context
        let entity = NSEntityDescription.entityForName("Photo", inManagedObjectContext: context)!
        super.init(entity: entity, insertIntoManagedObjectContext: context)
        
        title = dictionary[Keys.Title] as! String
        if title == "" {
            title = "Untitled"
        }
        imageID = dictionary[Keys.ID] as! String
        imageURLString = dictionary[Keys.ImageURL] as! String
    }
    
    var image: UIImage? {
        
        get {
            return FlickrClient.Caches.imageCache.imageWithIdentifier(imagePath)
        }
        set {
            FlickrClient.Caches.imageCache.storeImage(newValue, withIdentifier: imagePath)
        }
    }
    
    // Delete stored image data before removing Photo object from Core Data
    override func prepareForDeletion() {
        if image != nil {
            let path = FlickrClient.Caches.imageCache.pathForIdentifier(imagePath)
            let fileManager = NSFileManager.defaultManager()
            do {
                try fileManager.removeItemAtPath(path)
                print("image data removed automatically")
            } catch {
                print(error)
            }
        }
    }
}
