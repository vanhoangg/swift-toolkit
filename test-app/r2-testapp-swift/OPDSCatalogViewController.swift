//
//  OPDSLibraryViewController.swift
//  r2-testapp-swift
//
//  Created by Alexandre Camilleri on 10/30/17.
//  Copyright © 2017 Readium. All rights reserved.
//

import UIKit
import R2Shared
import ReadiumOPDS
import PromiseKit

class OPDSCatalogViewController: UIViewController {
    var feed: Feed?
    var isFeedInitialized: Bool
    var originalFeedURL: URL
    var currentFeedURL: URL
    var nextPageURL: URL?
    public var isLoadingNextPage: Bool
    var opdsNavigationViewController: OPDSNavigationViewController?
    var publicationViewController: OPDSPublicationsViewController?
    var groupViewControllers: [OPDSGroupViewController]?
    var filterButton: UIBarButtonItem?
    var spinnerView: UIActivityIndicatorView?
    var scrollView: UIScrollView?
    var contentView: UIView?

    init?(url: URL) {
        self.originalFeedURL = url
        self.currentFeedURL = url
        self.isFeedInitialized = false
        self.isLoadingNextPage = false
        super.init(nibName: "OPDSCatalogView", bundle: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        let flowFrame = CGRect(x: 0, y: 44, width: UIScreen.main.bounds.size.width, height: UIScreen.main.bounds.size.height-44)
        scrollView = UIScrollView(frame: flowFrame)
        view = scrollView
        contentView = UIView(frame: scrollView!.bounds)
        scrollView?.addSubview(contentView!)
        navigationItem.title = ""
        spinnerView = UIActivityIndicatorView.init(activityIndicatorStyle: .whiteLarge)
        spinnerView?.startAnimating()
        spinnerView?.center = view.center
        view.addSubview(spinnerView!)
        parseFeed()
    }

    func parseFeed() {
        firstly {
            OPDSParser.parseURL(url: self.originalFeedURL)
        }.then { newFeed -> Void in
            self.feed = newFeed
            self.finishFeedInitialization()
        }
    }

    func finishFeedInitialization() {
        DispatchQueue.main.async {
            self.spinnerView?.removeFromSuperview()
        }
        self.isFeedInitialized = true
        navigationItem.title = feed!.metadata.title
        self.nextPageURL = self.findNextPageURL(feed: feed!)
        if let facets = feed?.facets, facets.count > 0 {
            filterButton = UIBarButtonItem(title: "Filter", style: UIBarButtonItemStyle.plain, target: self, action: #selector(OPDSCatalogViewController.filterMenuClicked))
            navigationItem.rightBarButtonItem = filterButton
        }
        initSubviews()
    }

    override func viewWillAppear(_ animated: Bool) {
        navigationController?.setNavigationBarHidden(false, animated: false)
        view.frame = view.bounds
        super.viewWillAppear(animated)
    }

    func loadNewURL(newURL: URL) {
        let opdsCatalog = OPDSCatalogViewController(url: newURL)
        self.navigationController?.pushViewController(opdsCatalog!, animated: true)
    }

    func changeFeed(newFeed: Feed) {
        feed = newFeed
        opdsNavigationViewController?.changeFeed(newFeed: newFeed)
        publicationViewController?.changePublications(newPublications: newFeed.publications)
    }

    func filterMenuClicked(_ sender: UIBarButtonItem) {
        if (!isFeedInitialized) {
            return
        }
        let tableViewController = OPDSFacetTableViewController(feed: feed!, catalogViewController: self)
        tableViewController.modalPresentationStyle = UIModalPresentationStyle.popover

        present(tableViewController, animated: true, completion: nil)


        if let popoverPresentationController = tableViewController.popoverPresentationController {
            popoverPresentationController.barButtonItem = sender
        }
    }

    func initSubviews() {
        if (!isFeedInitialized) {
            return
        }
        var bottomView: UIView? = nil
        let margins = contentView?.layoutMargins

        if feed!.navigation.count != 0 {
            opdsNavigationViewController = OPDSNavigationViewController(feed: feed!)
            //view.addSubview((opdsNavigationViewController?.view)!)
            contentView!.addSubview((opdsNavigationViewController?.view)!)
            bottomView = opdsNavigationViewController?.view
            bottomView?.topAnchor.constraint(equalTo: contentView!.topAnchor)
        }
        if feed!.groups.count != 0 {
            groupViewControllers = []
            for group in feed!.groups {
                let groupViewController = OPDSGroupViewController(group, stackView: contentView!, catalogViewController: self)!
                groupViewControllers?.append(groupViewController)
                if bottomView == nil {
                    contentView!.addSubview((groupViewController.view)!)
                    (groupViewController.view)!.topAnchor.constraint(equalTo: contentView!.topAnchor).isActive = true

                    (groupViewController.view)!.leftAnchor.constraint(equalTo: contentView!.leftAnchor).isActive = true
                    (groupViewController.view)!.rightAnchor.constraint(equalTo: contentView!.rightAnchor).isActive = true

                    (groupViewController.view)!.bottomAnchor.constraint(equalTo: (groupViewController.view)!.topAnchor, constant: 150).isActive = true

                    //(groupViewController.view)!.setNeedsUpdateConstraints()
                }
                else {
                    contentView!.addSubview((groupViewController.view)!)

                    (groupViewController.view)!.topAnchor.constraint(equalTo: bottomView!.bottomAnchor).isActive = true
                    (groupViewController.view)!.leftAnchor.constraint(equalTo: contentView!.leftAnchor).isActive = true
                    (groupViewController.view)!.rightAnchor.constraint(equalTo: contentView!.rightAnchor).isActive = true

                    (groupViewController.view)!.bottomAnchor.constraint(equalTo: (groupViewController.view)!.topAnchor, constant: 150).isActive = true

                    //(groupViewController.view)!.setNeedsUpdateConstraints()

                }
                bottomView = (groupViewController.view)!
            }
        }
        if feed!.publications.count != 0 {
            publicationViewController = OPDSPublicationsViewController(feed!.publications, frame: view.frame, catalogViewController: self)
            //view.addSubview((publicationViewController?.view)!)
            if bottomView == nil {
                contentView!.addSubview((publicationViewController?.view)!)
                bottomView?.topAnchor.constraint(equalTo: contentView!.topAnchor)
            }
            else {
                contentView!.insertSubview((publicationViewController?.view)!, belowSubview: bottomView!)
                (publicationViewController?.view)!.topAnchor.constraint(equalTo: bottomView!.bottomAnchor)
            }
            bottomView = (publicationViewController?.view)!
        }
//        contentView!.topAnchor.constraint(equalTo: scrollView!.topAnchor).isActive = true
//        contentView!.leftAnchor.constraint(equalTo: scrollView!.leftAnchor).isActive = true
//        contentView!.rightAnchor.constraint(equalTo: scrollView!.rightAnchor).isActive = true
        if (bottomView != nil) {
            //contentView!.bottomAnchor.constraint(equalTo: bottomView!.bottomAnchor).isActive = true
        }
        contentView!.layoutSubviews()
        contentView!.frame = CGRect(x: 0, y: 0, width:(scrollView?.bounds.width)!,
                                    height: bottomView!.frame.maxY)
        scrollView?.contentSize = contentView!.frame.size
    }

    public func getValueForFacet(facet: Int) -> Int? {
        // TODO: remove this function
        return nil
    }

    public func setValueForFacet(facet: Int, value: Int?) {
        if (!isFeedInitialized) {
            return
        }
        if let facetValue = value,
            let hrefValue = self.feed!.facets[facet].links[facetValue].href {
            // hrefValue is only a path, it doesn't have a scheme or domain name.
            // We get those from the original url
            let newURLString = (self.originalFeedURL.scheme ?? "http") + "://" + self.originalFeedURL.host! + hrefValue
            self.loadNewURL(newURL: URL(string: newURLString)!)
        }
        else {
            self.loadNewURL(newURL: self.originalFeedURL) // Note: this fails for multiple facet groups. Figure out a fix when an example is available
        }
    }

    public func findNextPageURL(feed: Feed) -> URL? {
        for link in feed.links {
            for rel in link.rel {
                if rel == "next" {
                    return URL(string: link.href!)
                }
            }
        }
        return nil
    }

    public func loadNextPage() {
        if !self.isFeedInitialized || self.isLoadingNextPage || nextPageURL == nil {
            return
        }
        self.isLoadingNextPage = true
        firstly {
            OPDSParser.parseURL(url: nextPageURL!)
        }.then { newFeed -> Void in
            self.nextPageURL = self.findNextPageURL(feed: newFeed)
            self.feed!.publications.append(contentsOf: newFeed.publications)
            self.changeFeed(newFeed: self.feed!) // changing to the ORIGINAL feed, now with more publications
        }.always {
            self.isLoadingNextPage = false
        }
    }
}
