//
//  LoopPanelView.swift
//  nightguard
//
//  Created by Florian Preknya on 7/4/19.
//  Copyright © 2019 private. All rights reserved.
//

import UIKit

class LoopPanelView: XibLoadedView {
    
    @IBOutlet weak var loopStateView: LoopStateView!
    @IBOutlet weak var minutesLabel: UILabel!
    @IBOutlet weak var predictionPanel: GroupedLabelsView!
    @IBOutlet weak var basalPanel: GroupedLabelsView!
    @IBOutlet weak var cobPanel: GroupedLabelsView!
    @IBOutlet weak var infoLabel: PaddingLabel!
    
    @IBOutlet weak var touchReportingView: TouchReportingView!
    
    var isExpanded: Bool = false {
        didSet {
//            minutesLabel.textColor = isExpanded ? UIColor.white : UIColor.clear
            minutesLabel.isHidden = !isExpanded
            predictionPanel.alpha = isExpanded ? 1 : 0
            basalPanel.alpha = isExpanded ? 1 : 0
            cobPanel.alpha = isExpanded ? 1 : 0
            
            let stackView = loopStateView.superview?.superview as? UIStackView
            if let loopStateStackView = loopStateView.superview {
                stackView?.removeArrangedSubview(loopStateStackView)
                if isExpanded {
                    stackView?.insertArrangedSubview(loopStateStackView, at: 0)
                } else {
                    stackView?.addArrangedSubview(loopStateStackView)
                }
            }
            
            onExpanded?()
        }
    }
    
    var onExpanded: (() -> Void)?
    
    // References to registered notification center observers
    fileprivate var notificationObservers: [Any] = []
    
    deinit {
        for observer in notificationObservers {
            NotificationCenter.default.removeObserver(observer)
        }
    }
    
    override func commonInit() {
        super.commonInit()
        
        predictionPanel.axis = .vertical
        predictionPanel.label.text = "↝"
//        predictionPanel.addArrangedSubview(predictionPanel.subviews[0])
        basalPanel.axis = .vertical
        basalPanel.label.text = "BASAL"
        cobPanel.axis = .vertical
        cobPanel.label.text = "COB"

        updateLoopUI()
        notificationObservers = [
            NotificationCenter.default.addObserver(forName: .LoopDataChanged, object: LoopService.singleton, queue: nil) { [weak self] _ in
                dispatchOnMain { [weak self] in
                    self?.updateLoopUI()
                }
            }
        ]
        
        // toggle expanded state
        touchReportingView.onTouchUpInside = { [weak self] in
            UIView.animate(withDuration: 0.2) { [weak self] in
                guard let self = self else { return }
                self.isExpanded = !self.isExpanded
            }
        }
        
        do {
            self.isExpanded = false
        }
    }
    
    func updateLoopUI() {
        
        guard LoopService.singleton.enabled else {
            loopStateView.isHidden = true
            return
        }
        
        guard let loopData = LoopService.singleton.loopData else {
            loopStateView.isHidden = true
            return
        }
        
        minutesLabel.text = "\(loopData.minutesAgo)min"
        switch loopData.state {
        case .fresh:
            loopStateView.tintColor = UIColor.App.Loop.fresh
        case .aging:
            loopStateView.tintColor = UIColor.App.Loop.aging
        case .stale:
            loopStateView.tintColor = UIColor.App.Loop.stale
        case .unknown:
            loopStateView.tintColor = UIColor.App.Loop.unknown
        }
        
        if let predictionValues = loopData.predictedValues, !predictionValues.isEmpty {
            predictionPanel.highlightedLabel.text = "\(Int(predictionValues.last!))"
            //            loopPredictionGroup.setHidden(false)
        } else {
            predictionPanel.highlightedLabel.text = " - "
            //            loopPredictionGroup.setHidden(true)
        }
        
        if let basalRate = loopData.enactedBasalRate {
            let formattedBasalRate = (basalRate.truncatingRemainder(dividingBy: 1) == 0) ? "\(Int(basalRate))" : "\(basalRate)"
            basalPanel.highlightedLabel.text =  "\(formattedBasalRate) U/h"
            //            loopBasalGroup.setHidden(false)
        } else {
            basalPanel.highlightedLabel.text = "schedule"
            //            loopBasalGroup.setHidden(true)
        }
        
        cobPanel.highlightedLabel.text = "\(loopData.cob.cleanValue)g"
        
        if let failureReason = loopData.failureReason {
            infoLabel.textColor = UIColor.red
            infoLabel.text = "❌ \(failureReason)"
        } else {
            infoLabel.textColor = UIColor.white.withAlphaComponent(0.5)
            if let recommendedBolus = loopData.recommendedBolus, recommendedBolus > 0 {
                infoLabel.text = "REC BOLUS: \(recommendedBolus.roundTo3f)U"
            } else if let recommendedBasalRate = loopData.recommendedBasalRate {
                infoLabel.text = "REC BASAL: \(recommendedBasalRate.roundTo3f)U"
            } else {
                infoLabel.text = nil
            }
        }
        
        loopStateView.isHidden = false
    }
}
