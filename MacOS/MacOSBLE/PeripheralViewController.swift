//
//  PeripheralViewController.swift
//  MacOSBLE
//
//  Created by Tomasz on 16/12/2022.
//

import Cocoa
import CoreBluetooth

class PeripheralViewController: NSViewController {
    let dispatchQueue: DispatchQueue = DispatchQueue(label: "com.tomieq.ble")
    var peripheralManager: CBPeripheralManager?
    var value: UInt8 = 10
    var central: CBCentral?

    let readableCharacteristicID = CBUUID(string: "0xDA01")
    var readableCharacterisctic: CBMutableCharacteristic!
    let writableCharacteristicID = CBUUID(string: "0xDA02")
    var writableCharacterisctic: CBMutableCharacteristic!

    let serviceID = CBUUID(string: "0xDAAC")
    var service: CBMutableService!

    override func viewDidLoad() {
        super.viewDidLoad()

        print("Started peripheral mode")
        self.view.wantsLayer = true
//        self.view.layer?.backgroundColor = .white
        self.setupUI()

        self.service = CBMutableService(type: self.serviceID, primary: true)
        self.readableCharacterisctic = CBMutableCharacteristic(type: self.readableCharacteristicID,
                                                               properties: [.read, .notify],
                                                               value: nil, permissions: [.readable, .readEncryptionRequired])
        self.writableCharacterisctic = CBMutableCharacteristic(type: self.writableCharacteristicID,
                                                               properties: [.write],
                                                               value: nil, permissions: [.writeable])
        self.service.characteristics = [self.readableCharacterisctic, self.writableCharacterisctic]
        self.peripheralManager = CBPeripheralManager(delegate: self, queue: self.dispatchQueue)
    }

    override var representedObject: Any? {
        didSet {
            // Update the view, if already loaded.
        }
    }

    private func setupUI() {
        let button = NSButton()
        button.setButtonType(.momentaryPushIn)
        button.bezelStyle = .rounded
        button.title = "Update BLE value"

        self.view.addSubview(button, constraints: [
            equal(\.topAnchor, constant: 12),
            equal(\.widthAnchor, equalToConstant: 200),
            equal(\.centerXAnchor)
        ])
        button.action = #selector(self.updateBleValue)
    }

    @objc private func updateBleValue() {
        guard let central = self.central else {
            return
        }
        let value = Data(repeating: self.value, count: 1)
        print("Set BLE value: \(value.hexString) in characterisctic \(self.readableCharacteristicID.uuidString)")
        self.peripheralManager?.updateValue(value, for: self.readableCharacterisctic, onSubscribedCentrals: [central])
        self.value += 1
    }
}

extension PeripheralViewController: CBPeripheralManagerDelegate {
    func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
        switch peripheral.state {
        case .unknown:
            print("unknown")
        case .resetting:
            print("resetting")
        case .unsupported:
            print("unsupported")
        case .unauthorized:
            print("unauthorized")
        case .poweredOff:
            self.peripheralManager?.stopAdvertising()
            self.peripheralManager?.remove(self.service)
            print("poweredOff")
        case .poweredOn:
            print("poweredOn")

            self.peripheralManager?.add(self.service)
            self.peripheralManager?.startAdvertising([CBAdvertisementDataServiceUUIDsKey: [self.service.uuid],
                                                      CBAdvertisementDataLocalNameKey: "BLEPeripheral"])
        @unknown default:
            print("unknown")
        }
    }

    func peripheralManagerDidStartAdvertising(_ peripheral: CBPeripheralManager, error: Error?) {
        print("Started advertising BLE service \(error.notNil ? "Error: \(error.debugDescription)" : "")")
    }

    func peripheralManager(_ peripheral: CBPeripheralManager, didAdd service: CBService, error: Error?) {
        print("Registered BLE service with uuid: \(service.uuid)")
    }

    public func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveRead request: CBATTRequest) {
        print("Received READ command on characteristic: \(request.characteristic.uuid)")
        request.value = Data(repeating: self.value, count: 1)
        self.peripheralManager?.respond(to: request, withResult: .success)
    }

    public func peripheralManager(_ peripheral: CBPeripheralManager, didReceiveWrite requests: [CBATTRequest]) {
        for request in requests {
            if let data = request.value {
                print("Received WRITE command on characteristic: \(request.characteristic.uuid) with value: \(data.hexString)")
            }
            self.peripheralManager?.respond(to: request, withResult: .success)
        }
    }

    public func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didSubscribeTo characteristic: CBCharacteristic) {
        print("BLE peripheral subscribed to characteristic: \(characteristic.uuid)")
        self.central = central
    }

    func peripheralManager(_ peripheral: CBPeripheralManager, central: CBCentral, didUnsubscribeFrom characteristic: CBCharacteristic) {
        print("didUnsubscribeFrom \(characteristic.uuid)")
        self.central = nil
    }
}
