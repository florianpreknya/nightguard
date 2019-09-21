//
//  BedsideViewController.swift
//  nightguard
//
//  Created by Florian Preknya on 4/11/19.
//  Copyright © 2019 private. All rights reserved.
//

import UIKit

class BedsideViewController: UIViewController {
    
    var currentNightscoutData: NightscoutData? {
        didSet {
            if isViewLoaded {
                updateCurrentNightscoutInfo()
            }
        }
    }
    
    @IBOutlet weak var bgLabel: UILabel!
    @IBOutlet weak var deltaLabel: UILabel!
    @IBOutlet weak var deltaArrowsLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var lastUpdateLabel: UILabel!
    @IBOutlet weak var closeButton: UIButton!
    @IBOutlet weak var snoozeInfoLabel: UILabel!
    @IBOutlet weak var alertInfoLabel: UILabel!
    @IBOutlet weak var loopStateView: LoopStateView!
    
    // References to registered notification center observers
    fileprivate var notificationObservers: [Any] = []
    
    deinit {
        for observer in notificationObservers {
            NotificationCenter.default.removeObserver(observer)
        }
    }

    static func instantiate() -> BedsideViewController {
        return UIStoryboard(name: "Bedside", bundle: Bundle.main).instantiateViewController(
            withIdentifier: "bedsideViewController") as! BedsideViewController
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    func updateAlarmInfo() {
        
        var snoozeInfo: String?
        var alertReason: String?
        var alertColor: UIColor = .red
        var showAlertReason = true
        
        if AlarmRule.isSnoozed() {
            let remaininingSnoozeMinutes = AlarmRule.getRemainingSnoozeMinutes()
            snoozeInfo = "Snoozed for \(remaininingSnoozeMinutes)min"
            
            // show alert reason message if less than 5 minutes of snoozing (to be prepared!)
            showAlertReason = remaininingSnoozeMinutes < 5
        }
        
        if showAlertReason {
            alertReason = AlarmRule.getAlarmActivationReason(ignoreSnooze: true)
            if alertReason == nil {
                
                if AlarmRule.isLowPredictionEnabled.value {
                    
                    // no alarm, but maybe we'll show a low prediction warning...
                    if let minutesToLow = PredictionService.singleton.minutesTo(low: AlarmRule.alertIfBelowValue.value), minutesToLow > 0 {
                        alertReason = "Low Predicted in \(minutesToLow)min"
                        alertColor = .yellow
                    }
                }
            }
        }
        
        snoozeInfoLabel.text = snoozeInfo
        alertInfoLabel.text = alertReason
        alertInfoLabel.textColor = alertColor
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        closeButton.backgroundColor = UIColor.darkGray.withAlphaComponent(0.3)
        closeButton.setImage(UIImage(named: "close")?.withRenderingMode(.alwaysTemplate), for: .normal)
        closeButton.tintColor = .white
        
        updateCurrentNightscoutInfo()
        updateAlarmInfo()
        
        updateLoopUI()
        notificationObservers = [
            NotificationCenter.default.addObserver(forName: .LoopDataChanged, object: LoopService.singleton, queue: nil) { [weak self] _ in
                dispatchOnMain { [weak self] in
                    self?.updateLoopUI()
                }
            }
        ]
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        closeButton.layer.cornerRadius = closeButton.frame.size.height / 2
    }
    
    @IBAction func onCloseButtonTapped(_ sender: UIButton) {
        self.dismiss(animated: true, completion: nil)
    }
    
    private func updateCurrentNightscoutInfo() {
        
        guard let currentNightscoutData = self.currentNightscoutData else {
            return
        }
        
        self.bgLabel.text = currentNightscoutData.sgv
        self.bgLabel.textColor = UIColorChanger.getBgColor(currentNightscoutData.sgv)
        
        self.deltaLabel.text = currentNightscoutData.bgdeltaString.cleanFloatValue
        self.deltaLabel.textColor = UIColorChanger.getDeltaLabelColor(NSNumber(value: currentNightscoutData.bgdelta))
        
        self.deltaArrowsLabel.text = currentNightscoutData.bgdeltaArrow
        self.deltaArrowsLabel.textColor = UIColorChanger.getDeltaLabelColor(NSNumber(value: currentNightscoutData.bgdelta))
        
        self.lastUpdateLabel.text = currentNightscoutData.timeString
        self.lastUpdateLabel.textColor = UIColorChanger.getTimeLabelColor(currentNightscoutData.time)
        
        // update current time
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm"
        self.timeLabel.text = formatter.string(from: Date())
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

        loopStateView.isHidden = false
    }
}
