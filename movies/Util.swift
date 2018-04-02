//
//  Util.swift
//  movies
//
//  Created by Jerry Hale on 4/11/17.
//  Copyright © 2018 jhale. All rights reserved.
//

import CoreLocation
import UIKit

//	MARK: EmptySegue
class EmptySegue: UIStoryboardSegue
{
    override func perform()
	{

	}
}


//	MARK: CustomSegue
class CustomSegue: UIStoryboardSegue
{
    override func perform()
	{
		UIView.animate(withDuration:0.6, animations:
		{
			self.source.view.alpha = 0.3
            self.destination.view.alpha = 1.0

            }, completion: { finished in
				self.source.present(self.destination, animated: false, completion: nil)
        })
    }
}

//	MARK: CustomUnwindSegue
class CustomUnwindSegue: UIStoryboardSegue
{
    override func perform()
	{
        UIView.animate(withDuration: 0.6, animations:
		{
			self.source.view.alpha = 0.3
			self.destination.view.alpha = 1.0

            }, completion: { finished in
                self.source.dismiss(animated: false, completion: nil)
        })
    }
}


//	typedef void (^Callback)(true isSuccess, String object)
protocol GeocodeDelegate {
    func geocodeDidSucceed(placemark: CLPlacemark?, error: Error?)
    func geocodeDidFail(placemark: CLPlacemark?, error: Error?)
}
class Geocode {

	let geocoder = CLGeocoder()
	var delegate: GeocodeDelegate
	
	init(withDelegate delegate: GeocodeDelegate) { self.delegate = delegate }
	
	func geocodePostalCode(postalcode: String)
	{
//		let country = "USA"
//		let street = "Conklin Rd."
//		let city = "Big Bear Lake"
//		let state = "CA"
//		let postalcode = "92315"

        // Create Address String
        //	let address = "\(country), \(city), \(street), \(state), \(postalcode)"
		let address = "\(postalcode)"

        // Geocode Address String
        geocoder.geocodeAddressString(address)
		{ (placemarks, error) in
            // Process Response
        // Update View
			if let error = error
			{
				self.delegate.geocodeDidSucceed(placemark: nil, error: error)
				print("Unable to Forward Geocode Address (\(error))")
			}
			else
			{
				var location: CLLocation?
				
				if let placemarks = placemarks, placemarks.count > 0
				{
					location = placemarks.first?.location
					
					if let location = location
					{
						let coordinate = location.coordinate
						print("\(coordinate.latitude), \(coordinate.longitude)")
						self.delegate.geocodeDidSucceed(placemark: placemarks.first, error: error)
					}
					else
					{
						self.delegate.geocodeDidSucceed(placemark: nil, error: error)
					}
				}
			}
        }
    }

	//	let location = CLLocation(latitude: 34.243896, longitude: -116.911422)
	func reverseGeocodePostalCode(latitude: CLLocationDegrees, longitude: CLLocationDegrees)
	{
		//	34.243896
		//	create Location
		let location = CLLocation(latitude: latitude, longitude: longitude)

		// Geocode Location
	
		geocoder.reverseGeocodeLocation(location)
		{
			(placemarks, error) in
				//	process response
			
				// Update View
				//  geocodeButton.isHidden = false
				//  activityIndicatorView.stopAnimating()

				if let error = error { print("Unable to Reverse Geocode Location (\(error))") }
				else
				{
					if let placemarks = placemarks, let placemark = placemarks.first
					{
						//	postalcode = placemark.postalCode!
						self.delegate.geocodeDidSucceed(placemark: placemark, error: error)
					}
					else
					{
						self.delegate.geocodeDidFail(placemark: nil, error: error!)
						print("No Matching Addresses Found")
					}
				}
		}
	}
}

func createGenericPoster(_ title: String) -> UIImage
{
	var image = UIImage(named: "filmclip.png")

	UIGraphicsBeginImageContext((image?.size)!)
	
	image?.draw(in: CGRect(x: 0, y: 0, width: (image?.size.width)!, height: (image?.size.height)!))

	let titleString =
				NSMutableAttributedString(string: title,
			attributes: [.font:UIFont(name: "Helvetica Neue", size: 14)!])

	let red = CGFloat((0x333333 & 0xFF0000) >> 16) / 255.0
	let green = CGFloat((0x333333 & 0x00FF00) >> 8) / 255.0
	let blue = CGFloat(0x333333 & 0x00FF) / 255.0

	titleString.addAttribute(
			.foregroundColor,
				value: UIColor(red: red,
								green: green,
								blue: blue,
								alpha: 1.0),
				range: NSRange(location:0, length:titleString.length))

	let paraStyle = NSMutableParagraphStyle()
	paraStyle.alignment = .center

	titleString.addAttribute(.paragraphStyle, value:paraStyle, range:NSRange(location:0, length:titleString.length))

	titleString.draw(in: CGRect(x: 24, y: 50, width: (image?.size.width)! - 48, height: (image?.size.height)!))

	image = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext()

	return (image!)
}

func getTicketPurchasePageUrl(tmsID: String, theaterId: String, date: String, time: String) -> String
{
	//"07-18-2007+22:25"
	
//	let isPM = ("PM" == time.substring(from: time.index(time.endIndex, offsetBy: -2)))
//
//	let hour = time.substring(to: time.index(time.startIndex, offsetBy: 2))
//	var min = time.substring(from: time.index(time.startIndex, offsetBy: 2))
//
//	min = min.substring(to: min.index(min.endIndex, offsetBy: -3))
	//	print(hour)
	//	print(min)
	
//	var timeStr = hour + min
	
//	if (isPM)
//	{
//		if (Int(hour)! < 12)
//		{
//			let fmt = Int(hour)! + 12
//
//			timeStr = String(fmt) + min;
//		}
//	}
//	else if (Int(hour)! == 12) { timeStr = "00" + min }
	
	//	print(timeStr)
	
	//	theaterId = fandangoIDForTheaterID(theaterId);
	
	let url = ""

	//	print(url)
	return (url)
}


