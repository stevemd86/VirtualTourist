//
//  FlickrClient.swift
//  Virtual Tourist
//


import UIKit

class FlickrClient: NSObject {
    
    // Properties
    var methodArguments: [String : AnyObject] = [
        "api_key": Constants.APIKey,
        "method": Methods.SearchPhotos,
        "format": ParameterKeys.DataFormat,
        "nojsoncallback": ParameterKeys.NoJSONCallback,
        "per_page": ParameterKeys.PerPage,
        "safe_search": ParameterKeys.SafeSearch,
        "extras": ParameterKeys.PhotoSize
    ]
    var session: NSURLSession!
    
    // MARK: - Initializers
    override init() {
        super.init()
        session = NSURLSession.sharedSession()
    }
    
    
    // MARK: - Flickr API Method
    
    /* Since Flickr only allows a maximum of 4000 photos per search query, a per_page setting of 30 images per page will result in a maximum of 134 pages. First select a random page number, then call getImagesFromFlickrBySearchWithPage to get images for that particular page. */
    func getPhotosFromFlickrBySearch(request: NSMutableURLRequest, completionHandler: (result: AnyObject!, error: NSError?) -> Void) {
        
        // Initialize task for getting data
        let task = session.dataTaskWithRequest(request) { (data, response, error) in
            
            /* GUARD: Was there an error? */
            guard (error == nil) else {
                print("There was an error with your request: \(error!)")
                completionHandler(result: nil, error: error)
                return
            }
            
            /* GUARD: Did we get a successful 2XX response? */
            guard let statusCode = (response as? NSHTTPURLResponse)?.statusCode where statusCode >= 200 && statusCode <= 299 else {
                if let response = response as? NSHTTPURLResponse {
                    
                    let localizedResponse = NSHTTPURLResponse.localizedStringForStatusCode(response.statusCode)
                    print("Your request returned an invalid response! Status code: \(response.statusCode). Description: \(localizedResponse).")
                    
                    let userInfo = [NSLocalizedDescriptionKey : "\(response.statusCode) - \(localizedResponse)"]
                    completionHandler(result: nil, error: NSError(domain: "statusCode", code: 2, userInfo: userInfo))
                    
                } else if let response = response {
                    print("Your request returned an invalid response! Response: \(response)!")
                    let userInfo = [NSLocalizedDescriptionKey : "The request returned an invalid response code"]
                    completionHandler(result: nil, error: NSError(domain: "statusCode", code: 2, userInfo: userInfo))
                    
                } else {
                    print("Your request returned an invalid response!")
                    let userInfo = [NSLocalizedDescriptionKey : "The request returned an invalid response code"]
                    completionHandler(result: nil, error: NSError(domain: "statusCode", code: 2, userInfo: userInfo))
                }
                return
            }
            
            /* GUARD: Was there any data returned? */
            guard let data = data else {
                print("No data was returned by the request!")
                let userInfo = [NSLocalizedDescriptionKey : "Unable to retrieve data from server"]
                completionHandler(result: nil, error: NSError(domain: "data", code: 3, userInfo: userInfo))
                return
            }
            
            // Parse the JSON data
            self.parseJSONDataWithCompletionHandler(data) { (parsedResult, error) in
                
                guard let photosDictionary = parsedResult[FlickrClient.JSONResponseKeys.Photos] as? NSDictionary else {
                    print("Cannot find key \(JSONResponseKeys.Photos) in \(parsedResult). Error: \(error?.localizedDescription)")
                    return
                }
                
                guard let totalPages = photosDictionary[FlickrClient.JSONResponseKeys.Pages] as? Int else {
                    print("Cannot find key \(JSONResponseKeys.Pages) in \(photosDictionary). Error: \(error?.localizedDescription)")
                    return
                }
                
                // Pick a random page
                let pageLimit = min(totalPages, 134)
                let randomPage = Int(arc4random_uniform(UInt32(pageLimit))) + 1
                self.methodArguments[ParameterKeys.Page] = randomPage
                let request = self.configureURLRequestForGETImagesByLocation()
                self.getPhotosFromFlickrBySearchWithPage(request, completionHandler: completionHandler)
            }
        }
        
        task.resume()
    }
    
