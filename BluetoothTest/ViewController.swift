//
//  ViewController.swift
//  BluetoothTest
//
//  Created by 杨泽宇 on 2017/4/24.
//  Copyright © 2017年 杨泽宇. All rights reserved.
//

import UIKit
import CoreBluetooth

class ViewController: UIViewController{

    var BluetoothManager:CBCentralManager!
    var BluetoothPeripheral:CBPeripheral!
    let SignalOfSpeed = 2
    let data:NSData = "1".data(using: String.Encoding.utf8, allowLossyConversion: true) as! NSData
    override func viewDidLoad() {
        super.viewDidLoad()
        BluetoothManager = CBCentralManager(delegate: self, queue: nil)
        // Do any additional setup after loading the view, typically from a nib.
    }

    @IBAction func 搜索(_ sender: UIButton) {
        BluetoothManager.scanForPeripherals(withServices: nil, options: nil)
        Timer.scheduledTimer(withTimeInterval: 10.0, repeats: false, block: { [weak self] _ in
            self?.BluetoothManager.stopScan()
                   })
    }
    
    @IBAction func Signal(_ sender: UIButton) {
        self.BluetoothPeripheral.writeValue(data as Data, for: <#T##CBCharacteristic#>, type: <#T##CBCharacteristicWriteType#>)
    }
    @IBOutlet weak var log: UILabel!
    
    @IBOutlet weak var Position: UILabel!
    

    @IBOutlet weak var Input: UILabel!
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}
extension ViewController : CBCentralManagerDelegate{
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        //print(peripheral.name!)
        if peripheral.name == "BT05"{
            print("Found BT05")
            log.text = "Found BT05"
            BluetoothManager.stopScan()
            self.BluetoothPeripheral = peripheral
            self.BluetoothManager = central
            central.connect(self.BluetoothPeripheral, options: nil)
        }
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("Success to connect")
        log.text = "Success to connect "
        self.BluetoothPeripheral.delegate = self
        self.BluetoothPeripheral.discoverServices(nil)
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?){
        log.text = "Fail to connect"
        print("Fail to connect")
    }
    
}

extension ViewController : CBPeripheralDelegate {
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if error != nil {
            log.text = "No sevice was found"
            print("No service was found")
                       return
        }
        for s in peripheral.services!{
            peripheral.discoverCharacteristics(nil, for: s)
            print(s.uuid.uuidString)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        for c in service.characteristics! {
            
            if c.uuid.uuidString == "FFE1"{
                print(c.uuid.uuidString)
                peripheral.setNotifyValue(true, for: c)
            }
         }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?){
        let data:Data = characteristic.value!
        let  d  = Array(UnsafeBufferPointer(start: (data as NSData).bytes.bindMemory(to: UInt8.self, capacity: data.count), count: data.count))
        print(d)
        if d[0] >= 128 {
            for i in (0...17).filter({i in i % 2 == 0}) {
                let PosL = (Int)(d[i])
                let PosH = (Int)(d[i+1])
                let InputL = (Int)(d[i+2])
                let InputH = (Int)(d[i+3])
                Position.text = "\(PosL - 128 + PosH * 100)"
                Input.text = "\(InputL - 128 + InputH * 100)"
            }
        }
        else {
            for i in (1...15).filter({i in i % 2 == 1}) {
                
                let PosL = (Int)(d[i])
                let PosH = (Int)(d[i+1])
                let InputL = (Int)(d[i+2])
                let InputH = (Int)(d[i+3])
                Position.text = "\(PosL - 128 + PosH * 100)"
                Input.text = "\(InputL - 128 + InputH * 100)"

            }

        }
    }
}

