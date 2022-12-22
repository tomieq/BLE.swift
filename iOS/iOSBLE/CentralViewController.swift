//
//  CentralViewController.swift
//  iOSBLE
//
//  Created by Tomasz on 19/12/2022.
//

import UIKit
import CoreBluetooth

class CentralViewController: UIViewController {
    let dispatchQueue: DispatchQueue = DispatchQueue(label: "com.tomieq.ble")
    let serviceID = CBUUID(string: "0xDAAC")
    let readableCharacteristicID = CBUUID(string: "0xDA01")
    let writableCharacteristicID = CBUUID(string: "0xDA02")

    var centralManager: CBCentralManager?
    var peripheral: CBPeripheral?
    let label = UILabel()

    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupUI()
        print("Started central mode")
        self.centralManager = CBCentralManager(delegate: self, queue: self.dispatchQueue)
    }

    override func viewDidDisappear(_ animated: Bool) {
        self.centralManager?.stopScan()
        if let peripheral = self.peripheral {
            self.centralManager?.cancelPeripheralConnection(peripheral)
        }
    }

    private func setupUI() {
        self.view.backgroundColor = .white
        self.label.font = UIFont.systemFont(ofSize: 52)
        self.label.textAlignment = .center
        self.view.addSubview(self.label, constraints: [
            equal(\.topAnchor, anchor: self.view.centerYAnchor, constant: -64),
            equal(\.centerXAnchor),
            equal(\.leadingAnchor),
            equal(\.trailingAnchor)

        ])
    }
}

extension CentralViewController: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .unknown:
            print("unknown")
        case .resetting:
            print("resetting")
        case .unsupported:
            print("unsupported")
        case .unauthorized:
            print("unauthorized")
        case .poweredOff:
            print("poweredOff")
            self.centralManager?.stopScan()
        case .poweredOn:
            print("poweredOn")
            self.centralManager?.scanForPeripherals(withServices: [self.serviceID])
        @unknown default:
            print("unknown")
        }
    }

    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String: Any], rssi RSSI: NSNumber) {
        let name = advertisementData[CBAdvertisementDataLocalNameKey] as? String
        print("BLE discovered peripheral \(name.readable)")
        if name == "BLEPeripheral" {
            self.centralManager?.stopScan()
            self.peripheral = peripheral
            self.peripheral?.delegate = self
            self.centralManager?.connect(peripheral)
        }
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("Connected to BLE peripheral")
        self.centralManager?.stopScan()
        self.peripheral?.discoverServices(nil)
    }

    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        print("Failed to connect to BLE peripheral: \(error.debugDescription)")
    }

    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        print("BLE Peripheral disconnected")
        self.peripheral = nil
    }
}

extension CentralViewController: CBPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        print("Discovered BLE services \(peripheral.services?.map{ $0.uuid } ?? [])")
        if let service = (peripheral.services?.first{ $0.uuid == self.serviceID }) {
            self.peripheral?.discoverCharacteristics(nil, for: service)
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        let characteristics = service.characteristics
        print("Discovered BLE characteristics \(characteristics?.map{ $0.uuid } ?? []) in service \(service.uuid)")

        if let readable = (characteristics?.first{ $0.uuid == self.readableCharacteristicID }) {
            self.peripheral?.readValue(for: readable)
            self.peripheral?.setNotifyValue(true, for: readable)
        }
        if let writable = (characteristics?.first{ $0.uuid == self.writableCharacteristicID }) {
            self.peripheral?.writeValue(Data(repeating: 2, count: 4), for: writable, type: .withResponse)
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        print("Received READ characteristic \(characteristic.uuid) response: \(characteristic.value!.hexString)")
        DispatchQueue.main.async { [weak self] in
            self?.label.text = "\(characteristic.value![0])"
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        print("Received WRITE confirmation for characteristic \(characteristic.uuid)")
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        print("Subscription to characteristic \(characteristic.uuid) \(error.isNil ? "succeeded" : "failed with error: \(error.debugDescription)")")
    }

    func peripheral(_ peripheral: CBPeripheral, didModifyServices invalidatedServices: [CBService]) {
        print("BLE Peripheral invalidated services: \(invalidatedServices.map{ $0.uuid })")
        if (invalidatedServices.map{ $0.uuid }.contains(self.serviceID)) {
            self.centralManager?.cancelPeripheralConnection(peripheral)
        }
    }
}
