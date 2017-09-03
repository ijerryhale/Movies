

import UIKit
import MapKit
import Contacts
import CoreLocation

class MapViewController: UIViewController
{
    var placemark: MKPlacemark?
    let locationManager = CLLocationManager()

    @IBOutlet weak var mapView: MKMapView!

	private func add_annotation_at_theater_address()
	{
		//	let nameString = "West Wind El Rancho Drive-In"
		//	let addressString = "555 El Rancho Drive, Sparks NV 89431"
		let index = gState[KEY_CO_INDEX] as! Int
		let theater = gTheater[index]
		
		let nameString = theater[KEY_NAME] as? String
		
		let aa = theater[KEY_ADDRESS]
		var addressString = aa?[KEY_STREET] as! String

		addressString += " "
		addressString += aa?[KEY_CITY] as! String
		addressString += ", "
		addressString += aa?[KEY_STATE] as! String

		let request = MKLocalSearchRequest()
        request.naturalLanguageQuery = addressString

        request.region = mapView.region
        let search = MKLocalSearch(request: request)
        
        search.start { response, _ in
            guard let response = response else { return }
            var matchingItems: [MKMapItem] = response.mapItems
			
			let placemark = matchingItems[0].placemark
			//	print(placemark)

			let annotation = MKPointAnnotation()
			annotation.coordinate = placemark.coordinate
			annotation.title = nameString

			if let number = placemark.subThoroughfare,
				let street = placemark.thoroughfare,
				let city = placemark.locality,
				 let state = placemark.administrativeArea,
					let zip = placemark.postalCode
				{ annotation.subtitle = "\(number) \(street) \(city), \(state) \(zip)" }
			
			self.mapView.addAnnotation(annotation)
			self.placemark = placemark
        }
	}

	func getDirections()
	{
        guard let placemark = placemark else { return }
        let mapItem = MKMapItem(placemark: placemark)
        let launchOptions = [MKLaunchOptionsDirectionsModeKey: MKLaunchOptionsDirectionsModeDriving]
        mapItem.openInMaps(launchOptions: launchOptions)
    }


	override func viewWillDisappear(_ animated: Bool)
	{ super.viewWillDisappear(animated); print("MapViewController viewWillDisappear ") }

    override func viewDidLoad()
	{ super.viewDidLoad(); print("MapViewController viewDidLoad ")
		
		definesPresentationContext = true

		locationManager.delegate = self
		locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.requestLocation()
 
		locationManager.startUpdatingLocation()
		
 		mapView.delegate = self
		mapView.showsUserLocation = true

		add_annotation_at_theater_address()
	}
}

extension MapViewController : CLLocationManagerDelegate
{
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus)
	{
        if status == .authorizedWhenInUse { locationManager.requestLocation() }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) { }
	
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error)
	{
        print("error:: \(error)")
    }
}

extension MapViewController : MKMapViewDelegate
{
	func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation)
	{
		//	zoom to level which shows both annotations
		mapView.showAnnotations(mapView.annotations, animated: true)
	}

    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView?
	{
		print(annotation)
		
        guard !(annotation is MKUserLocation) else { return nil }
        let reuseId = "pin"
        var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuseId) as? MKPinAnnotationView
        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
        }
        pinView?.pinTintColor = UIColor.blue
        pinView?.canShowCallout = true
        let smallSquare = CGSize(width: 48, height: 48)
        let button = UIButton(frame: CGRect(origin: CGPoint.zero, size: smallSquare))
        button.setBackgroundImage(UIImage(named: "theater"), for: UIControlState())
        button.addTarget(self, action: #selector(MapViewController.getDirections), for: .touchUpInside)
        pinView?.leftCalloutAccessoryView = button
        
        return pinView
    }
}
