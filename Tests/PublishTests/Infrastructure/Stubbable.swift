/**
*  Publish
*  Copyright (c) John Sundell 2019
*  MIT license, see LICENSE file for details
*/

import Foundation
import PublishVE

protocol Stubbable {
    static func stub(withPath path: Path) -> Self
}

extension Stubbable {
    static func stub() -> Self {
        stub(withPath: Path(.unique()))
    }

    func setting<T>(_ keyPath: WritableKeyPath<Self, T>,
                    to value: T) -> Self {
        var stub = self
        stub[keyPath: keyPath] = value
        return stub
    }
}
