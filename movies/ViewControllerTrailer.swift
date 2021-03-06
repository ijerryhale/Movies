//
//  ViewControllerTrailer.swift
//  movies
//
//  Created by Jerry Hale on 3/30/17
//  Copyright © 2018-2020 jhale. All rights reserved
//

import Foundation
import AVFoundation
import UIKit

//	simple `UIView` subclass that is backed by an `AVPlayerLayer` layer.
class PlayerView: UIView
{
    var player: AVPlayer?
	{
        get { return playerLayer.player }
        set { playerLayer.player = newValue }
    }
    
    var playerLayer: AVPlayerLayer { return layer as! AVPlayerLayer }
    override class var layerClass: AnyClass { return AVPlayerLayer.self }
}
/*
	KVO context used to differentiate KVO callbacks for this class versus other
	classes in its class hierarchy.
*/
private var playerViewControllerKVOContext = 0

//	MARK: ViewControllerTrailer
class ViewControllerTrailer: UIViewController
{
    @IBOutlet weak var playPauseBtn: UIButton!
    @IBOutlet weak var playerView: PlayerView!
	@IBOutlet weak var slider: UISlider!
	
    static let assetKeysRequiredToPlay = [ "playable", "hasProtectedContent" ]

	@objc let player = AVPlayer()
	var timeObserverToken: Any?
	
	var currentTime: Double
	{
        get { return CMTimeGetSeconds(player.currentTime()) }
        
        set {
            let newTime = CMTimeMakeWithSeconds(newValue, preferredTimescale: 1)
            player.seek(to: newTime, toleranceBefore: CMTime.zero, toleranceAfter: CMTime.zero)
        }
    }

	var duration: Double
	{
        guard let currentItem = player.currentItem else { return 0.0 }

        return CMTimeGetSeconds(currentItem.duration)
	}

	var rate: Float
	{
		get { return player.rate }
		set { player.rate = newValue }
	}

    var asset: AVURLAsset?
	{
        didSet {
            guard let newAsset = asset else { return }

            asynchronouslyLoadURLAsset(newAsset)
        }
    }
	
    @IBAction func sliderDidChange(_ sender: UISlider)
	{
        currentTime = Double(sender.value)
    }

	private var playerLayer: AVPlayerLayer? { return playerView.playerLayer }
	
	/*
	A formatter for individual date components used to provide an appropriate
	value for the `startTimeLabel` and `durationLabel`.
	*/
//	let timeRemainingFormatter: DateComponentsFormatter = {
//		let formatter = DateComponentsFormatter()
//		formatter.zeroFormattingBehavior = .pad
//		formatter.allowedUnits = [.minute, .second]
//		
//		return formatter
//	}()

    /*
        A token obtained from calling `player`'s `addPeriodicTimeObserverForInterval(_:queue:usingBlock:)`
        method.
    */
	//	private var timeObserverToken: Any?

	private var playerItem: AVPlayerItem? = nil {
        didSet {
            /*
                If needed, configure player item here before associating it with a player.
                (example: adding outputs, setting text style rules, selecting media options)
            */
            player.replaceCurrentItem(with: self.playerItem)
        }
	}
    
    // MARK: - Asset Loading
    func asynchronouslyLoadURLAsset(_ newAsset: AVURLAsset)
	{
        /*
            Using AVAsset now runs the risk of blocking the current thread (the 
            main UI thread) whilst I/O happens to populate the properties. It's
            prudent to defer our work until the properties we need have been loaded.
        */
        newAsset.loadValuesAsynchronously(forKeys: ViewControllerTrailer.assetKeysRequiredToPlay)
		{
            /*
                The asset invokes its completion handler on an arbitrary queue. 
                To avoid multiple threads using our internal state at the same time 
                we'll elect to use the main thread at all times, let's dispatch
                our handler to the main queue.
            */
            DispatchQueue.main.async
			{
                /*
                    `self.asset` has already changed! No point continuing because
                    another `newAsset` will come along in a moment.
                */
                guard newAsset == self.asset else { return }

                /*
                    Test whether the values of each of the keys we need have been
                    successfully loaded.
                */
                for key in ViewControllerTrailer.assetKeysRequiredToPlay
				{
                    var error: NSError?
                    
                    if newAsset.statusOfValue(forKey: key, error: &error) == .failed
					{
                        let stringFormat = NSLocalizedString("error.asset_key_%@_failed.description", comment: "Can't use this AVAsset because one of it's keys failed to load")

                        let message = String.localizedStringWithFormat(stringFormat, key)
                        
                        self.handleErrorWithMessage(message, error: error)
                        
                        return
                    }
                }
                // We can't play this asset.
                if !newAsset.isPlayable || newAsset.hasProtectedContent
				{
                    let message = NSLocalizedString("error.asset_not_playable.description", comment: "Can't use this AVAsset because it isn't playable or has protected content")
                    
                    self.handleErrorWithMessage(message)
                    
                    return
                }
                /*
                    We can play this asset. Create a new `AVPlayerItem` and make
                    it our player's current item.
                */
                self.playerItem = AVPlayerItem(asset: newAsset)
            }
        }
    }

