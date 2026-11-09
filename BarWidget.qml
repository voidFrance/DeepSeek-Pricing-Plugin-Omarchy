import QtQuick
import Quickshell.Io
import qs.Commons
import qs.Commons as Commons
import qs.Ui
import "Model.js" as Model

// DeepSeek bar pill: the logo, the current regime (½ or 2×) and a tooltip
// with the prices and the next switch. Left click opens the panel, right
// click opens the official price page.
BarWidget {
  id: root
  moduleName: "teteu.deepseek-pricing"

  // Refreshed on a coarse tick; the tooltip only needs minutes, and the panel
  // runs its own one-second tick while it is open.
  property double now: Date.now()
  readonly property bool peak: Model.isPeak(now)
  readonly property double change: Model.nextChange(now)

  readonly property bool animate: setting("animate", true) !== false
  readonly property string tierText: peak ? "2×" : "½"
  readonly property color tierColor: peak ? Commons.Color.urgent : Commons.Color.accent

  readonly property string tooltipText: {
    var duration = Model.formatDuration(change - now)
    var clock = Model.formatClock(change)
    var headline = peak
      ? strings.t("bar.peak").arg(duration).arg(clock)
      : strings.t("bar.off").arg(duration).arg(clock)

    var tier = peak ? Model.TIER_PEAK : Model.TIER_OFF
    var models = setting("showPro", true) !== false ? Model.PRICING.models : [Model.PRICING.models[0]]
    var lines = []
    for (var i = 0; i < models.length; i++)
      lines.push(models[i].name + "  " + Model.formatUsd(Model.price(models[i].id, "miss", tier))
        + " in · " + Model.formatUsd(Model.price(models[i].id, "output", tier)) + " out")
    return headline + "\n" + lines.join("\n")
  }

  Commons.Translations {
    id: strings
    directory: Qt.resolvedUrl("i18n")
  }

  Timer {
    interval: 15000
    running: true
    repeat: true
    triggeredOnStart: true
    onTriggered: root.now = Date.now()
  }

  implicitWidth: root.vertical ? root.barSize : content.implicitWidth + Style.spaceReal(12)
  implicitHeight: root.vertical ? root.barSize : button.implicitHeight

  // ---- Panel plumbing: the bar identifies a popup by these on the widget.
  readonly property bool opened: panelLoader.item ? panelLoader.item.opened === true : false

  function open() {
    if (panelLoader.item) panelLoader.item.open()
  }

  function close() {
    if (panelLoader.item) panelLoader.item.close()
  }

  function togglePanel() {
    if (panelLoader.item) panelLoader.item.toggle()
  }

  readonly property bool popoutSwitchClosing: panelLoader.item ? panelLoader.item.popoutSwitchClosing === true : false

  function closeForPopoutSwitch() {
    if (panelLoader.item) panelLoader.item.closeForPopoutSwitch()
  }

  function injectPanel() {
    var target = panelLoader.item
    if (!target) return
    if ("bar" in target) target.bar = root.bar
    if ("settings" in target) target.settings = root.settings
    if ("anchorItem" in target) target.anchorItem = button
    if ("hostWidget" in target) target.hostWidget = root
  }

  onBarChanged: injectPanel()
  onSettingsChanged: injectPanel()

  WidgetButton {
    id: button
    anchors.fill: parent
    bar: root.bar
    text: ""
    hasVisualContent: true
    tooltipText: root.tooltipText
    horizontalMargin: 6
    verticalPadding: 4
    // The label is painted by the row below so the logo and the tier share
    // one baseline; the button only owns hover, press and the tooltip.
    labelVisible: false

    onPressed: function(mouseButton) {
      if (mouseButton === Qt.RightButton) {
        if (root.bar) root.bar.run("xdg-open " + Model.PRICING.source)
      }
      else if (mouseButton === Qt.LeftButton)
        root.togglePanel()
    }
  }

  Row {
    id: content
    anchors.centerIn: parent
    spacing: Style.space(4)

    LogoMark {
      anchors.verticalCenter: parent.verticalCenter
      size: root.vertical ? Style.space(14) : Style.space(15)
      tint: root.peak ? root.bar.barForeground : Commons.Color.accent
      pulseColor: Commons.Color.accent
      pulsing: root.animate && !root.peak
      hovered: button.tooltipHovered
    }

    Text {
      anchors.verticalCenter: parent.verticalCenter
      visible: !root.vertical
      textFormat: Text.PlainText
      text: root.tierText
      color: root.tierColor
      font.family: button.fontFamily
      font.pixelSize: Style.font.body
      font.bold: true
    }
  }

  ShellIpc {
    target: "teteu.deepseek-pricing"

    function open(): void { root.open() }
    function close(): void { root.close() }
    function show(): void { root.open() }
    function hide(): void { root.close() }
    function toggle(): void { root.togglePanel() }
  }

  Loader {
    id: panelLoader
    active: true
    source: Qt.resolvedUrl("Panel.qml")
    visible: false
    onLoaded: {
      root.injectPanel()
      Qt.callLater(root.injectPanel)
    }
  }
}
