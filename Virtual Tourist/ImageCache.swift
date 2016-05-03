//
//  File.swift
//  FavoriteActors
//


import UIKit

class ImageCache {
    
    private var inMemoryCache = NSCache()
    
    // MARK: - Retrieving images
    
    func imageWithIdentifier(identifier: String?) -> UIImage? {
        
        // If the identifier is nil, or empty, return nil
        if identifier == nil || identifier! == "" {
            print("no identifier")
            return nil
        }
        
        else {
            let path = pathForIdentifier(identifier!)
            
            // First try the memory cache
            if let image = inMemoryCache.objectForKey(path) as? UIImage {
                print("image retrieved from memory cache")
                return image
            }
                // Next Try the hard drive
            else if let data = NSData(contentsOfFile: path) {
                print("image retrieved from hard drive")
                return UIImage(data: data)
            }
            else {
                print("could not retrieve image")
                return nil
            }
        }
    }
    
    // MARK: - Saving images
    
    func storeImage(image: UIImage?, withIdentifier identifier: String) {
        let path = pathForIdentifier(identifier)
        
        // If the image is nil, remove images from the cache
        if image == nil {
            print("image is nil")
            inMemoryCache.removeObjectForKey(path)
            do {
                try NSFileManager.defaultManager().removeItemAtPath(path)
            } catch _ {
            }
            return
        }
        else {
            
            inMemoryCache.setObject(image!, forKey: path)
            
            // And in documents directory
            let data = UIImageJPEGRepresentation(image!, 1.0)
            data!.writeToFile(path, atomically: true)
            
            print("image stored at path: \(path)")
        }
    }
    
    // MARK: - Helper
    
    func pathForIdentifier(identifier: String) -> String {
        let documentsDirectoryURL: NSURL = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).first!
        let fullURL = documentsDirectoryURL.URLByAppendingPathComponent(identifier)
        
        return fullURL.path!
    }
}