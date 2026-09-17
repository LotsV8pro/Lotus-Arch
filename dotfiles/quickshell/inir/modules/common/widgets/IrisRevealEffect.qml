pragma ComponentBehavior: Bound

import QtQuick
import qs.modules.common

/**
 * IrisRevealEffect - Top-corner circular iris reveal/close mask.
 *
 * Use as a layer effect:
 *   Item {
 *       layer.enabled: root._irisActive
 *       layer.effect: IrisRevealEffect {
 *           progress: root._irisProgress
 *           mirrored: !root.isLeftEdge
 *       }
 *   }
 *
 * progress: 0 = fully hidden, 1 = fully visible. The iris expands from the
 * top-left corner (or top-right when `mirrored` is true), mirroring the
 * window/menu iris animation used by niri.
 */
ShaderEffect {
    id: root

    property real progress: 0
    property bool mirrored: false
    property real w: root.width
    property real h: root.height

    readonly property real _mirror: root.mirrored ? 1 : 0

    fragmentShader: Qt.resolvedUrl("irisReveal.frag.qsb")
}