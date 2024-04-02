//
//  ViewController.swift
//  MapsApp
//
//  Created by Cihan on 26.01.2024.
//

import UIKit
import MapKit
import CoreLocation
import CoreData

class MapsViewController: UIViewController,MKMapViewDelegate,CLLocationManagerDelegate {
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var textFieldAnnotationName: UITextField!
    @IBOutlet weak var textFieldSubtitleText: UITextField!
    
    var locationManager = CLLocationManager()
    
    var selectedLatitude = Double()
    var selectedLongitude = Double()
    
    var selectedName = ""
    var selectedId : UUID?
    
    var annotationTitle = ""
    var annotationSubtitle = ""
    var annotationLatitude = Double()
    var annotationLongitude = Double()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mapView.delegate  = self
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        
        let gestureRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(selectLocation(gestureRecognizer:)))
        gestureRecognizer.minimumPressDuration =  3
        mapView.addGestureRecognizer(gestureRecognizer)
        
        if selectedName != "" {
             //CoreData
            if let uuidString = selectedId?.uuidString {
                let appDelegate = UIApplication.shared.delegate as! AppDelegate
                let context = appDelegate.persistentContainer.viewContext
                
                let request = NSFetchRequest<NSFetchRequestResult>(entityName: "Annotation")
                request.predicate = NSPredicate(format: "id = %@", uuidString)
                request.returnsObjectsAsFaults = false
                
                do {
                    let results = try context.fetch(request)
                    
                    if results.count > 0 {
                        
                        for result in results as![NSManagedObject] {
                            if let name = result.value(forKey: "name") as? String {
                                annotationTitle = name
                                textFieldAnnotationName.text = name
                                
                                if let subtitle = result.value(forKey: "subtitle") as? String {
                                    annotationSubtitle = subtitle
                                    textFieldSubtitleText.text = subtitle
                                    
                                    if let latitude = result.value(forKey: "latitude") as? Double {
                                        annotationLatitude = latitude
                                        
                                        if let longitude = result.value(forKey: "longitude") as? Double {
                                            annotationLongitude = longitude
                                            
                                            let annotation = MKPointAnnotation()
                                            annotation.title = annotationTitle
                                            annotation.subtitle = annotationSubtitle
                                            let coordinate = CLLocationCoordinate2D(latitude: annotationLatitude, longitude: annotationLongitude)
                                            annotation.coordinate = coordinate
                                            
                                            mapView.addAnnotation(annotation)
                                            locationManager.stopUpdatingLocation()
                                            
                                            let span = MKCoordinateSpan(latitudeDelta: 0.005, longitudeDelta: 0.005)
                                            let region = MKCoordinateRegion(center: coordinate, span: span)
                                            mapView.setRegion(region, animated: true)
                                        }
                                    }
                                }
                            }
                        }
                    }
                    
                } catch {
                    self.alertMessage(title: "LOADING ERROR", message: "An error occurred while retrieving data from the Database")
                }
            }
        } else {
            //New Data
        }
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation is MKUserLocation {
            return nil
        }
        let reuseId = "myAnnotationId"
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId)
        
        if pinView == nil {
            
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView?.canShowCallout = true
            pinView?.tintColor = .red
            
            let button = UIButton(type: .detailDisclosure)
            pinView?.rightCalloutAccessoryView = button
            
        } else {
            pinView?.annotation = annotation
        }
        
        return pinView
    }
    
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView, calloutAccessoryControlTapped control: UIControl) {
        if selectedName != "" {
            var requestLocation = CLLocation(latitude: annotationLatitude, longitude: annotationLongitude)
            CLGeocoder().reverseGeocodeLocation(requestLocation) { ( placemarkarray, error) in
                if let placemarks = placemarkarray {
                    if placemarks.count > 0 {
                        let newplacemark = MKPlacemark(placemark: placemarks[0])
                        let item = MKMapItem(placemark: newplacemark)
                        item.name = self.annotationTitle
                        let launchOptions = [MKLaunchOptionsDirectionsModeKey : MKLaunchOptionsDirectionsModeDriving]
                         
                        item.openInMaps(launchOptions: launchOptions )
                    }
                }
            }
        }
    }
    
    
    @objc func selectLocation(gestureRecognizer:UILongPressGestureRecognizer) {
        if gestureRecognizer.state == .began {
            let touchedPoint = gestureRecognizer.location(in: mapView)
            let touchedCoordinate = mapView.convert(touchedPoint, toCoordinateFrom:mapView)
            
            selectedLatitude = touchedCoordinate.latitude
            selectedLongitude = touchedCoordinate.longitude
            
            let annotation = MKPointAnnotation()
            annotation.coordinate = touchedCoordinate
            annotation.title = textFieldAnnotationName.text
            annotation.subtitle = textFieldSubtitleText.text
            mapView.addAnnotation(annotation)
        }
    }
    
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if selectedName == "" {
            let location = CLLocationCoordinate2D(latitude: locations[0].coordinate.latitude, longitude: locations[0].coordinate.longitude)
            let span = MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
            let region = MKCoordinateRegion(center: location, span: span)
            mapView.setRegion(region, animated: true)
        } else {
            
        }
       
    }
    @IBAction func buttonSave(_ sender: Any) {
        let appDelegate = UIApplication.shared.delegate as! AppDelegate
        let context = appDelegate.persistentContainer.viewContext
        
        let newAnnotation = NSEntityDescription.insertNewObject(forEntityName: "Annotation", into: context)
        
        newAnnotation.setValue(textFieldAnnotationName.text, forKey: "name")
        newAnnotation.setValue(textFieldSubtitleText.text, forKey: "subtitle")
        newAnnotation.setValue(selectedLatitude, forKey: "latitude")
        newAnnotation.setValue(selectedLongitude, forKey: "longitude")
        newAnnotation.setValue(UUID(), forKey: "id")
        
        do {
            try context.save()
            //self.alertMessage(title: "SAVE SUCCESSFUL", message: "Registration to the database was successful")
            NotificationCenter.default.post(name: NSNotification.Name("CreateNewAnnotation"), object: nil)
            navigationController?.popViewController(animated: true)
        } catch {
            self.alertMessage(title: "SAVE ERROR", message: "An error occurred while saving to the database")
        }
    }
    

    
    func alertMessage(title:String,message:String) {
        let alertMessage = UIAlertController(title: title, message: message, preferredStyle: UIAlertController.Style.alert)
        
        let okButton = UIAlertAction(title: "OK", style: UIAlertAction.Style.default)
        
        alertMessage.addAction(okButton)
        self.present(alertMessage, animated: true, completion: nil)
    }
    

}

