import Foundation

/// 可注入依赖包。本组件不包含用户偏好存储、常用语或任何外观设置。
public struct YZSessionStoreEnvironment: Sendable {
    public let fileSystem: any YZSessionFileSystem
    public let clock: any YZClockProvider
    public let calendar: any YZCalendarProvider
    public let logger: any YZSessionStoreLogger
    public let displayNames: (any YZSessionDisplayNameProviding)?

    public init(
        fileSystem: any YZSessionFileSystem,
        clock: any YZClockProvider,
        calendar: any YZCalendarProvider,
        logger: any YZSessionStoreLogger,
        displayNames: (any YZSessionDisplayNameProviding)? = nil
    ) {
        self.fileSystem = fileSystem
        self.clock = clock
        self.calendar = calendar
        self.logger = logger
        self.displayNames = displayNames
    }

    public static var production: YZSessionStoreEnvironment {
        YZSessionStoreEnvironment(
            fileSystem: YZDefaultFileSystem(),
            clock: YZSystemClock(),
            calendar: YZSystemCalendarProvider(),
            logger: YZSessionNullLogger(),
            displayNames: nil
        )
    }
}