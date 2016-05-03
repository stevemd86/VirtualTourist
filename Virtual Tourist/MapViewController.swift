//
//  MapViewController.swift
//  Virtual Tourist
//


import UIKit
import MapKit
import CoreData

class MapViewController: UIViewController, MKMapViewDelegate {

    //   Properties
    
    @IBOutlet weak var mapView: MKMapView!
    var dragged = false
    var deleteMode = false
    var prefetched = Bool()
    var pins = [Pin]()
    var annotation: PointAnnotation!
    var mapRegionArray: [MapRegion]!
    var mapRegion: MapRegion!
    var initialLaunch: Bool!!
    var region: MKCoordinateRegion!
    
    
    // MARK: - UI Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mapView.delegate = self
        initialLaunch = true
        
        // Add and configure gesture recognizer
        let longPressGesture = UILongPressGestureRecognizer(target: self, action: "addPin:")
        longPressGesture.minimumPressDuration = 0.5
        mapView.addGestureRecognizer(longPressGesture)
        
        // Configure nav bar button
        navigationItem.rightBarButtonItem = editButtonItem()
        navigationItem.rightBarButtonItem!.enabled = !pins.isEmpty
        
        // Fetch stored pins
        pins = CoreDataStackManager.sharedInstance().fetchAllPins()
        
        // Initialize MapView object
        mapRegionArray = CoreDataStackManager.sharedInstance().fetchMapRegion()
        
        if mapRegionArray.isEmpty {
            
            // Create MapRegion object and save to context
            mapRegion = MapRegion(region: mapView.region, context: sharedContext)
            saveContext()
            print("MapRegion object created")
        } else {
            mapRegion = mapRegionArray.last
            
            // Configure mapView region
            let center = CLLocationCoordinate2DMake(mapRegion.latitude, mapRegion.longitude)
            let span = MKCoordinateSpanMake(mapRegion.latitudeDelta, mapRegion.longitudeDelta)
            region = MKCoordinateRegionMake(center, span)
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        // Default prefetched variable to false
        prefetched = false
    }
    
    
    // MARK: - Core Data Convenience
    lazy var sharedContext: NSManagedObjectContext = {
        return CoreDataStackManager.sharedInstance().managedObjectContext
    }()
    
    func saveContext() {
        CoreDataStackManager.sharedInstance().saveContext()
    }
    
    
    // MARK: - Set Editing
    override func setEditing(editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        
        if editing {
            // Slide up view to show 'Tap Pins to Delete' label
            UIView.animateWithDuration(0.2, animations: { () -> Void in
                self.view.frame.origin.y = -50.0
            })
            
            // Enable delete mode
            deleteMode = true
        }
        else {
            // Slide view back down
            UIView.animateWithDuration(0.2, animations: { () -> Void in
                self.view.frame.origin.y = +50.0
            })
            
            // Disable delete mode
            deleteMode = false
            
            // Disable Edit button if mapView has no more annotations
            navigationItem.rightBarButtonItem!.enabled = mapView.annotations.count > 0
        }
    }
    
    
    // MARK: - Actions
    func addPin(gestureRecognizer: UIGestureRecognizer) {
        
        if deleteMode == false {
            
            // Get point from gesture recognizer and convert to map coordinates
            let point = gestureRecognizer.locationInView(mapView)
            let coordinates = mapView.convertPoint(point, toCoordinateFromView: mapView)
            
            switch gestureRecognizer.state {
            case .Began:
                print("gesture began")
                
                // Create new Pin object
                let newPin = Pin(coordinate: coordinates, getPhotosCompleted: false, context: sharedContext)
                
                // Create PointAnnotation from newPin and add to map view
                annotation = PointAnnotation(pin: newPin)
                annotation.coordinate = coordinates
            
                dispatch_async(dispatch_get_main_queue()) {
                    self.mapView.addAnnotation(self.annotation)
                    self.navigationItem.rightBarButtonItem!.enabled = true
                }
                
                print("annotation added")
                
            case .Changed:
                print("gesture changed")
                
                // Update annotation coordinates
                dispatch_async(dispatch_get_main_queue()) {
                    self.annotation.coordinate = coordinates
                    self.annotation.pin.latitude = coordinates.latitude
                    self.annotation.pin.longitude = coordinates.longitude
                }
                
            case .Ended:
                print("gesture ended")
                
                // Add pin to array
                pins.append(annotation.pin)
                
                // Save pin
                saveContext()
                
                // Pre-fetch images
                getPhotosURLArrayFromFlickr(annotation.pin)
                
            default:
                return
            }
        }
    }
    

    // MARK: - MKMapViewViewDelegate Methods
    
    func mapViewDidFinishRenderingMap(mapView: MKMapView, fullyRendered: Bool) {

        if fullyRendered {
            if mapView.annotations.isEmpty {
                
                // Upon initial loading, create PointAnnotation objects from persisted Pin objects and add to mapView
                for pin in pins {
                    let annotation = PointAnnotation(pin: pin)
                    let coordinate = CLLocationCoordinate2DMake(pin.latitude, pin.longitude)
                    annotation.coordinate = coordinate
                    mapView.addAnnotation(annotation)
                    
                    print("stored PointAnnotation added")
                }
            }
            
            if initialLaunch == true {
                
                if !mapRegionArray.isEmpty {
                    // Set mapView region
                    mapView.setRegion(region, animated: true)
                    print("restored region: \(region)")
                }
                initialLaunch = false
            }
        }
    }
    
