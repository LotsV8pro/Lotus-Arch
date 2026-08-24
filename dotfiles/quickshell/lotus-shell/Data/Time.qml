pragma Singleton
import Quickshell
import QtQuick

Singleton {
    readonly property date now: clock.date

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }
}
