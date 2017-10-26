//
//  ConnectViewControler.swift
//  BlocklySample
//
//  Created by WG on 2017/10/20.
//  Copyright © 2017年 Google Inc. All rights reserved.
//

import Foundation
import UIKit

class ConnectViewControler: UIViewController {
    @IBOutlet weak var container: UIView!
    @IBOutlet weak var table: UITableView!
    public weak var delegate: PresentViewControllerDelegate?
    fileprivate let manager:BluetoothManager
    fileprivate var items = [(UUID, String)]()
    fileprivate var tryingUuid:UUID?
    fileprivate var device:Bluetooth?
    init(_ manager:BluetoothManager) {
        self.manager = manager
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        container.layer.cornerRadius = 16
        table.reloadData()
        manager.addDelegate(self)
        items = manager.connected
        manager.update()
    }
    
    func supportedInterfaceOrientations()->UIInterfaceOrientationMask{
        return .landscape
    }
    @IBAction func onTap(_ sender: Any) {
        delegate?.onCancel(self)
    }
}

extension ConnectViewControler:BluetoothManagerDelegate{
    func managerDidUpdate(error: PhoneStateError?) {
        if let e = error {
            print(e);
        }else{
            manager.scan()
        }
    }
    
    func managerDidScan(_ uuid: UUID, name: String) {
        if nil == items.index(where: {uuid == $0.0}){
            items += [(uuid, name)]
            table.reloadData()
        }
    }
    
    func managerDidConnect(_ uuid: UUID, error: ConnectError?) {
        if tryingUuid == uuid {
            device?.delegate = nil
            device = manager[uuid]
            table.reloadData()
            guard let _ = device else {
                return
            }
            device?.delegate = self
            device?.verify()
        }else{
            table.reloadData()
        }
    }
    
    func managerDidDisconnect(_ uuid: UUID, error: DisconnectError?) {
        if tryingUuid == uuid {
            tryingUuid = nil
        }
        table.reloadData()
    }
}

extension ConnectViewControler:BluetoothDelegate{

    func bluetoothDidVerify(_ error: VerifyError?) {
        if let e = error {
            print("bluetoothDidVerify \(e)")
        }else{
            device?.handshake()
        }
    }
    
    func bluetoothDidWrite(_ cmd: UInt8, error: WriteError?) {
        
    }
    
    func bluetoothDidRead(_ data: (UInt8, [UInt8])?, error: ReadError?) {
        print("bluetoothDidRead \(data?.0) \(data?.1)")
        if error == .restarted {
            device?.connect()
        }
    }
    
    func bluetoothDidHandshake(_ result: Bool) {
        if result {
            guard let u = tryingUuid else{return}
            delegate?.onConfirm(self, obj: u)
        }else{
            print("bluetoothDidHandshake fail")
        }
    }
    
    func bluetoothDidUpdateInfo(_ info: DeviceInfo) {
        print("bluetoothDidUpdateInfo \(info)")
    }
}

extension ConnectViewControler: UITableViewDataSource, UITableViewDelegate{
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return items.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCell(withIdentifier: "cell")
        if cell == nil {
            cell = UITableViewCell.init(style: .subtitle, reuseIdentifier: "cell")
            cell?.accessoryView = UIActivityIndicatorView.init(activityIndicatorStyle: .gray)
        }
        let item = items[indexPath.row]
        cell?.textLabel?.text = item.1
        switch manager[item.0]?.state ?? .disconnected {
        case .connected:
            cell?.textLabel?.textColor = .green
            cell?.accessoryView?.isHidden = true
        case .connecting:
            cell?.textLabel?.textColor = .yellow
            (cell?.accessoryView as? UIActivityIndicatorView)?.startAnimating()
            cell?.accessoryView?.isHidden = false
        default:
            cell?.textLabel?.textColor = .gray
            cell?.accessoryView?.isHidden = true
        }
        
        return cell!
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        device?.delegate = nil
        device = nil
        let item = items[indexPath.row]
        manager.connect(item.0)
        tryingUuid = item.0
        tableView.deselectRow(at: indexPath, animated: true)
        tableView.reloadRows(at: [indexPath], with: .none)
    }
}
