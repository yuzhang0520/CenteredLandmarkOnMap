//
//  MapViewController.swift
//  YuZhangAssignment1
//
//  Created by Xcode User on 2020-10-11.
//  Copyright © 2020 Xcode User. All rights reserved.
//

import UIKit
import CoreLocation
import MapKit

class MapViewController: UIViewController, UITextFieldDelegate, MKMapViewDelegate, CLLocationManagerDelegate, UITableViewDelegate, UITableViewDataSource {
    
    let locationMananger = CLLocationManager()
    
    // Hard code the initial location to Sheridan
    let initialLocation = CLLocation(latitude: 43.655787, longitude: -79.739534)
    
    var wp1Location = CLLocation()
    var wp2Location = CLLocation()
    var destination = CLLocation()
    
    var routeSetpsWP1 = ["Enter a destination to see the step"]
    
    var routeSetpsWP2 = ["Enter a destination to see the step"]
    
    var routeSetpsDes = ["Enter a destination to see the step"]
    
    var routeSetps = ["Enter a destination to see the step"]
    
    @IBOutlet var myMapView : MKMapView!
    
    @IBOutlet var tbLocEntered : UITextField!
    @IBOutlet var tbWaypoint1 : UITextField!
    @IBOutlet var tbWaypoint2 : UITextField!
    
    @IBOutlet var lbMessage : UILabel!
    
    @IBOutlet var sgmtChagneSteps : UISegmentedControl!
    
    @IBOutlet var myTableView : UITableView!
    
    @IBAction func changeSteps( _ sender : UISegmentedControl){
        
        if sender.selectedSegmentIndex == 0 {
            self.routeSetps.removeAll()
            self.routeSetps = self.routeSetpsWP1
            self.myTableView.reloadData()
        } else if sender.selectedSegmentIndex == 1 {
            self.routeSetps.removeAll()
            self.routeSetps = self.routeSetpsWP2
            self.myTableView.reloadData()
        } else {
            self.routeSetps.removeAll()
            self.routeSetps = self.routeSetpsDes
            self.myTableView.reloadData()
        }
    }
    
    
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        return textField.resignFirstResponder()
    }

    let regionRadius : CLLocationDistance = 15000
    func centerMapOnLocation(location : CLLocation){
        let coordinateRegion = MKCoordinateRegion(center: location.coordinate, latitudinalMeters: regionRadius * 2.0, longitudinalMeters: regionRadius * 2.0)
        myMapView.setRegion(coordinateRegion, animated: true)
    }
    
    func addBoudingCircle(location : CLLocation){
        myMapView.removeOverlays(myMapView.overlays)
        let circle = MKCircle(center: location.coordinate, radius: 30000.0)
        
        myMapView.addOverlay(circle)
    }
    
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {

        if overlay is MKPolyline {
            let renderer = MKPolylineRenderer(overlay: overlay)
            renderer.strokeColor = UIColor.blue
            renderer.lineWidth = 3.0;
            return renderer
        } else if overlay is MKCircle{
            let circleRenderer = MKCircleRenderer(overlay: overlay)
            circleRenderer.strokeColor = .red
            circleRenderer.fillColor = .red
            circleRenderer.alpha = 0.2
            return circleRenderer
        }
        return MKOverlayRenderer()
    }