	@IBAction func playPauseBtnPressed(_ sender: UIButton)
	{
		if player.rate != 1.0
		{
            // not playing, so play
 			if currentTime == duration
			{
                // at end, go back to begining
				currentTime = 0.0
			}

			player.play()
		}
        else { player.pause() }
	}

	@IBAction func returnBtnPressed(_ sender: UIButton)
	{
		player.pause()

		//	pop ViewControllerTrailer push ViewControllerMovieDetail
		(parent as! ViewControllerContainer).trailerSegueUnwind()
	}

    // MARK: - KVO Observation

    //	update UI when player or `player.currentItem` changes.
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey: Any]?, context: UnsafeMutableRawPointer?)
	{
        //	make sure the this KVO callback was intended for this view controller
        guard context == &playerViewControllerKVOContext else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
            return
        }

		if keyPath == #keyPath(ViewControllerTrailer.player.currentItem.duration)
		{
            //	update `timeSlider` and enable / disable controls when `duration` > 0.0

            /*
                Handle `NSNull` value for `NSKeyValueChangeNewKey`, i.e. when 
                `player.currentItem` is nil.
            */
            let newDuration: CMTime
            if let newDurationAsValue = change?[NSKeyValueChangeKey.newKey] as? NSValue {
                newDuration = newDurationAsValue.timeValue
            }
            else {
                newDuration = CMTime.zero
            }

            let hasValidDuration = newDuration.isNumeric && newDuration.value != 0
            let newDurationSeconds = hasValidDuration ? CMTimeGetSeconds(newDuration) : 0.0
            let currentTime = hasValidDuration ? Float(CMTimeGetSeconds(player.currentTime())) : 0.0
            
            slider.maximumValue = Float(newDurationSeconds)

            slider.value = currentTime
            
            playPauseBtn.isEnabled = hasValidDuration
            
			slider.isEnabled = hasValidDuration
		}
        else if keyPath == #keyPath(ViewControllerTrailer.player.rate)
		{
            let newRate = (change?[NSKeyValueChangeKey.newKey] as! NSNumber).doubleValue
            let buttonImageName = newRate == 1.0 ? "pause" : "play"
            let buttonImage = UIImage(named: buttonImageName)

            playPauseBtn.setImage(buttonImage, for: UIControl.State())
        }
        else if keyPath == #keyPath(ViewControllerTrailer.player.currentItem.status)
		{
            //	display error if status becomes `.Failed`

            /*
                Handle `NSNull` value for `NSKeyValueChangeNewKey`, i.e. when
                `player.currentItem` is nil.
            */
            let newStatus: AVPlayerItem.Status

            if let newStatusAsNumber = change?[NSKeyValueChangeKey.newKey] as? NSNumber
			{
                newStatus = AVPlayerItem.Status(rawValue: newStatusAsNumber.intValue)!
            }
            else
			{
                newStatus = .unknown
            }
            
            if newStatus == .failed
			{
                handleErrorWithMessage(player.currentItem?.error?.localizedDescription, error:player.currentItem?.error)
            }
        }
    }

    //	trigger KVO for anyone observing our properties
	//	affected by player and player.currentItem
    override class func keyPathsForValuesAffectingValue(forKey key: String) -> Set<String>
	{
        let affectedKeyPathsMappingByKey: [String: Set<String>] = [
            "duration":     [#keyPath(ViewControllerTrailer.player.currentItem.duration)],
            "rate":         [#keyPath(ViewControllerTrailer.player.rate)]
        ]
        
        return affectedKeyPathsMappingByKey[key] ?? super.keyPathsForValuesAffectingValue(forKey: key)
	}

	func handleErrorWithMessage(_ message: String?, error: Error? = nil)
	{
		NSLog("Error occured with message: \(message ?? "No Message"), error: \(String(describing: error)).")
    
        let alertTitle = NSLocalizedString("alert.error.title", comment: "Alert title for errors")
        let defaultAlertMessage = NSLocalizedString("error.default.description", comment: "Default error message when no NSError provided")

        let alert = UIAlertController(title: alertTitle, message: message == nil ? defaultAlertMessage : message, preferredStyle: UIAlertController.Style.alert)

        let alertActionTitle = NSLocalizedString("alert.error.actions.OK", comment: "OK on error alert")

        let alertAction = UIAlertAction(title: alertActionTitle, style: .default, handler: nil)
        
        alert.addAction(alertAction)

        present(alert, animated: true, completion: nil)
	}

	//	MARK: UIViewController overrides
    override func viewWillDisappear(_ animated: Bool)
	{ super.viewWillDisappear(animated); print("ViewControllerTrailer viewWillDisappear ")
		
		removeObserver(self, forKeyPath: #keyPath(ViewControllerTrailer.player.currentItem.duration), context: &playerViewControllerKVOContext)
        removeObserver(self, forKeyPath: #keyPath(ViewControllerTrailer.player.rate), context: &playerViewControllerKVOContext)
        removeObserver(self, forKeyPath: #keyPath(ViewControllerTrailer.player.currentItem.status), context: &playerViewControllerKVOContext)
		removeObserver(self, forKeyPath: #keyPath(ViewControllerTrailer.player.currentItem), context: &playerViewControllerKVOContext)

		if let timeObserverToken = timeObserverToken
		{
            player.removeTimeObserver(timeObserverToken)
            self.timeObserverToken = nil
        }
	}

    override func viewWillAppear(_ animated: Bool)
	{
        super.viewWillAppear(animated)
        
		addObserver(self, forKeyPath: #keyPath(ViewControllerTrailer.player.currentItem.duration), options: [.new, .initial], context: &playerViewControllerKVOContext)
        addObserver(self, forKeyPath: #keyPath(ViewControllerTrailer.player.rate), options: [.new, .initial], context: &playerViewControllerKVOContext)
        addObserver(self, forKeyPath: #keyPath(ViewControllerTrailer.player.currentItem.status), options: [.new, .initial], context: &playerViewControllerKVOContext)
		addObserver(self, forKeyPath: #keyPath(ViewControllerTrailer.player.currentItem), options: [.new, .initial], context: &playerViewControllerKVOContext)
		
        playerView.playerLayer.player = player

		//	make sure we don't have a strong reference
		//	cycle by only capturing self as weak
        let interval = CMTimeMake(value: 1, timescale: 1)
        timeObserverToken = player.addPeriodicTimeObserver(forInterval: interval, queue: DispatchQueue.main)
		{ [unowned self] time in
            let timeElapsed = Float(CMTimeGetSeconds(time))
            
            self.slider.value = Float(timeElapsed)
        }

		let movie = gMovie[gCurrMovie]
		//	don't have to check info here as we never
		//	get here if there isn't a good info
		let info = gXMLIndex.filter({ $0[KEY_ID] as? String == movie.movie[KEY_FILM_ID] as? String }).first

		let previews = info?[KEY_PREVIEWS] as! [String : AnyObject]
		let preview = previews[KEY_PREVIEW] as! [String : AnyObject]
		let data = NSData(contentsOf: DataHelper.get_URL_TRAILER((preview[KEY_TEXT] as! String)))
		let datastring = NSString(data: data! as Data, encoding: String.Encoding.utf8.rawValue)! as String
		
		asset = AVURLAsset(url: URL(string: datastring.filter { !"\n".contains($0) } )! , options: nil)

		player.play()
    }

    override func viewDidLoad()
	{
		super.viewDidLoad(); print("ViewControllerTrailer viewDidLoad ")
		
		slider.setThumbImage(UIImage(named: "scrubthumb.png"), for: .normal)
	}
}
