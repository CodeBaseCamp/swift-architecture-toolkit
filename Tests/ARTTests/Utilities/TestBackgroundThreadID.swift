// Copyright © Rouven Strauss. MIT license.

import ART

enum TestBackgroundDispatchQueueID: BackgroundDispatchQueueIDProtocol {
  case defaultBackgroundThread
}

extension DispatchQueueID where BackgroundDispatchQueueID == TestBackgroundDispatchQueueID {
  static var backgroundThread: Self {
    return .backgroundThread(.defaultBackgroundThread)
  }
}
