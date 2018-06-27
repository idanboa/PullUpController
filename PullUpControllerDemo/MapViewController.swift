//
//  MapViewController.swift
//  PullUpControllerDemo
//
//  Created by Mario on 03/11/2017.
//  Copyright © 2017 Mario. All rights reserved.
//

import UIKit
import MapKit

class MapViewController: UIViewController {

    @IBOutlet private weak var mapView: MKMapView!
    weak var searchViewController: SearchViewController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        addPullUpController()
    }
    
    private func addPullUpController() {
        guard
            let searchViewController = UIStoryboard(name: "Main", bundle: nil)
                .instantiateViewController(withIdentifier: "SearchViewController") as? SearchViewController
            else { return }
        
        addPullUpController(searchViewController)
        self.searchViewController = searchViewController
    }
    
    func zoom(to location: CLLocationCoordinate2D) {
        let span = MKCoordinateSpan(latitudeDelta: 0.05, longitudeDelta: 0.05)
        let region = MKCoordinateRegionMake(location, span)
        
        mapView.setRegion(region, animated: true)
    }
    
    
    @IBAction func hideButton(_ sender: UIButton) {
        searchViewController?.hide()
    }
    
    @IBAction func revealButton(_ sender: UIButton) {
        searchViewController?.reveal()
    }
    
    @IBAction func reloadButton(_ sender: UIButton) {
        searchViewController?.hide { [weak searchViewController] finished in
            finished ? searchViewController?.reveal() : ()
        }
    }
    
    @IBAction func bounceButton(_ sender: UIButton) {
        searchViewController?.bounce()
    }
}

