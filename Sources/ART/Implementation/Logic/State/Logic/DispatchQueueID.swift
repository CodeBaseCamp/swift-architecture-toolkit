// Copyright © Rouven Strauss. MIT license.

/// Enumeration of specific available dispatch queues.
public enum DispatchQueueID<
  BackgroundDispatchQueueID: BackgroundDispatchQueueIDProtocol
>: Hashable {
  case mainThread
  case backgroundThread(BackgroundDispatchQueueID)
}

extension DispatchQueueID: CaseIterable {
  public static var allCases: [DispatchQueueID<BackgroundDispatchQueueID>] {
    return [.mainThread] + BackgroundDispatchQueueID.allCases.map { .backgroundThread($0) }
  }
}
