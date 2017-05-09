//
//  ViewController.swift
//  BluetoothTest
//
//  Created by 杨泽宇 on 2017/4/24.
//  Copyright © 2017年 杨泽宇. All rights reserved.
//

import UIKit
import CoreBluetooth
import CoreMotion

class ViewController: UIViewController{
    //运动管理器
    let motionManager = CMMotionManager()
    //刷新时间间隔
    let timeInterval: TimeInterval = 0.1
    var interestingCharacteristic:CBCharacteristic!
    var BluetoothManager:CBCentralManager!
    var BluetoothPeripheral:CBPeripheral!
    var SuccessToConnectBluetooth = false
    let SignalOfSpeed = 2
    let data:NSData = "1".data(using: String.Encoding.utf8, allowLossyConversion: true)! as NSData
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        UIApplication.shared.isIdleTimerDisabled = true
        BluetoothManager = CBCentralManager(delegate: self, queue: nil)
        // Do any additional setup after loading the view, typically from a nib.
        //开始陀螺仪更新
        startAttitudeUpdates()
    }
    
    func startAttitudeUpdates() {
        //判断设备支持情况
        guard motionManager.isDeviceMotionAvailable else {
            self.DataOfPositionSener.text = "\n当前设备不支位置识别\n"
            return
        }
        
        //设置刷新时间间隔
        self.motionManager.deviceMotionUpdateInterval = self.timeInterval
        
        //开始实时获取数据
        let queue = OperationQueue.current
        self.motionManager.startDeviceMotionUpdates(to: queue!, withHandler: { (attitudeData, error) in
            guard error == nil else {
                print(error!)
                return
            }
            //有更新
            if self.motionManager.isDeviceMotionActive {
                if let attitude = attitudeData?.attitude {
                    let pi = 3.1415926
                    let PositionInput = (Int)((attitude.roll / pi * 180) / 0.02 + 5000)

                    self.DataOfPositionSener.text = "陀螺仪数据：" + "\(PositionInput)"
                    let DataToSend = "\r\n\(PositionInput)"
                    if self.SuccessToConnectBluetooth == true {
                        self.BluetoothPeripheral.writeValue(DataToSend.data(using: String.Encoding.utf8, allowLossyConversion: true)!, for: self.interestingCharacteristic, type: CBCharacteristicWriteType(rawValue: 1)!)
                    }
                }
                
            }
        })
    }
//搜索并连接蓝牙
    @IBAction func 搜索(_ sender: UIButton) {
        BluetoothManager.scanForPeripherals(withServices: nil, options: nil)
        Timer.scheduledTimer(withTimeInterval: 10.0, repeats: false, block: { [weak self] _ in self?.BluetoothManager.stopScan()})
    }
    
    @IBAction func WrithValue(_ sender: UIButton) {
        let Kp1 = "P" + Kp.text!
        let Ki1 = "I" + Ki.text!
        let Kd1 = "D" + Kd.text!
        let Threshold1 = "T" + Threshold.text!
        self.BluetoothPeripheral.writeValue(Kp1.data(using: String.Encoding.utf8, allowLossyConversion: true)!, for: self.interestingCharacteristic, type: CBCharacteristicWriteType(rawValue: 1)!)
        self.BluetoothPeripheral.writeValue(Ki1.data(using: String.Encoding.utf8, allowLossyConversion: true)!, for: self.interestingCharacteristic, type: CBCharacteristicWriteType(rawValue: 1)!)
        self.BluetoothPeripheral.writeValue(Kd1.data(using: String.Encoding.utf8, allowLossyConversion: true)!, for: self.interestingCharacteristic, type: CBCharacteristicWriteType(rawValue: 1)!)
        self.BluetoothPeripheral.writeValue(Threshold1.data(using: String.Encoding.utf8, allowLossyConversion: true)!, for: self.interestingCharacteristic, type: CBCharacteristicWriteType(rawValue: 1)!)
        
    }
    
    @IBOutlet weak var Threshold: UITextField!
    @IBOutlet weak var Kd: UITextField!
    @IBOutlet weak var Ki: UITextField!
    @IBOutlet weak var Kp: UITextField!
    @IBOutlet weak var log: UILabel!
    @IBOutlet weak var Position: UILabel!
    @IBOutlet weak var Input: UILabel!
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBOutlet weak var DataOfPositionSener: UILabel!

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
                interestingCharacteristic = c
                SuccessToConnectBluetooth = true
                print(c.uuid.uuidString)
                peripheral.setNotifyValue(true, for: c)
            }
         }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?){
        let data:Data = characteristic.value!
        let  d  = Array(UnsafeBufferPointer(start: (data as NSData).bytes.bindMemory(to: UInt8.self, capacity: data.count), count: data.count))
        print(d)
        if d.count == 20
        {
            if d[0] >= 128 {
                for i in (0...17).filter({i in i % 2 == 0}) {
                    let PosL = (Int)(d[i])
                    let PosH = (Int)(d[i+1])
                    let InputL = (Int)(d[i+2])
                    let InputH = (Int)(d[i+3])
                    self.Position.text = "\(PosL - 128 + PosH * 100)"
                    self.Input.text = "\(InputL - 128 + InputH * 100)"
                }
            }
            else {
                for i in (1...15).filter({i in i % 2 == 1}) {
                    let PosL = (Int)(d[i])
                    let PosH = (Int)(d[i+1])
                    let InputL = (Int)(d[i+2])
                    let InputH = (Int)(d[i+3])
                    self.Position.text = "\(PosL - 128 + PosH * 100)"
                    self.Input.text = "\(InputL - 128 + InputH * 100)"
                }
            }
        }
    }
}

