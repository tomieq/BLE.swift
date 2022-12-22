//
//  LaunchViewController.swift
//  iOSBLE
//
//  Created by Tomasz on 20/12/2022.
//

import UIKit

class LaunchViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupUI()
    }

    private func setupUI() {
        let peripheralButton = UIButton()
        peripheralButton.backgroundColor = .red
        peripheralButton.setTitle("Peripheral mode", for: .normal)

        self.view.addSubview(peripheralButton, constraints: [
            equal(\.topAnchor, anchor: self.view.centerYAnchor, constant: -48),
            equal(\.widthAnchor, equalToConstant: 200),
            equal(\.centerXAnchor)
        ])
        peripheralButton.addTarget(nil, action: #selector(self.peripheralMode), for: .touchUpInside)

        let centralButton = UIButton()
        centralButton.backgroundColor = .blue
        centralButton.setTitle("Cenral mode", for: .normal)

        self.view.addSubview(centralButton, constraints: [
            equal(\.topAnchor, anchor: peripheralButton.bottomAnchor, constant: 48),
            equal(\.widthAnchor, equalToConstant: 200),
            equal(\.centerXAnchor)
        ])
        centralButton.addTarget(nil, action: #selector(self.centralMode), for: .touchUpInside)
    }

    @objc private func peripheralMode() {
        self.show(PeripheralViewController(), sender: nil)
    }

    @objc private func centralMode() {
        self.show(CentralViewController(), sender: nil)
    }
}
