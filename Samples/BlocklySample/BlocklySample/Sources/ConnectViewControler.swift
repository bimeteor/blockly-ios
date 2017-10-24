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
    let manager:BluetoothManager
    fileprivate var items = [(UUID, String)]()
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
        manager.delegate = self
        manager.update()
    }
    
    func supportedInterfaceOrientations()->UIInterfaceOrientationMask{
        return .landscape
    }
    @IBAction func onTap(_ sender: Any) {
        dismiss(animated: true, completion: nil)
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
        if nil == self.items.index(where: {uuid == $0.0}){
            self.items += [(uuid, name)]
            table.reloadData()
        }
    }
    
    func managerDidConnect(_ uuid: UUID, error: ConnectError?) {
        table.reloadData()
    }
    
    func managerDidDisconnect(_ uuid: UUID, error: DisconnectError?) {
        table.reloadData()
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
        }
        let item = items[indexPath.row]
        cell?.textLabel?.text = item.1
        switch manager[item.0]?.state ?? .disconnected {
        case .connected:
            cell?.textLabel?.textColor = .green
        case .connecting:
            cell?.textLabel?.textColor = .yellow
        default:
            cell?.textLabel?.textColor = .gray
        }
        
        return cell!
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let item = items[indexPath.row]
        manager.connect(item.0)
        tableView.deselectRow(at: indexPath, animated: true)
    }
}

