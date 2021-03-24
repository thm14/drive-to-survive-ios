//
//  HomeViewController.swift
//  DriveToSurvive
//
//  Created by Mahesh De Silva on 3/8/21.
//

import UIKit
import Lottie

protocol ParallaxCardViewManagerProtocol {
    var visibleCards: [ParallaxCardViewPresentable] { get }
    var selectedCardView: ParallaxCardViewPresentable? { get }
}

class HomeViewController: UIViewController, ParallaxCardViewManagerProtocol {

    @IBOutlet weak var newsCollectionView: UICollectionView!
    @IBOutlet weak var driverLineupCollectionView: UICollectionView!
    @IBOutlet weak var settingsNavBarButton: UIButton!
    @IBOutlet weak var settingsNavBarAnimationView: AnimationView!
    @IBOutlet weak var contentView: UIView!

    
    private let margin: CGFloat = 30.0
    
    private var listCellsize = CGSize.zero
    private var detailCellSize = CGSize.zero
    var selectedNewsItemCell: ParallaxCollectionViewCell?
    var selectedDriverCell: DriverThumbnailCollectionViewCell?
    private var collectionViewLayout: UICollectionViewLayout = ParallaxCollectionViewLayout()
    private var newsItems: [NewsItem] = DataStore.shared.getNewsItems()
    private var drivers: [Driver] = DataStore.shared.getDriversData()
    
    private var lastOffsetX: CGFloat?
    
    var visibleCards: [ParallaxCardViewPresentable] {
        get {
            if let cells = newsCollectionView?.visibleCells {
                let cards = cells.map { $0 as! ParallaxCardViewPresentable }
                return cards
            }
            return [ParallaxCardViewPresentable]()
        }
    }
    
    var selectedCardView: ParallaxCardViewPresentable? {
        get {
            if let selectedCell = self.selectedNewsItemCell {
                return selectedCell
            }
            return nil
        }
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupNewsCollectionView()
        setupDriverLineupCollectionView()
        self.navigationController?.delegate = self
        setupUI()
        newsCollectionView.reloadData()
        settingsNavBarAnimationView.animationSpeed = 2
        setButtonAnimation(button: settingsNavBarButton)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.navigationBar.isHidden = false
    }
    
    private func setupNewsCollectionView() {
        newsCollectionView.dataSource = self
        newsCollectionView.delegate = self
        newsCollectionView.register(ParallaxCollectionViewCell.classForCoder(), forCellWithReuseIdentifier: ParallaxCollectionViewCell.reuseIdentifier)
        newsCollectionView.collectionViewLayout = self.collectionViewLayout
    }
    
    private func setupDriverLineupCollectionView() {
        driverLineupCollectionView.dataSource = self
        driverLineupCollectionView.delegate = self
        driverLineupCollectionView.register(UINib(nibName: DriverThumbnailCollectionViewCell.reuseIdentifier, bundle: nil), forCellWithReuseIdentifier: DriverThumbnailCollectionViewCell.reuseIdentifier)
        
        driverLineupCollectionView.showsHorizontalScrollIndicator = false
    }
    
    private func setupUI() {
        //view.backgroundColor = UIColor(patternImage: UIImage(named: "metallic_gray")!)
        
        if let layout = self.collectionViewLayout as? ParallaxCollectionViewLayout {
            layout.minLineSpacing = 20.0
            layout.contentInset = UIEdgeInsets(top: 0, left: margin, bottom: 0, right: margin - layout.minLineSpacing)
            layout.itemSize = CGSize(width: view.frame.width - (4*margin), height: 350)
            newsCollectionView.backgroundColor = .white
            newsCollectionView.layer.masksToBounds = false
            newsCollectionView.showsHorizontalScrollIndicator = false
        }
    }
    
}