    // Get photos from a random page
    func getPhotosFromFlickrBySearchWithPage(request: NSMutableURLRequest, completionHandler: (result: AnyObject!, error: NSError?) -> Void) {

        // Initialize task for getting data
        let task = session.dataTaskWithRequest(request) { (data, response, error) in
            
            /* GUARD: Was there an error? */
            guard (error == nil) else {
                print("There was an error with your request: \(error!)")
                completionHandler(result: nil, error: error)
                return
            }
            
            /* GUARD: Did we get a successful 2XX response? */
            guard let statusCode = (response as? NSHTTPURLResponse)?.statusCode where statusCode >= 200 && statusCode <= 299 else {
                if let response = response as? NSHTTPURLResponse {
                    
                    let localizedResponse = NSHTTPURLResponse.localizedStringForStatusCode(response.statusCode)
                    print("Your request returned an invalid response! Status code: \(response.statusCode). Description: \(localizedResponse).")
                    
                    let userInfo = [NSLocalizedDescriptionKey : "\(response.statusCode) - \(localizedResponse)"]
                    completionHandler(result: nil, error: NSError(domain: "statusCode", code: 2, userInfo: userInfo))
                    
                } else if let response = response {
                    print("Your request returned an invalid response! Response: \(response)!")
                    let userInfo = [NSLocalizedDescriptionKey : "The request returned an invalid response code"]
                    completionHandler(result: nil, error: NSError(domain: "statusCode", code: 2, userInfo: userInfo))
                    
                } else {
                    print("Your request returned an invalid response!")
                    let userInfo = [NSLocalizedDescriptionKey : "The request returned an invalid response code"]
                    completionHandler(result: nil, error: NSError(domain: "statusCode", code: 2, userInfo: userInfo))
                }
                return
            }
            
            /* GUARD: Was there any data returned? */
            guard let data = data else {
                print("No data was returned by the request!")
                let userInfo = [NSLocalizedDescriptionKey : "Unable to retrieve data from server"]
                completionHandler(result: nil, error: NSError(domain: "data", code: 3, userInfo: userInfo))
                return
            }
            
            // Parse the JSON data
            self.parseJSONDataWithCompletionHandler(data, completionHandler: completionHandler)
        }
        
        // 9 - Resume (execute) the task
        task.resume()
    }
    
    
    // MARK: - Helper Methods
    
    func parseJSONDataWithCompletionHandler(data: NSData, completionHandler: (result: AnyObject!, error: NSError?) -> Void) {
        var parsedResult: AnyObject!
        do {
            parsedResult = try NSJSONSerialization.JSONObjectWithData(data, options: .AllowFragments)
        } catch {
            let userInfo = [NSLocalizedDescriptionKey : "Could not parse the data as JSON: '\(data)'"]
            completionHandler(result: nil, error: NSError(domain: "parseJSONWithCompletionHandler", code: 1, userInfo: userInfo))
        }

        completionHandler(result: parsedResult, error: nil)
    }
    
    // Given a dictionary of parameters, convert to a string for a URL (ASCII)
    func escapedParameters(parameters: [String : AnyObject]) -> String {
        
        var urlVars = [String]()
        
        for (key, value) in parameters {
            
            // Make sure that it is a string value
            let stringValue = "\(value)"
            
            // Escape it
            let escapedValue = stringValue.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet())
            
            // Append it
            urlVars += [key + "=" + "\(escapedValue!)"]
        }
        
        return (!urlVars.isEmpty ? "?" : "") + urlVars.joinWithSeparator("&")
    }
    
    
    // MARK: Shared Instance
    class func sharedInstance() -> FlickrClient {
        
        struct Singleton {
            static var sharedInstance = FlickrClient()
        }
        
        return Singleton.sharedInstance
    }
    
    
    // MARK: - Shared Image Cache
    
    struct Caches {
        static let imageCache = ImageCache()
    }
}