//    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
//
//        guard let circleOverlay = overlay as? MKCircle else { return MKOverlayRenderer()}
//
//        let circleRenderer = MKCircleRenderer(circle: circleOverlay)
//        circleRenderer.strokeColor = .red
//        circleRenderer.fillColor = .red
//        circleRenderer.alpha = 0.2
//
//        return circleRenderer
//    }
    
    func isInBounding(location : CLLocation){
//        let newCoordinate = MKMapPoint.init(location.coordinate)
//        let mapRect = myMapView.visibleMapRect
//        var inside : Bool!
//        if (inside == myMapView.visibleMapRect.contains(newCoordinate)){
//            lbMessage.text = "This location is inside the bounding area."
//        }else{
//            lbMessage.text = "This location is outside the bounding area."
//        }
        
        if location.distance(from: initialLocation) > 30000.0 {
            lbMessage.text = "This location is outside the bounding area."
        }else{
            lbMessage.text = "This location is inside the bounding area."
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        centerMapOnLocation(location: initialLocation)
        addBoudingCircle(location: initialLocation)
        let dropPin = MKPointAnnotation()
        dropPin.coordinate = initialLocation.coordinate
        dropPin.title = "Starting at Sheridan College"
        self.myMapView.addAnnotation(dropPin)
        self.myMapView.selectAnnotation(dropPin, animated: true)
    }
    
    
    @IBAction func findNewLocation(){
        
        let locEnteredText = tbLocEntered.text
        
        let wp1Text = tbWaypoint1.text
        
        let wp2Text = tbWaypoint2.text
        
        let geocoderWP1 = CLGeocoder()
        
        self.routeSetps.removeAll()
        self.myTableView.reloadData()
        
        geocoderWP1.geocodeAddressString(wp2Text!, completionHandler:
            
            {(placemarks, error) -> Void in
                if(error != nil){
                    print("Error", error)
                }
                if let placemark = placemarks?.first{
                    let coordinates : CLLocationCoordinate2D = placemark.location!.coordinate
                    
                    self.wp1Location = CLLocation(latitude: coordinates.latitude, longitude: coordinates.longitude)
                    
                    let dropPin = MKPointAnnotation()
                    dropPin.coordinate = coordinates
                    dropPin.title = placemark.name
                    self.myMapView.addAnnotation(dropPin)
                    self.myMapView.selectAnnotation(dropPin, animated: true)
                    
                    let request = MKDirections.Request()
                    request.source = MKMapItem(placemark: MKPlacemark(coordinate: self.initialLocation.coordinate, addressDictionary: nil))
                    request.destination = MKMapItem(placemark: MKPlacemark(coordinate: coordinates, addressDictionary: nil))
                    request.requestsAlternateRoutes = false
                    request.transportType = .automobile
                    
                    let directions = MKDirections(request: request)
                    directions.calculate(completionHandler:
                        {[unowned self] response, error in
                            
                            for route in (response?.routes)!{
                                
                                self.myMapView.addOverlay(route.polyline, level:MKOverlayLevel.aboveRoads)
                                self.myMapView.setVisibleMapRect(route.polyline.boundingMapRect, animated: true)
                                
                                self.routeSetpsWP1.removeAll()
                                self.routeSetps.removeAll()
                                for step in route.steps {
                                    self.routeSetpsWP1.append(step.instructions)
                                    self.routeSetps.append(step.instructions)
                                    self.myTableView.reloadData()
                                }
                            }
                        }
                    )
                }
                
        }
        )
        
        let geocoderWP2 = CLGeocoder()
        
        geocoderWP2.geocodeAddressString(wp1Text!, completionHandler:
            
            {(placemarks, error) -> Void in
                if(error != nil){
                    print("Error", error)
                }
                if let placemark = placemarks?.first{
                    let coordinates : CLLocationCoordinate2D = placemark.location!.coordinate
                    
                    self.wp2Location = CLLocation(latitude: coordinates.latitude, longitude: coordinates.longitude)
                    
                    let dropPin = MKPointAnnotation()
                    dropPin.coordinate = coordinates
                    dropPin.title = placemark.name
                    self.myMapView.addAnnotation(dropPin)
                    self.myMapView.selectAnnotation(dropPin, animated: true)
                    
                    let request = MKDirections.Request()
                    request.source = MKMapItem(placemark: MKPlacemark(coordinate: self.wp1Location.coordinate, addressDictionary: nil))
                    request.destination = MKMapItem(placemark: MKPlacemark(coordinate: coordinates, addressDictionary: nil))
                    request.requestsAlternateRoutes = false
                    request.transportType = .automobile
                    
                    let directions = MKDirections(request: request)
                    directions.calculate(completionHandler:
                        {[unowned self] response, error in
                            
                            for route in (response?.routes)!{
                                
                                self.myMapView.addOverlay(route.polyline, level:MKOverlayLevel.aboveRoads)
                                self.myMapView.setVisibleMapRect(route.polyline.boundingMapRect, animated: true)
                                
                                self.routeSetpsWP2.removeAll()
                                for step in route.steps {
                                    self.routeSetpsWP2.append(step.instructions)
                                }
                            }
                        }
                        
                    )
                }
        }
        )
        
        let geocoder = CLGeocoder()
        
        geocoder.geocodeAddressString(locEnteredText!, completionHandler:
            
            {(placemarks, error) -> Void in
                if(error != nil){
                    print("Error", error)
                }
                if let placemark = placemarks?.first{
                    let coordinates : CLLocationCoordinate2D = placemark.location!.coordinate
                    
                    let newLocation = CLLocation(latitude: coordinates.latitude, longitude: coordinates.longitude)
                    self.isInBounding(location: newLocation)
                    self.centerMapOnLocation(location: newLocation)
                    
                    let dropPin = MKPointAnnotation()
                    dropPin.coordinate = coordinates
                    dropPin.title = placemark.name
                    self.myMapView.addAnnotation(dropPin)
                    self.myMapView.selectAnnotation(dropPin, animated: true)
                    
                    let request = MKDirections.Request()
                    request.source = MKMapItem(placemark: MKPlacemark(coordinate: self.initialLocation.coordinate, addressDictionary: nil))
                    request.destination = MKMapItem(placemark: MKPlacemark(coordinate: coordinates, addressDictionary: nil))
                    request.requestsAlternateRoutes = false
                    request.transportType = .automobile
                    
                    let directions = MKDirections(request: request)
                    directions.calculate(completionHandler:
                        {[unowned self] response, error in
                            
                            for route in (response?.routes)!{
                                
                                self.myMapView.addOverlay(route.polyline, level:MKOverlayLevel.aboveRoads)
                                self.myMapView.setVisibleMapRect(route.polyline.boundingMapRect, animated: true)
                                
                                self.routeSetpsDes.removeAll()
                                for step in route.steps {
                                    self.routeSetpsDes.append(step.instructions)
//                                    self.myTableView.reloadData()
                                }
                            }
                        }
                    )
                }
                
        }
        )
        
        self.routeSetps.removeAll()
        self.routeSetps = self.routeSetpsWP1
        self.myTableView.reloadData()
    }
    
//    @IBAction func findNewLocation(){
//
//        let locEnteredText = tbLocEntered.text
//
//        let geocoder = CLGeocoder()
//
//        geocoder.geocodeAddressString(locEnteredText!, completionHandler:
//
//            {(placemarks, error) -> Void in
//                if(error != nil){
//                    print("Error", error)
//                }
//                if let placemark = placemarks?.first{
//                    let coordinates : CLLocationCoordinate2D = placemark.location!.coordinate
//
//                    let newLocation = CLLocation(latitude: coordinates.latitude, longitude: coordinates.longitude)
//                    self.isInBounding(location: newLocation)
//                    self.centerMapOnLocation(location: newLocation)
//
//                    let dropPin = MKPointAnnotation()
//                    dropPin.coordinate = coordinates
//                    dropPin.title = placemark.name
//                    self.myMapView.addAnnotation(dropPin)
//                    self.myMapView.selectAnnotation(dropPin, animated: true)
//
//                    let request = MKDirections.Request()
//                    request.source = MKMapItem(placemark: MKPlacemark(coordinate: self.initialLocation.coordinate, addressDictionary: nil))
//                    request.destination = MKMapItem(placemark: MKPlacemark(coordinate: coordinates, addressDictionary: nil))
//                    request.requestsAlternateRoutes = false
//                    request.transportType = .automobile
//
//                    let directions = MKDirections(request: request)
//                    directions.calculate(completionHandler:
//                        {[unowned self] response, error in
//
//                            for route in (response?.routes)!{
//
//                                self.myMapView.addOverlay(route.polyline, level:MKOverlayLevel.aboveRoads)
//                                self.myMapView.setVisibleMapRect(route.polyline.boundingMapRect, animated: true)
//
//                                self.routeSetps.removeAll()
//                                for step in route.steps {
//                                    self.routeSetps.append(step.instructions)
//                                    self.myTableView.reloadData()
//                                }
//                            }
//                        }
//
//                    )
//                }
//
//        }
//        )
//    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return routeSetps.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 30
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let tableCell = tableView.dequeueReusableCell(withIdentifier: "cell") ?? UITableViewCell()
        
        tableCell.textLabel?.text = routeSetps[indexPath.row]
        
        return tableCell
    }
    
    func isBounding(location : CLLocation){
        //        let region = self.myMapView.region
        //        let center = region.center
        //        let span = region.span
        //        let newCoordinate = location.coordinate
        //
        //        if(cos((center.latitude - newCoordinate.latitude) * Double.pi / 180.0) > cos(span.latitudeDelta / 2.0 * Double.pi / 180.0) &&
        //            cos((center.longitude - newCoordinate.longitude) * Double.pi / 180) > cos(span.longitudeDelta / 2.0 * Double.pi / 180)){
        //            lbMessage.text = "This location is outside the bounding area."
        //        }else{
        //            lbMessage.text = "This location is inside the bounding area."
        //        }
        
        let region = MKCoordinateRegion(center: initialLocation.coordinate, latitudinalMeters: regionRadius * 2.0, longitudinalMeters: regionRadius * 2.0)
        let center = region.center
        let northWestCorner = CLLocationCoordinate2D(latitude: center.latitude - (region.span.latitudeDelta / 2.0), longitude: center.longitude - (region.span.longitudeDelta / 2.0))
        let southEastCorner = CLLocationCoordinate2D(latitude: center.latitude + (region.span.latitudeDelta / 2.0), longitude: center.longitude + (region.span.longitudeDelta / 2.0))
        
        if (location.coordinate.latitude >= northWestCorner.latitude &&
            location.coordinate.latitude <= southEastCorner.latitude &&
            location.coordinate.longitude >= northWestCorner.longitude &&
            location.coordinate.longitude <= southEastCorner.longitude)
        {
            lbMessage.text = "This location is outside the bounding area."
        }
        else
        {
            lbMessage.text = "This location is inside the bounding area."
        }
        
        
    }


    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
