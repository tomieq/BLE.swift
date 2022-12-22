//
//  AutoLayout.swift
//  MacOSBLE
//
//  Created by Tomasz on 16/12/2022.
//

import Foundation
import Cocoa

public typealias Constraint = (_ child: NSView, _ parent: NSView) -> NSLayoutConstraint

func equal<Axis, Anchor>(_ keyPath: KeyPath<NSView, Anchor>, multiplier: CGFloat = 1.0, constant: CGFloat = 0) -> Constraint where Anchor: NSLayoutAnchor<Axis> {
    return equal(keyPath, to: keyPath, multiplier: multiplier, constant: constant)
}

func equal<Axis, Anchor>(_ keyPath: KeyPath<NSView, Anchor>, to: KeyPath<NSView, Anchor>, multiplier: CGFloat = 1.0, constant: CGFloat = 0.0) -> Constraint where Anchor: NSLayoutAnchor<Axis> {
    return { view, parent in

        if let anchor = view[keyPath: keyPath] as? NSLayoutDimension,
           let parentAnchor = parent[keyPath: to] as? NSLayoutDimension {
            return anchor.constraint(equalTo: parentAnchor, multiplier: multiplier, constant: constant)
        }
        return view[keyPath: keyPath].constraint(equalTo: parent[keyPath: to], constant: constant)
    }
}

func equal<Axis, Anchor>(_ keyPath: KeyPath<NSView, Anchor>, anchor: Anchor, multiplier: CGFloat = 1.0, constant: CGFloat = 0.0) -> Constraint where Anchor: NSLayoutAnchor<Axis> {
    return { view, parent in

        if let selfAnchor = view[keyPath: keyPath] as? NSLayoutDimension,
           let nextViewAnchor = anchor as? NSLayoutDimension {
            return selfAnchor.constraint(equalTo: nextViewAnchor, multiplier: multiplier, constant: constant)
        }
        return view[keyPath: keyPath].constraint(equalTo: anchor, constant: constant)
    }
}

func equal<Anchor>(_ keyPath: KeyPath<NSView, Anchor>, equalToConstant: CGFloat = 0.0) -> Constraint where Anchor: NSLayoutDimension {
    return { view, parent in
        return view[keyPath: keyPath].constraint(equalToConstant: equalToConstant)
    }
}

func equal<Axis, Anchor>(_ keyPath: KeyPath<NSView, Anchor>, toSelf: KeyPath<NSView, Anchor>, multiplier: CGFloat = 1.0, constant: CGFloat = 0.0) -> Constraint where Anchor: NSLayoutAnchor<Axis> {
    return { view, _ in

        if let anchor = view[keyPath: keyPath] as? NSLayoutDimension,
           let toSelfAnchor = view[keyPath: toSelf] as? NSLayoutDimension {
            return anchor.constraint(equalTo: toSelfAnchor, multiplier: multiplier, constant: constant)
        }
        return view[keyPath: keyPath].constraint(equalTo: view[keyPath: toSelf], constant: constant)
    }
}

public extension NSView {
    func addSubview(_ child: NSView, constraints: [Constraint]) {
        self.addSubview(child)
        child.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate(constraints.map{ $0(child, self) })
    }
}
