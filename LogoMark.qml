import QtQuick
import QtQuick.Effects
import qs.Commons

// The DeepSeek mark, tinted to the current theme.
//
// The shipped SVG is a single dark glyph, so it is painted through its alpha
// instead of being used as-is: an Image provides the mask and a Rectangle
// fills it with the theme colour. That keeps the logo legible on every theme,
// including the light ones.
//
// `pulsing` draws a soft sonar ring while the off-peak rate is active. The
// ring is decorative: it stops with Omarchy's animations toggle and never
// carries information on its own.
Item {
  id: root

  property real size: 16
  property color tint: Commons.Color.foreground
  property color pulseColor: Commons.Color.accent
  property bool pulsing: false
  property bool hovered: false
  property int rings: 1

  readonly property real aspect: 19.6 / 26.634

  implicitWidth: Math.max(1, Math.round(size))
  implicitHeight: Math.max(1, Math.round(size * aspect))

  scale: hovered ? 1.08 : 1
  transformOrigin: Item.Center
  Behavior on scale {
    NumberAnimation {
      duration: Style.duration(140)
      easing.type: Easing.OutCubic
    }
  }

  Image {
    id: mask
    anchors.fill: parent
    fillMode: Image.PreserveAspectFit
    source: Qt.resolvedUrl("assets/deepseek-mark.svg")
    sourceSize.width: Math.ceil(width * Screen.devicePixelRatio)
    sourceSize.height: Math.ceil(height * Screen.devicePixelRatio)
    // Hidden but still rendered into its own layer so MultiEffect can sample
    // it as a mask.
    visible: false
    layer.enabled: true
  }

  // Paints the theme colour through the glyph's alpha.
  Rectangle {
    anchors.fill: parent
    color: root.tint
    layer.enabled: true
    layer.effect: MultiEffect {
      maskEnabled: true
      maskSource: mask
      maskThresholdMin: 0.5
      maskSpreadAtMin: 1.0
    }
  }

  // Staggered rings, one per `rings`. Two of them read as a slow sonar; one
  // stays quiet next to the other bar icons.
  Repeater {
    model: root.rings

    Item {
      id: ring
      required property int index

      anchors.centerIn: root
      width: root.width * 1.32
      height: width
      opacity: 0
      visible: root.pulsing && !Style.reduceMotion

      Rectangle {
        anchors.fill: parent
        radius: width / 2
        color: "transparent"
        border.width: Math.max(1, Style.spaceReal(1.5))
        border.color: root.pulseColor
      }

      SequentialAnimation {
        running: ring.visible
        loops: Animation.Infinite
        PauseAnimation { duration: Style.duration(4000 + ring.index * 900) }
        ParallelAnimation {
          NumberAnimation {
            target: ring
            property: "scale"
            from: 0.66
            to: 1.24
            duration: Style.duration(1800)
            easing.type: Easing.OutCubic
          }
          NumberAnimation {
            target: ring
            property: "opacity"
            from: 0.6
            to: 0
            duration: Style.duration(1800)
            easing.type: Easing.OutCubic
          }
        }
      }
    }
  }
}
