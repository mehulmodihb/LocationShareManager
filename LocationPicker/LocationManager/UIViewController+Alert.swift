//
//  UIViewController+Alert.swift
//  LocationPicker
//
//  Created by hb on 26/05/20.
//  Copyright © 2020 hb. All rights reserved.
//

import UIKit

extension UIViewController {
    //MARK: - Show alert message with title
    ///To show alert message with title
    /// - parameters:
    ///     - title: Title of alert
    ///     - message: Message to show
    internal func showAlertMessageWithTitle(title : String?, message : String?, completion:(() -> Void)?)
    {
        guard (message != nil) else {
            return
        }
        let alertController = UIAlertController(title: title, message: message, preferredStyle:.alert)
        alertController.addAction(UIKit.UIAlertAction(title: LMConstant.OK, style: .default, handler: {_ in
            if let completed = completion
            {
                completed();
            }
        }))
        DispatchQueue.main.async {
            self.present(alertController, animated: true, completion: nil)
        }
    }
    
    //MARK: - Prompt for settings
    ///To show prompt message for settings
    /// - parameters:
    ///     - isAudio: False
    internal func promptForSettings(_ message : String, completion: ((_ buttonIndex : Int) -> Void)?){
        DispatchQueue.main.async(execute: { [unowned self] in
            let alertController = UIAlertController(title: "APP_NAME" , message: message, preferredStyle: .alert)
            alertController.addAction(UIAlertAction(title: LMConstant.OK, style: .cancel, handler:{ action in
                self.dismiss(animated: true, completion: nil)
                if let completed = completion{
                    completed(0)
                }
            }))
            alertController.addAction(UIAlertAction(title: LMConstant.Settings, style: .default, handler: { action in
                if let appSettings = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(appSettings, options: [:], completionHandler: nil)
                }
            }))
            self.present(alertController, animated: true, completion: nil)
        })
    }
    
    //MARK: - Show confirmation alert
    ///To show confirmation alert
    /// - parameters:
    ///     - title: Title of alert
    ///     - message: Message to show
    ///     - cancelTitle: Cancel button title
    ///     - okTitle: OK button title
    internal func showConfirmationAlert(title: String, message: String?, cancelTitle: String?, okTitle: String?, completion: ((_ buttonIndex : Int) -> Void)?)
    {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: cancelTitle, style: .cancel, handler: {_ in
            if let completed = completion
            {
                completed(0);
            }
        }))
        alertController.addAction(UIAlertAction(title: okTitle, style: .default, handler: {_ in
            if let completed = completion
            {
                completed(1);
            }
        }))
        DispatchQueue.main.async {
            self.present(alertController, animated: true, completion: nil)
        }
    }
}
