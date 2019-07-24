import QtQuick 2.1
import QtQuick.Layouts 1.1
import QtQuick.Controls 1.4

Component {
    RowLayout {
        id: desktopSwitcher
        spacing: 0
        implicitHeight: parent.height

        property int desktopAmount: 0
        property var desktopEntries: []
        property int desktopEntrySpacing: {
            if (plasmoid.configuration.entrySpacing == 0) {
                return 4;
            } else if (plasmoid.configuration.entrySpacing == 1) {
                return 8;
            }
            return 12;
        }
        property int currentDesktopNumber;

        DesktopEntry {
            id: desktopEntryComponent
        }

        RowLayout {
            id: desktopEntriesLayout
            spacing: parent.spacing
            implicitHeight: parent.height
            anchors.fill: parent
        }

        PlusButton {}

        Component.onCompleted: {
            var desktopNames = virtualDesktopBar.getDesktopNames();
            currentDesktopNumber = virtualDesktopBar.getCurrentDesktopNumber();

            for (var i = 0; i < desktopNames.length; i++) {
                var desktopNumber = i + 1;
                var desktopName = desktopNames[i];
                var isCurrentDesktop = currentDesktopNumber == desktopNumber;
                registerDesktopEntry(desktopName, isCurrentDesktop);
            }

            desktopAmount = desktopNames.length;
        }

        function onCurrentDesktopChanged(desktopNumber) {
            for (var i = 0; i < desktopEntries.length; i++) {
                var desktopEntry = desktopEntries[i];
                var isCurrentDesktop = desktopNumber == i + 1;
                desktopEntry.setIsCurrentDesktop(isCurrentDesktop);
                if (isCurrentDesktop) {
                    currentDesktopNumber = i + 1;
                }
            }
        }

        function onDesktopAmountChanged(desktopAmount) {
            desktopSwitcher.desktopAmount = desktopAmount;
            var currentDesktopAmount = desktopEntries.length;
            var desktopAmountDifference = desktopAmount - currentDesktopAmount;
            if (desktopAmountDifference > 0) {
                addDesktops(currentDesktopAmount, desktopAmountDifference);
            } else if (desktopAmountDifference < 0) {
                removeDesktops(currentDesktopAmount);
            }
        }

        function onDesktopRemoveRequested(desktopNumber) {
            if (desktopAmount > 1) {
                removeDesktop(desktopNumber);
                virtualDesktopBar.removeDesktop(desktopNumber);
                onCurrentDesktopChanged(desktopNumber);
            }
        }

        function onDesktopNamesChanged() {
            var desktopNames = virtualDesktopBar.getDesktopNames();
            for (var i = 0; i < desktopEntries.length; i++) {
                var desktopName = desktopNames[i];
                var desktopEntry = desktopEntries[i];
                desktopEntry.setDesktopName(desktopName);
            }
        }

        function registerDesktopEntry(desktopName, isCurrentDesktop) {
            var desktopEntry = desktopEntryComponent.createObject(desktopEntriesLayout);
            desktopEntry.setDesktopName(desktopName);
            desktopEntry.setIsCurrentDesktop(!!isCurrentDesktop);
            desktopEntries.push(desktopEntry);
        }

        Timer {
            id: renameNewDesktopTimer
            interval: 100
            onTriggered: root.action_renameCurrentDesktop()
        }

        function addDesktops(currentDesktopAmount, addDesktopAmount) {
            var desktopNames = virtualDesktopBar.getDesktopNames();
            var desktopNumber = 1;
            for (var i = 1; i <= addDesktopAmount; i++) {
                desktopNumber = currentDesktopAmount + i;
                var desktopName = desktopNames[desktopNumber - 1];
                registerDesktopEntry(desktopName);
            }
            if (plasmoid.configuration.switchToNewDesktop) {
                if (plasmoid.configuration.keepOneEmptyDesktop &&
                    virtualDesktopBar.getEmptyDesktopsAmount() == 1) {
                    return;
                }

                virtualDesktopBar.switchToDesktop(desktopNumber);
                if (plasmoid.configuration.renameNewDesktop) {
                    renameNewDesktopTimer.start();
                }
            }
        }

        function removeDesktops(currentDesktopAmount) {
            for (var i = currentDesktopAmount - 1; i >= desktopAmount; i--) {
                var desktopEntry = desktopEntries[i];
                desktopEntry.remove();
                desktopEntries.splice(i, 1);
            }
        }

        function removeDesktop(desktopNumber) {
            var desktopEntry = desktopEntries[desktopNumber - 1];
            desktopEntry.remove();
            desktopEntries.splice(desktopNumber - 1, 1);
        }

        function getDesktopNumberForDesktopEntry(desktopEntry, nextNumber) {
            for (var i = 0; i < desktopEntries.length; i++) {
                if (desktopEntries[i] == desktopEntry) {
                    return i + 1;
                }
            }
            return nextNumber ? desktopEntries.length + 1 : -1;
        }

        MouseArea {
            anchors.fill: parent
            propagateComposedEvents: true
            property int wheelDelta: 0
            property int wheelDeltaLimit: 120

            onWheel: {
                if (!plasmoid.configuration.switchWithWheel) {
                    return;
                }

                var change = wheel.angleDelta.y || wheel.angleDelta.x;
                if (plasmoid.configuration.invertWheelSwitch) {
                    change = -change;
                }

                wheelDelta += change;

                while (wheelDelta >= wheelDeltaLimit) {
                    wheelDelta -= wheelDeltaLimit;
                    var nextDesktopNumber = currentDesktopNumber + 1;
                    if (nextDesktopNumber <= desktopAmount) {
                        virtualDesktopBar.switchToDesktop(nextDesktopNumber);
                    } else if (plasmoid.configuration.wheelSwitchWrap) {
                        virtualDesktopBar.switchToDesktop(1);
                    }
                }

                while (wheelDelta <= -wheelDeltaLimit) {
                    wheelDelta += wheelDeltaLimit;
                    var nextDesktopNumber = currentDesktopNumber - 1;
                    if (nextDesktopNumber >= 1) {
                        virtualDesktopBar.switchToDesktop(nextDesktopNumber);
                    } else if (plasmoid.configuration.wheelSwitchWrap) {
                        virtualDesktopBar.switchToDesktop(desktopAmount);
                    }
                }
            }
        }
    }
}