extension HomeViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        switch collectionView {
        case driverLineupCollectionView:
            return 1
        default:
            break
        }
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        switch collectionView {
        case self.newsCollectionView:
            return newsItems.count
        case self.driverLineupCollectionView:
            return drivers.count
        default:
            return 0
        }
        
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        switch collectionView {
        case driverLineupCollectionView:
            let size = CGSize(width: 120, height: 180)
            return size
        default:
            return .zero
        }
        
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        switch collectionView {
        case driverLineupCollectionView:
            return UIEdgeInsets(top: 0, left: 20, bottom: 0, right: 20)
        default:
            return .zero
        }
        
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        var cell: UICollectionViewCell
        
        switch collectionView {
        case newsCollectionView:
            cell = collectionView.dequeueReusableCell(withReuseIdentifier: ParallaxCollectionViewCell.reuseIdentifier, for: indexPath)
            
            if let cell = cell as? ParallaxCollectionViewCell {
                let newsItem = self.newsItems[indexPath.row]
                cell.update(with: newsItem.image, title: newsItem.title, subtitle: newsItem.subtitle)
            }
        case driverLineupCollectionView:
            cell = collectionView.dequeueReusableCell(withReuseIdentifier: DriverThumbnailCollectionViewCell.reuseIdentifier, for: indexPath)
            
            if let driverCell = cell as? DriverThumbnailCollectionViewCell {
                let driver = self.drivers[indexPath.row]
                driverCell.update(with: driver)
            }
        default:
            return UICollectionViewCell()
        }
        
        return cell
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        switch collectionView {
        case newsCollectionView:
            let newsItem = newsItems[indexPath.row]
            let newsDetailVC = NewsDetailViewController(with: newsItem)
            selectedNewsItemCell = collectionView.cellForItem(at: indexPath) as! ParallaxCollectionViewCell?
            
            newsDetailVC.transitioningDelegate = self
            self.presentInFullScreen(newsDetailVC, animated: true, completion: nil)
        case driverLineupCollectionView:
            let driver = drivers[indexPath.row]
            let driverDetailVC = DriverDetailViewController(with: driver)
            driverDetailVC.transitioningDelegate = self
            selectedDriverCell = collectionView.cellForItem(at: indexPath) as! DriverThumbnailCollectionViewCell?
            self.presentInFullScreen(driverDetailVC, animated: true, completion: nil)
//            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1, execute: {
//                self.selectedDriverCell?.alpha = 0
//                self.selectedDriverCell?.hideName()
//            })
        default:
            break
        }
        
    }
    
    /* Animate Settings Button */
    // TODO: - Move this to a Custom UI Button
    private func setButtonAnimation(button: UIButton) {
        button.addTarget(self, action: #selector(animateDown), for: [.touchDown, .touchDragEnter])
        button.addTarget(self, action: #selector(animateUp), for: [.touchDragExit, .touchCancel, .touchUpInside, .touchUpOutside])
    }
    
    @objc private func animateDown(sender: UIButton) {
        settingsNavBarAnimationView.loopMode = .playOnce
        settingsNavBarAnimationView.play()
    }
    
    @objc private func animateUp(sender: UIButton) {
        settingsNavBarAnimationView.play(toProgress: 0)
    }
    
    
    
}

// MARK: UICollectionViewDelegateFlowLayout functions

extension HomeViewController : UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat
    {
        switch collectionView {
        case driverLineupCollectionView:
            return 15
        default:
            break
        }
        
        return 0
    }
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat
    {
        
        switch collectionView {
        case driverLineupCollectionView:
            return 15
        default:
            break
        }
        
        return 0
    }
}

// MARK:- UIViewControllerTransitioningDelegate functions

extension HomeViewController: UIViewControllerTransitioningDelegate {
    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        
        if presented is DriverDetailViewController {
            return DriverDetailViewControllerTransitionAnimator(isDismissed: false)
        }
        
        return NewsDetailViewControllerTransitionAnimator(isDismissed: false)
    }
    
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        if(dismissed is DriverDetailViewController) {
            return DriverDetailViewControllerTransitionAnimator(isDismissed: true)
        }
        return NewsDetailViewControllerTransitionAnimator(isDismissed: true)
    }
}

// MARK:- UINavigationControllerDelegate functions

extension HomeViewController: UINavigationControllerDelegate {
    func navigationController(_ navigationController: UINavigationController, animationControllerFor operation: UINavigationController.Operation, from fromVC: UIViewController, to toVC: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        
        
        if operation == .push {
            switch toVC {
            case is DriverDetailViewController:
                return DriverDetailViewControllerTransitionAnimator(isDismissed: false)
            case is NewsDetailViewController:
                return NewsDetailViewControllerTransitionAnimator(isDismissed:  false)
            default:
                return nil
            }
        }
        
        if operation == .pop {
            switch fromVC {
            case is DriverDetailViewController:
                return DriverDetailViewControllerTransitionAnimator(isDismissed: true)
            case is NewsDetailViewController:
                return NewsDetailViewControllerTransitionAnimator(isDismissed: true)
            default:
                return nil
            }
        }
    
        return nil
    }
}

// MARK: - UIScrollViewDelegate functions

extension HomeViewController: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView == driverLineupCollectionView {
            animateDriverLineUp(scrollView: scrollView)
        }
        
      
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        lastOffsetX = nil
    }
    
    func animateDriverLineUp(scrollView: UIScrollView) {
        defer { lastOffsetX = scrollView.contentOffset.x }
        guard let lastOffsetX = lastOffsetX else { return }
        let maxVelocity: CGFloat = 30
        let maxStretch: CGFloat = 20
        let velocity = min(scrollView.contentOffset.x - lastOffsetX, maxVelocity)
        let stretch = velocity / maxVelocity * maxStretch
        var cumulativeStretch: CGFloat = 0
          var delay: Double = 0
          
          for (index, cell) in driverLineupCollectionView.visibleCells.enumerated() {
              cumulativeStretch += stretch
              delay += 0.05 * Double(index)
              UIView.animate(withDuration: 0.2, delay: delay, options: [.curveEaseInOut, .layoutSubviews], animations: {
                  cell.transform = CGAffineTransform(translationX: -cumulativeStretch, y: 0)
              }, completion: nil)
          }

        //TODO: - Find a away to introduce incremental translation along x.
    }
}