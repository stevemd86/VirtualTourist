//
//  FlickrConvenience.swift
//  Virtual Tourist
//


import UIKit

// MARK: - FlickrClient (Convenient Resource Methods)

extension FlickrClient {
    
    // MARK: - GET Images by Lat/Lon Data
    func getPhotosURLArrayByLocation(latitude: Double, longitude: Double, completionHandler: (success: Bool, photosArray: [[String: AnyObject]], errorString: String?) -> Void) {
        
        // Set the parameters
        methodArguments[ParameterKeys.BBox] = createBoundingBoxString(latitude, longitude: longitude)
        
        let request = configureURLRequestForGETImagesByLocation()
        
        getPhotosFromFlickrBySearch(request) { (result, error) in
            
            if let error = error {
                completionHandler(success: false, photosArray: [], errorString: error.localizedDescription)
            } else {
                // Check if result contains 'photos' key
                if let photosDictionary = result[JSONResponseKeys.Photos] as? NSDictionary {
                    
                    // Check if any images have been returned
                    if let totalPhotos = photosDictionary[JSONResponseKeys.Total] as? String {

                        if Int(totalPhotos) > 0 {
                            print("\(totalPhotos) photos found.")
                            
                            // Check if results contain an array of photo dictionaries
                            if let photosArray = photosDictionary[JSONResponseKeys.Photo] as? [[String: AnyObject]] {
                                
                                var filteredPhotosArray = [[String: AnyObject]]()
                                
                                // If photo object contains an imageURLString, append to filteredPhotosArray until 30 imageURLStrings are obtained
                                for photo in photosArray {
                                    if filteredPhotosArray.count < 30 {
                                        if photo[FlickrClient.JSONResponseKeys.ImageURL] != nil {

                                            filteredPhotosArray.append(photo)
                                        } else {
                                            print("Photo object does not contain an imageURLString.")
                                        }
                                    }
                                }
                                
                                completionHandler(success: true, photosArray: filteredPhotosArray, errorString: nil)
                            }
                            else {
                                print("Cannot find key \(JSONResponseKeys.Photo) in \(photosDictionary)")
                                completionHandler(success: false, photosArray: [], errorString: "Server results did not contain any photo data.")
                            }
                        }
                        else {
                            print("No images have been returned")
                            completionHandler(success: true, photosArray: [], errorString: nil)
                        }
                    }
                    else {
                        print("Cannot find key \(JSONResponseKeys.Total) in \(photosDictionary)")
                        completionHandler(success: false, photosArray: [], errorString: "No totalPhotos value returned from server.")
                    }
                }
                else {
                    print("Cannot find key \(JSONResponseKeys.Photos) in \(result)")
                    completionHandler(success: false, photosArray: [], errorString: "No results returned from server.")
                }
            }
        }
    }
    
    func getImageWithURL(urlString: String, completionHandler: (downloadedImage: UIImage?, error: NSError?) -> Void) {

        let url = NSURL(string: urlString)
        let request = NSMutableURLRequest(URL: url!)
        
        let task = session.dataTaskWithRequest(request) { (data, response, error) in
            if let error = error {
                print(error.localizedDescription)
                completionHandler(downloadedImage: nil, error: error)
            } else {
                if let image = UIImage(data: data!) {
                    completionHandler(downloadedImage: image, error: nil)
                }
                else {
                    print("image does not exist at URL")
                    completionHandler(downloadedImage: nil, error: nil)
                }
            }
        }
        task.resume()
    }
    
    func configureURLRequestForGETImagesByLocation() -> NSMutableURLRequest {
        
        // Build the URL and configure the request
        let urlString = Constants.baseURLSecure + escapedParameters(methodArguments)
        let url = NSURL(string: urlString)!
        let request = NSMutableURLRequest(URL: url)
        
        return request
    }
    
    
    // MARK: - Lat/Lon Manipulation
    func createBoundingBoxString(latitude: Double, longitude: Double) -> String {
        
        let bottom_left_lon = max(longitude - BoundingBox.HalfWidth, BoundingBox.LonMin)
        let bottom_left_lat = max(latitude - BoundingBox.HalfHeight, BoundingBox.LatMin)
        let top_right_lon = min(longitude + BoundingBox.HalfWidth, BoundingBox.LonMax)
        let top_right_lat = min(latitude + BoundingBox.HalfHeight, BoundingBox.LatMax)
        
        return "\(bottom_left_lon),\(bottom_left_lat),\(top_right_lon),\(top_right_lat)"
    }
    
}
