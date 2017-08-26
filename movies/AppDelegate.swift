//
//  AppDelegate.swift
//  Movies
//
//  Created by Jerry Hale on 9/8/16.
//  Copyright © 2017 jhale. All rights reserved.
//

import UIKit
import CoreLocation

enum COType {
	case cot_app_launch
	case cot_theater_detail
	case cot_movie_detail
}

var gDayOffset = 0
var gState = [KEY_CO_STATE : COType.cot_app_launch, KEY_CO_INDEX : 0] as [String : Any]
var gPostalCode = "92315"

var gIndex = [[String : AnyObject]]()
var gTheater = [[String : AnyObject]]()
var gMovie = [[String : AnyObject]]()

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, GeocodeDelegate
{
	var window: UIWindow?

	private func topViewControllerWithRootViewController(rootViewController: UIViewController!) -> UIViewController?
	{
		if (rootViewController == nil) { return nil }
		
		if (rootViewController.isKind(of: (UITabBarController).self))
		{
			return topViewControllerWithRootViewController(rootViewController: (rootViewController as! UITabBarController).selectedViewController)
		}
		else if (rootViewController.isKind(of:(UINavigationController).self))
		{
			return topViewControllerWithRootViewController(rootViewController: (rootViewController as! UINavigationController).visibleViewController)
		}
		else if (rootViewController.presentedViewController != nil)
		{
			return topViewControllerWithRootViewController(rootViewController: rootViewController.presentedViewController)
		}
		
		return rootViewController
	}

	func handleNetworkError(error: Error?) { print("handleNetworkError: ", error as Any) }
	func handleNoDataAvailable(error: Error?) { print("handleNoDataAvailable: ", error as Any) }

	private func process_theaters()
	{ print("process_theaters start")

		//	sort the Theaters by Theater name
		gTheater.sort { ($0[KEY_NAME]! as! String) < ($1[KEY_NAME]! as! String) }

		//	create a set to hold Movie tms_id's
		let tms_id: NSMutableSet = NSMutableSet()

		#if HAS_WEB_SERVICE
			//	have to remove BASE_URL from path
			var baseURL = DataAccess.url_BASE()
			let range = baseURL?.range(of:"s")
			if let startLocation = range?.lowerBound,
			let endLocation = range?.upperBound
			{
				baseURL?.replaceSubrange(startLocation ..< endLocation, with: "")
				baseURL = baseURL! + "/"
			}
		#endif

		//	loop thru the Theaters and create a unique set of Movies
		for i in 0...gTheater.count - 1
		{
			var t = gTheater[i] as [String : AnyObject]
			
			if (t[KEY_RELEASE_DATE] as? NSNull) != nil { gTheater[i][KEY_RELEASE_DATE] = "" as AnyObject }
			if (t[KEY_RUN_TIME] as? NSNull) != nil { gTheater[i][KEY_RUN_TIME] = "" as AnyObject }
			if (t[KEY_TOMATO_RATING] as? NSNull) != nil  { gTheater[i][KEY_TOMATO_RATING] = "" as AnyObject }

			//	thisMov is one Movie in this Theaters 'now_showing' array
			for thisMov in t[KEY_NOW_SHOWING] as! [[String:AnyObject]]
			{
				let tmsid = (thisMov as [String : AnyObject])[KEY_TMS_ID] as! String

				if tms_id.contains(tmsid) { continue }

				tms_id.add(tmsid)
				
				gMovie.append(thisMov);
			}
		}

		//	sort the Movies by Movie rating, title
		gMovie.sort
		{
			let lhsrating = $0[KEY_RATING]! as! String
			let rhsrating = $1[KEY_RATING]! as! String
				
			if lhsrating != rhsrating { return lhsrating < rhsrating }
			else { return ($0[KEY_TITLE]! as! String) < ($1[KEY_TITLE]! as! String) }
		}
		
		//	for index in stride(from: self.movie.count - 1, through: 3, by: -1)
		//	{
		//		self.movie.removeObject(at: index)
		//	}
		
		print("process_theaters end")
	}

    func geocodeDidSucceed(placemark: CLPlacemark?, error: Error?)
	{
		gPostalCode = (placemark?.postalCode)!
		print("geocodeDidSucceed (\(gPostalCode))")
	}
	
    func geocodeDidFail(placemark: CLPlacemark?, error: Error?)
	{
		gPostalCode = "92315"
		print("geocodeDidFail (\(error?.localizedDescription))")
	}

	func reloadTheaters()
	{
		DataAccess().gettheaters(getShowDateFromDayOffset(dayoffset: gDayOffset + DAY_OFFSET),
									postalcode: gPostalCode)
		{
			(theaters, error) in

			//	print(theaters?.count)
			if (error != nil) { self.handleNetworkError(error: error); return }
			else if theaters?.count == 0 { self.handleNoDataAvailable(error: error); return }

			gTheater = theaters  as! [[String : AnyObject]]
			self.process_theaters()
		}
	}

//	func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask
//	{
//        
//        if self.window?.rootViewController?.presentedViewController is BoxOfficeController {
//            
//            return UIInterfaceOrientationMask.all;
//            
//        } else {
//            return UIInterfaceOrientationMask.all;
//        }
//    }

	func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask
	{
		if let rootViewController = self.topViewControllerWithRootViewController(rootViewController: window?.rootViewController)
		{
			if (rootViewController.responds(to: Selector(("canRotate"))))
			{
				// Unlock landscape view orientations for this view controller
				return .allButUpsideDown;
			}
		}

		//	only allow portrait (standard behaviour)
		return .portrait;
	}

	func applicationWillResignActive(_ application: UIApplication)
	{
		// Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
		// Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
	}

	func applicationDidEnterBackground(_ application: UIApplication)
	{
		// Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
		// If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
	}

	func applicationWillEnterForeground(_ application: UIApplication)
	{
		// Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
	}

	func applicationDidBecomeActive(_ application: UIApplication)
	{
		// Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
	}

	func applicationWillTerminate(_ application: UIApplication)
	{
		// Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
	}
	
	func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool
	{
		#if HAS_WEB_SERVICE
			DataAccess().getindex()
			{
				(index, error) in
				
				if (error != nil) { self.handleNetworkError(error: error); return }

				gIndex = index as! [[String : AnyObject]]
				
				DataAccess().gettheaters(getShowDateFromDayOffset(dayoffset: gDayOffset + DAY_OFFSET),
												postalcode: gPostalCode)
				{
					(theaters, error) in

					//	print(theaters?.count)
					if (error != nil) { self.handleNetworkError(error: error); return }
					else if theaters?.count == 0 { self.handleNoDataAvailable(error: error); return }

					gTheater = theaters  as! [[String : AnyObject]]
					self.process_theaters()

					self.window = UIWindow(frame: UIScreen.main.bounds)
					let mainStoryboard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)

					let mvc: MarqueeController = mainStoryboard.instantiateViewController(withIdentifier: "MarqueeStoryboard") as! MarqueeController
					self.window?.rootViewController = mvc
					self.window?.makeKeyAndVisible()
				}
			}
		#else

			//	let  data = DataAccess.get_DATA("hello")
			gIndex = DataAccess().parseindex(DataAccess.get_DATA(DataAccess.url_INDEX())) as! [[String : AnyObject]]

			gTheater = DataAccess().parsetheaters(DataAccess.get_DATA(DataAccess.url_STRING()))  as! [[String : AnyObject]]

			process_theaters()

			self.window = UIWindow(frame: UIScreen.main.bounds)
			let mainStoryboard: UIStoryboard = UIStoryboard(name: "Main", bundle: nil)

			let mvc: MarqueeController = mainStoryboard.instantiateViewController(withIdentifier: "MarqueeStoryboard") as! MarqueeController
			self.window?.rootViewController = mvc
			self.window?.makeKeyAndVisible()
		#endif
		// Override point for customization after application launch.
		return true
	}
}

