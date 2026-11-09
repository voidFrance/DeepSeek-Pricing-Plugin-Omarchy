import QtQuick
import qs.Commons
import qs.Commons as Commons
import qs.Ui
import "Model.js" as Model

// The popup behind the bar pill: where the day's peak windows sit, what the
// two models cost right now, and whether a job is worth starting.
Panel {
  id: root
  moduleName: "teteu.deepseek-pricing"
  ipcTarget: "teteu.deepseek-pricing"
  manageIpc: false

  property var anchorItem: null
  property var hostWidget: null
  readonly property var barIdentity: hostWidget || root

  // One second while open, so the countdown and the "now" marker move.
  property double now: Date.now()
  readonly property bool peak: Model.isPeak(now)
  readonly property double change: Model.nextChange(now)
  readonly property var segments: Model.localSegments(now)
  readonly property bool animate: setting("animate", true) !== false
  readonly property bool showPro: setting("showPro", true) !== false
  readonly property var models: showPro ? Model.PRICING.models : [Model.PRICING.models[0]]
  readonly property real dayMs: segments.length > 0 ? segments[segments.length - 1].to - segments[0].from : 86400000

  readonly property color fg: root.barForeground
  readonly property color dim: Qt.darker(fg, 1.5)
  readonly property color accent: Commons.Color.accent
  readonly property color urgent: Commons.Color.urgent
  readonly property color stateColor: peak ? urgent : accent

  readonly property string changeText: peak
    ? strings.t("panel.untilOff").arg(Model.formatDuration(change - now)).arg(Model.formatClock(change))
    : strings.t("panel.untilPeak").arg(Model.formatDuration(change - now)).arg(Model.formatClock(change))

  readonly property string adviceText: {
    if (!peak) return strings.t("panel.adviceOff")
    var minutes = Math.ceil((change - now) / 60000)
    return minutes <= 90
      ? strings.t("panel.advicePeakShort").arg(Model.formatDuration(change - now))
      : strings.t("panel.advicePeakLong")
  }

  Commons.Translations {
    id: strings
    directory: Qt.resolvedUrl("i18n")
  }

  Timer {
    interval: 1000
    running: root.opened
    repeat: true
    onTriggered: root.now = Date.now()
  }

  KeyboardPanel {
    id: panel
    anchorItem: root.anchorItem
    owner: root.barIdentity
    bar: root.bar
    open: root.opened
    focusTarget: panel.loadedContent
    contentWidth: panel.fittedContentWidth(Style.space(430))
    contentHeight: panel.fittedContentHeight(panel.loadedContentHeight)

    content: PanelKeyCatcher {
      id: catcher
      implicitHeight: body.implicitHeight
      onCloseRequested: root.close()
      onTabRequested: function(direction) { root.switchPanel(direction) }

      Flickable {
        anchors.fill: parent
        contentWidth: width
        contentHeight: body.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        interactive: contentHeight > height

        Column {
          id: body
          width: parent.width
          spacing: Style.space(16)

          // ---- Hero: logo, name and the active regime.
          Item {
            id: hero
            width: parent.width
            height: Math.max(heroLogo.height, heroLabels.implicitHeight, badge.height)

            LogoMark {
              id: heroLogo
              anchors.left: parent.left
              anchors.verticalCenter: parent.verticalCenter
              size: Style.space(42)
              rings: 2
              pulsing: root.animate && !root.peak
              tint: root.peak ? root.fg : root.accent
              pulseColor: root.accent
            }

            Column {
              id: heroLabels
              anchors.left: heroLogo.right
              anchors.leftMargin: Style.space(14)
              anchors.right: badge.left
              anchors.rightMargin: Style.space(10)
              anchors.verticalCenter: parent.verticalCenter
              spacing: Style.space(2)

              Text {
                textFormat: Text.PlainText
                width: parent.width
                elide: Text.ElideRight
                text: "DeepSeek"
                color: root.fg
                font.family: Style.font.family
                font.pixelSize: Style.font.title
                font.bold: true
              }

              Text {
                textFormat: Text.PlainText
                width: parent.width
                elide: Text.ElideRight
                text: strings.t("panel.meta").toUpperCase()
                color: root.dim
                font.family: Style.font.family
                font.pixelSize: Style.font.caption
                font.bold: true
                font.letterSpacing: 1.2
              }
            }

            BorderSurface {
              id: badge
              anchors.right: parent.right
              anchors.verticalCenter: parent.verticalCenter
              implicitWidth: badgeText.implicitWidth + Style.space(14)
              implicitHeight: badgeText.implicitHeight + Style.space(6)
              color: Util.alpha(root.stateColor, 0.12)
              borderSpec: Border.controlSpec("normal", root.stateColor, root.stateColor)
              radius: Style.cornerRadius

              Text {
                id: badgeText
                textFormat: Text.PlainText
                anchors.centerIn: parent
                text: root.peak ? strings.t("panel.peakBadge") : strings.t("panel.offBadge")
                color: root.stateColor
                font.family: Style.font.family
                font.pixelSize: Style.font.caption
                font.bold: true
              }
            }
          }

          // ---- Regime and countdown.
          Column {
            width: parent.width
            spacing: Style.space(3)

            Text {
              textFormat: Text.PlainText
              width: parent.width
              text: root.peak ? strings.t("panel.peak") : strings.t("panel.off")
              color: root.fg
              font.family: Style.font.family
              font.pixelSize: Style.font.display
              font.bold: true
            }

            Text {
              textFormat: Text.PlainText
              width: parent.width
              text: root.peak ? strings.t("panel.peakSubtitle") : strings.t("panel.offSubtitle")
              color: root.dim
              font.family: Style.font.family
              font.pixelSize: Style.font.subtitle
            }

            Text {
              textFormat: Text.PlainText
              width: parent.width
              topPadding: Style.space(2)
              text: root.changeText
              color: root.stateColor
              font.family: Style.font.family
              font.pixelSize: Style.font.body
              font.bold: true
            }
          }

          // ---- The local day, with peak windows shaded.
          Column {
            width: parent.width
            spacing: Style.space(7)

            Item {
              width: parent.width
              height: todayLabel.implicitHeight

              PanelSectionHeader {
                id: todayLabel
                text: strings.t("panel.today")
                foreground: root.fg
              }

              Text {
                anchors.right: parent.right
                anchors.verticalCenter: todayLabel.verticalCenter
                textFormat: Text.PlainText
                text: Model.formatClock(root.now)
                color: root.dim
                font.family: Style.font.family
                font.pixelSize: Style.font.caption
                font.bold: true
              }
            }

            Item {
              id: track
              width: parent.width
              height: Style.space(10)

              Rectangle {
                anchors.fill: parent
                radius: height / 2
                color: Util.alpha(root.fg, 0.08)
              }

              Row {
                anchors.fill: parent
                Repeater {
                  model: root.segments

                  Rectangle {
                    id: segment
                    required property var modelData
                    width: track.width * (modelData.to - modelData.from) / root.dayMs
                    height: track.height
                    color: modelData.peak ? Util.alpha(root.urgent, 0.85) : "transparent"
                  }
                }
              }

              // Where "now" is on the day.
              Rectangle {
                x: Math.round(track.width * Model.dayProgress(root.now)) - 1
                y: -Style.space(2)
                width: 2
                height: track.height + Style.space(4)
                radius: 1
                color: root.fg
              }
            }

            Row {
              width: parent.width
              Repeater {
                model: [0, 6, 12, 18]
                Item {
                  required property int modelData
                  width: track.width / 4
                  height: hourText.implicitHeight
                  Text {
                    id: hourText
                    textFormat: Text.PlainText
                    text: Model.pad2(modelData) + "h"
                    color: root.dim
                    font.family: Style.font.family
                    font.pixelSize: Style.font.caption
                  }
                }
              }
            }
          }

          // ---- Price cards, at the tier that is active now.
          Column {
            width: parent.width
            spacing: Style.space(8)

            PanelSectionHeader {
              text: strings.t("panel.prices")
              foreground: root.fg
            }

            Row {
              id: priceRow
              width: parent.width
              spacing: Style.space(10)

              Repeater {
                model: root.models

                Rectangle {
                  id: card
                  required property var modelData
                  required property int index
                  width: (priceRow.width - Style.space(10) * (root.models.length - 1)) / root.models.length
                  height: cardBody.implicitHeight + Style.space(22)
                  radius: Style.cornerRadius
                  color: Util.alpha(root.fg, 0.05)
                  border.width: 1
                  border.color: Util.alpha(root.fg, 0.10)

                  Column {
                    id: cardBody
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.leftMargin: Style.space(12)
                    anchors.rightMargin: Style.space(12)
                    spacing: Style.space(6)

                    Text {
                      textFormat: Text.PlainText
                      width: parent.width
                      elide: Text.ElideRight
                      text: card.modelData.name
                      color: root.fg
                      font.family: Style.font.family
                      font.pixelSize: Style.font.subtitle
                      font.bold: true
                    }

                    Repeater {
                      model: [
                        { key: "hit", label: strings.t("panel.hit") },
                        { key: "miss", label: strings.t("panel.miss") },
                        { key: "output", label: strings.t("panel.output") }
                      ]

                      Item {
                        required property var modelData
                        width: cardBody.width
                        height: priceLabel.implicitHeight

                        Text {
                          id: priceLabel
                          textFormat: Text.PlainText
                          text: modelData.label
                          color: root.dim
                          font.family: Style.font.family
                          font.pixelSize: Style.font.caption
                        }

                        Text {
                          anchors.right: parent.right
                          anchors.verticalCenter: priceLabel.verticalCenter
                          textFormat: Text.PlainText
                          text: Model.formatUsd(Model.price(card.modelData.id, modelData.key, root.peak ? "peak" : "off"))
                          color: root.fg
                          font.family: Style.font.family
                          font.pixelSize: Style.font.body
                          font.bold: true
                        }
                      }
                    }
                  }
                }
              }
            }
          }

          // ---- The actual advice.
          Rectangle {
            width: parent.width
            height: adviceBody.implicitHeight + Style.space(24)
            radius: Style.cornerRadius
            color: Util.alpha(root.stateColor, 0.09)
            border.width: 1
            border.color: Util.alpha(root.stateColor, 0.28)

            Column {
              id: adviceBody
              anchors.left: parent.left
              anchors.right: parent.right
              anchors.verticalCenter: parent.verticalCenter
              anchors.leftMargin: Style.space(12)
              anchors.rightMargin: Style.space(12)
              spacing: Style.space(3)

              Text {
                textFormat: Text.PlainText
                text: strings.t("panel.advice").toUpperCase()
                color: root.stateColor
                font.family: Style.font.family
                font.pixelSize: Style.font.caption
                font.bold: true
                font.letterSpacing: 1.2
              }

              Text {
                textFormat: Text.PlainText
                width: parent.width
                wrapMode: Text.WordWrap
                text: root.adviceText
                color: root.fg
                font.family: Style.font.family
                font.pixelSize: Style.font.body
                lineHeight: 1.15
              }
            }
          }

          // ---- Provenance. A wrong price is worse than a stale one that says so.
          Column {
            width: parent.width
            spacing: Style.space(2)

            Text {
              textFormat: Text.PlainText
              width: parent.width
              wrapMode: Text.WordWrap
              text: strings.t("panel.source").arg(Model.formatIsoDate(Model.PRICING.effectiveFrom))
              color: root.dim
              font.family: Style.font.family
              font.pixelSize: Style.font.caption
            }

            Text {
              textFormat: Text.PlainText
              width: parent.width
              wrapMode: Text.WordWrap
              visible: Model.holidayCalendarMissing(root.now)
              text: strings.t("panel.holidayWarning").arg(Model.beijingYear(root.now))
              color: root.urgent
              font.family: Style.font.family
              font.pixelSize: Style.font.caption
            }
          }
        }
      }
    }
  }
}