    func mapView(mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        
        // Update mapRegion and save to context
        mapRegion.latitude = mapView.region.center.latitude
        mapRegion.longitude = mapView.region.center.longitude
        mapRegion.latitudeDelta = mapView.region.span.latitudeDelta
        mapRegion.longitudeDelta = mapView.region.span.longitudeDelta
        
        saveContext()
        
        print("map region updated")
    }
    
    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
        
        let reuseId = "pin"
        
        var pinView = mapView.dequeueReusableAnnotationViewWithIdentifier(reuseId) as? MKPinAnnotationView
        
        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView!.animatesDrop = true
            pinView!.draggable = true
            pinView!.canShowCallout = false
            pinView!.pinTintColor = UIColor.redColor()
            
            // Set annotation as selected so that it is draggable after being created
            pinView!.setSelected(true, animated: true)
        }
        else {
            pinView!.annotation = annotation
        }
        
        return pinView
    }
    
    func mapView(mapView: MKMapView, didSelectAnnotationView view: MKAnnotationView) {

        if deleteMode == false {
            
            // Deselect annotation from map view so that it can be tapped again without having to first be deselected by the user
            mapView.deselectAnnotation(view.annotation, animated: false)
            
            // Set annotation view as selected so that it is draggable
            view.setSelected(true, animated: true)
            
            // If annotation view is selected by tapping (instead of by dragging), segue to PhotoAlbumViewController
            if dragged == false {
                
                performSegueWithIdentifier("showAlbum", sender: view)
                
            } else {
                // If 'dragged' was true, set to false to enable push to PhotoAlbumViewController by tapping on annotation view
                dragged = false
            }
        }
        
        else {
            let selectedPin = (view.annotation as! PointAnnotation).pin
            
            pins.removeAtIndex(pins.indexOf(selectedPin!)!)
            print("annotation removed")
            
            mapView.removeAnnotation(view.annotation!)
            
            sharedContext.deleteObject(selectedPin!)
            saveContext()
        }
    }
    
    func mapView(mapView: MKMapView, annotationView view: MKAnnotationView, didChangeDragState newState: MKAnnotationViewDragState, fromOldState oldState: MKAnnotationViewDragState) {
        
        let selectedPin = (view.annotation as! PointAnnotation).pin
        
        switch newState {
        case .Starting:
            print("drag starting")
            
            // Delete old photos from pin
            for photo in selectedPin.photos {
                
                // Remove association with Pin object
                photo.pin = nil
                
                // Remove Photo object from context
                sharedContext.deleteObject(photo)
            }
            
        case .Canceling, .Ending:
            print("drag ended")
            
            let draggedAnnotation = view.annotation
            print("annotation dropped at: \(draggedAnnotation!.coordinate.latitude), \(draggedAnnotation!.coordinate.longitude)")
            
            selectedPin.latitude = draggedAnnotation!.coordinate.latitude
            selectedPin.longitude = draggedAnnotation!.coordinate.longitude
            
            // Since annotation view will be automatically selected after dragging occurs, set to true so that push to PhotoAlbumViewController doesn't occur
            dragged = true
            
            selectedPin!.getPhotosCompleted = false
            
            // Save the context
            saveContext()
            
            // Pre-fetch new photos for pin
            getPhotosURLArrayFromFlickr(selectedPin!)
            
        default:
            return
        }
    }
    
    
    // MARK: - Segue
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "showAlbum" {
            
            let photoAlbumVC = segue.destinationViewController as! PhotoAlbumViewController
            
            photoAlbumVC.coordinate = (sender as! MKAnnotationView).annotation!.coordinate
            photoAlbumVC.pin =  ((sender as! MKAnnotationView).annotation as! PointAnnotation).pin
            photoAlbumVC.mapViewRegion = mapView.region
            photoAlbumVC.prefetched = prefetched
        }
    }
    
    
    // MARK: - Helper Methods
    
    // Get images from Flickr
    func getPhotosURLArrayFromFlickr(selectedPin: Pin) {
        
        let latitude = selectedPin.latitude as Double
        let longitude = selectedPin.longitude as Double
        FlickrClient.sharedInstance().getPhotosURLArrayByLocation(latitude, longitude: longitude) {
            (success, photosArray, errorString) in
            
            if success {
                
                if !photosArray.isEmpty {
                    
                    self.prefetched = true
                    
                    self.sharedContext.performBlockAndWait({
                        
                        // Create photo objects and append to selectedPin's photos array
                        for photo in photosArray {
                            
                            let photoObject = Photo(dictionary: photo, context: self.sharedContext)
                            
                            // Add photoObject to Pin's photos array
                            photoObject.pin = selectedPin
                        }
                        
                        // Save the context
                        self.saveContext()
                    })
                    
                    print("Photos downloaded successfully.")
                }
                    
                else {
                    print("No images found.")
                }
                
                self.sharedContext.performBlockAndWait({
                    selectedPin.getPhotosCompleted = true
                })
            }
                
            else {
                print(errorString!)
            }
        }
    }
}

