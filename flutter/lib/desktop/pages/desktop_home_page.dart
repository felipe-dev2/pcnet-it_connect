import 'dart:async';
import 'dart:io';
import 'dart:convert';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hbb/common.dart';
import 'package:flutter_hbb/common/widgets/animated_rotation_widget.dart';
import 'package:flutter_hbb/common/widgets/custom_password.dart';
import 'package:flutter_hbb/common/widgets/peer_tab_page.dart';
import 'package:flutter_hbb/consts.dart';
import 'package:flutter_hbb/desktop/pages/connection_page.dart';
import 'package:flutter_hbb/desktop/pages/desktop_setting_page.dart';
import 'package:flutter_hbb/desktop/pages/desktop_tab_page.dart';
import 'package:flutter_hbb/desktop/widgets/update_progress.dart';
import 'package:flutter_hbb/models/platform_model.dart';
import 'package:flutter_hbb/models/server_model.dart';
import 'package:flutter_hbb/models/state_model.dart';
import 'package:flutter_hbb/plugin/ui_manager.dart';
import 'package:flutter_hbb/utils/multi_window_manager.dart';
import 'package:flutter_hbb/utils/platform_channel.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:window_manager/window_manager.dart';
import 'package:window_size/window_size.dart' as window_size;
import '../widgets/button.dart';
import '../../common/pcnet_colors.dart';

class DesktopHomePage extends StatefulWidget {
  const DesktopHomePage({Key? key}) : super(key: key);

  @override
  State<DesktopHomePage> createState() => _DesktopHomePageState();
}

const borderColor = Color(0xFF2F65BA);

class _DesktopHomePageState extends State<DesktopHomePage>
    with AutomaticKeepAliveClientMixin, WidgetsBindingObserver {
  @override
  bool get wantKeepAlive => true;
  var systemError = '';
  StreamSubscription? _uniLinksSubscription;
  var svcStopped = false.obs;
  var watchIsCanScreenRecording = false;
  var watchIsProcessTrust = false;
  var watchIsInputMonitoring = false;
  var watchIsCanRecordAudio = false;
  Timer? _updateTimer;
  bool isCardClosed = false;

  final RxBool _block = false.obs;
  int _selectedNavIndex = 0;

  final GlobalKey _childKey = GlobalKey();
  final _leftPaneScrollController = ScrollController();

  // Sidebar colors
  static const Color _sidebarBg = Color(0xFF16161A);
  static const Color _leftPanelBg = Color(0xFF1E1E24);

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final isIncomingOnly = bind.isIncomingOnly();
    final isOutgoingOnly = bind.isOutgoingOnly();
    return _buildBlock(
        child: Container(
      color: PCNETColors.blackPrimary,
      child: Row(
        children: [
          // Sidebar navigation
          _buildSidebar(context),
          Container(width: 1, color: PCNETColors.dividerColor),
          // Main content area
          Expanded(
            child: Column(
              children: [
                // Main two-panel content
                Expanded(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Left panel: Connection details + form
                      if (!isOutgoingOnly)
                        ChangeNotifierProvider.value(
                          value: gFFI.serverModel,
                          child: _buildLeftPanel(context),
                        ),
                      if (!isOutgoingOnly)
                        Container(width: 1, color: PCNETColors.dividerColor),
                      // Right panel: Recent Sessions + Peer tabs
                      Expanded(child: _buildRightPanel(context)),
                    ],
                  ),
                ),
                // Help/install banners
                if (!isOutgoingOnly)
                  ChangeNotifierProvider.value(
                    value: gFFI.serverModel,
                    child: _buildHelpBanners(context),
                  ),
                // Status bar
                Container(height: 1, color: PCNETColors.dividerColor),
                _buildStatusBar(context),
              ],
            ),
          ),
        ],
      ),
    ));
  }

  Widget _buildBlock({required Widget child}) {
    return buildRemoteBlock(
        block: _block, mask: true, use: canBeBlocked, child: child);
  }

  // ============ SIDEBAR ============

  Widget _buildSidebar(BuildContext context) {
    return Container(
      width: 72,
      color: _sidebarBg,
      child: Column(
        children: [
          SizedBox(height: 16),
          // Logo
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
            ),
            child: loadIcon(38),
          ),
          SizedBox(height: 24),
          // Top nav items
          _buildNavItem(Icons.connected_tv_outlined, 'Remote\nConnection', 0),
          SizedBox(height: 2),
          _buildNavItem(Icons.history_outlined, 'History', 1),
          Spacer(),
          // Bottom nav items
          _buildNavItem(Icons.settings_outlined, 'Settings', 2),
          SizedBox(height: 2),
          _buildNavItem(Icons.info_outline, 'About', 3),
          SizedBox(height: 16),
          // User icon
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: PCNETColors.grayDark,
              border: Border.all(color: PCNETColors.borderColor, width: 1),
            ),
            child: Icon(Icons.person_outline, size: 18, color: PCNETColors.textSecondary),
          ),
          SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    final isSelected = _selectedNavIndex == index;
    return InkWell(
      onTap: () {
        if (index == 2) {
          // Settings - open settings tab
          if (DesktopSettingPage.tabKeys.isNotEmpty) {
            DesktopSettingPage.switch2page(DesktopSettingPage.tabKeys[0]);
          }
          return;
        }
        if (index == 3) {
          // About - show about dialog
          _showAboutDialog(context);
          return;
        }
        setState(() {
          _selectedNavIndex = index;
        });
      },
      child: Container(
        width: 72,
        padding: EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          border: isSelected
              ? Border(
                  left: BorderSide(color: PCNETColors.greenPrimary, width: 3),
                )
              : null,
          color: isSelected ? PCNETColors.greenPrimary.withOpacity(0.08) : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 22,
              color: isSelected ? PCNETColors.greenPrimary : PCNETColors.textSecondary,
            ),
            SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 9,
                height: 1.3,
                color: isSelected ? PCNETColors.greenPrimary : PCNETColors.textSecondary,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: PCNETColors.surfaceColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Row(
          children: [
            loadIcon(28),
            SizedBox(width: 10),
            Text(
              'PCNET-IT Connect',
              style: TextStyle(
                color: PCNETColors.greenPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Version ${bind.mainGetVersion()}',
              style: TextStyle(color: PCNETColors.textSecondary, fontSize: 13),
            ),
            SizedBox(height: 8),
            Text(
              'Remote desktop solution by PCNET-IT Solutions.',
              style: TextStyle(color: PCNETColors.textPrimary, fontSize: 13),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('OK', style: TextStyle(color: PCNETColors.greenPrimary)),
          ),
        ],
      ),
    );
  }

  // ============ LEFT PANEL ============

  Widget _buildLeftPanel(BuildContext context) {
    return Container(
      width: 380,
      color: _leftPanelBg,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Connection Details section
          Padding(
            padding: EdgeInsets.fromLTRB(24, 24, 24, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your Connection Details',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: PCNETColors.textPrimary,
                  ),
                ),
                SizedBox(height: 20),
                // Your ID
                _buildIDDisplay(context),
                SizedBox(height: 16),
                // Password
                _buildPasswordDisplay(context),
              ],
            ),
          ),
          // Connect to Remote Device section
          Expanded(
            child: Padding(
              padding: EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: ConnectionPage(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIDDisplay(BuildContext context) {
    final model = gFFI.serverModel;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Your ID',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: PCNETColors.textSecondary,
          ),
        ),
        SizedBox(height: 6),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: PCNETColors.grayDark,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: PCNETColors.borderColor, width: 1),
          ),
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onDoubleTap: () {
                    Clipboard.setData(
                        ClipboardData(text: model.serverId.text));
                    showToast(translate("Copied"));
                  },
                  child: TextFormField(
                    controller: model.serverId,
                    readOnly: true,
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                      isDense: true,
                    ),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: PCNETColors.textPrimary,
                      letterSpacing: 1,
                    ),
                  ).workaroundFreezeLinuxMint(),
                ),
              ),
              _buildIconButton(
                Icons.refresh,
                tooltip: translate('Refresh ID'),
                onTap: () => bind.mainUpdateTemporaryPassword(),
              ),
              SizedBox(width: 4),
              _buildIconButton(
                Icons.copy_outlined,
                tooltip: translate('Copy'),
                onTap: () {
                  Clipboard.setData(
                      ClipboardData(text: model.serverId.text));
                  showToast(translate("Copied"));
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordDisplay(BuildContext context) {
    return Consumer<ServerModel>(
      builder: (context, model, child) {
        final showOneTime = model.approveMode != 'click' &&
            model.verificationMethod != kUsePermanentPassword;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Password',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: PCNETColors.textSecondary,
              ),
            ),
            SizedBox(height: 6),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: PCNETColors.grayDark,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: PCNETColors.borderColor, width: 1),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onDoubleTap: () {
                        if (showOneTime) {
                          Clipboard.setData(
                              ClipboardData(text: model.serverPasswd.text));
                          showToast(translate("Copied"));
                        }
                      },
                      child: TextFormField(
                        controller: model.serverPasswd,
                        readOnly: true,
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                          isDense: true,
                        ),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: PCNETColors.textPrimary,
                          letterSpacing: 2,
                        ),
                      ).workaroundFreezeLinuxMint(),
                    ),
                  ),
                  if (showOneTime)
                    _buildIconButton(
                      Icons.copy_outlined,
                      tooltip: translate('Copy'),
                      onTap: () {
                        Clipboard.setData(
                            ClipboardData(text: model.serverPasswd.text));
                        showToast(translate("Copied"));
                      },
                    ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildIconButton(IconData icon,
      {required String tooltip, required VoidCallback onTap}) {
    RxBool hover = false.obs;
    return InkWell(
      borderRadius: BorderRadius.circular(4),
      onTap: onTap,
      onHover: (value) => hover.value = value,
      child: Tooltip(
        message: tooltip,
        child: Obx(() => Padding(
              padding: EdgeInsets.all(4),
              child: Icon(
                icon,
                size: 16,
                color: hover.value
                    ? PCNETColors.greenPrimary
                    : PCNETColors.textSecondary,
              ),
            )),
      ),
    );
  }

  // ============ RIGHT PANEL ============

  Widget _buildRightPanel(BuildContext context) {
    return Container(
      color: PCNETColors.blackPrimary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Row(
              children: [
                Text(
                  'Recent Sessions',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: PCNETColors.textPrimary,
                  ),
                ),
                Spacer(),
                _buildSettingsButton(context),
              ],
            ),
          ),
          SizedBox(height: 8),
          // Peer tabs and list
          Expanded(
            child: PeerTabPage().paddingOnly(left: 12.0, right: 12.0),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsButton(BuildContext context) {
    RxBool hover = false.obs;
    return InkWell(
      borderRadius: BorderRadius.circular(6),
      child: Obx(
        () => Padding(
          padding: EdgeInsets.all(6),
          child: Icon(
            Icons.settings_outlined,
            color: hover.value ? PCNETColors.textPrimary : PCNETColors.textSecondary,
            size: 20,
          ),
        ),
      ),
      onTap: () => {
        if (DesktopSettingPage.tabKeys.isNotEmpty)
          {
            DesktopSettingPage.switch2page(DesktopSettingPage.tabKeys[0])
          }
      },
      onHover: (value) => hover.value = value,
    );
  }

  // ============ STATUS BAR ============

  Widget _buildStatusBar(BuildContext context) {
    return Container(
      height: 32,
      padding: EdgeInsets.symmetric(horizontal: 16),
      color: PCNETColors.surfaceColor,
      child: OnlineStatusWidget(),
    );
  }

  // ============ HELP BANNERS ============

  Widget _buildHelpBanners(BuildContext context) {
    return FutureBuilder<Widget>(
      future: Future.value(
          Obx(() => _buildHelpContent(stateGlobal.updateUrl.value))),
      builder: (_, data) {
        if (data.hasData) {
          if (bind.isIncomingOnly()) {
            if (isInHomePage()) {
              Future.delayed(Duration(milliseconds: 300), () {
                _updateWindowSize();
              });
            }
          }
          return data.data!;
        } else {
          return const Offstage();
        }
      },
    );
  }

  Widget _buildHelpContent(String updateUrl) {
    if (!bind.isCustomClient() &&
        updateUrl.isNotEmpty &&
        !isCardClosed &&
        bind.mainUriPrefixSync().contains('rustdesk')) {
      final isToUpdate = (isWindows || isMacOS) && bind.mainIsInstalled();
      String btnText = isToUpdate ? 'Update' : 'Download';
      GestureTapCallback onPressed = () async {
        final Uri url = Uri.parse('https://rustdesk.com/download');
        await launchUrl(url);
      };
      if (isToUpdate) {
        onPressed = () {
          handleUpdate(updateUrl);
        };
      }
      return _buildBannerCard(
          "Status",
          "${translate("new-version-of-{${bind.mainGetAppNameSync()}}-tip")} (${bind.mainGetNewVersion()}).",
          btnText,
          onPressed,
          closeButton: true);
    }
    if (systemError.isNotEmpty) {
      return _buildBannerCard("", systemError, "", () {});
    }

    if (isWindows && !bind.isDisableInstallation()) {
      if (!bind.mainIsInstalled()) {
        return _buildBannerCard(
            "", bind.isOutgoingOnly() ? "" : "install_tip", "Install",
            () async {
          await rustDeskWinManager.closeAllSubWindows();
          bind.mainGotoInstall();
        });
      } else if (bind.mainIsInstalledLowerVersion()) {
        return _buildBannerCard(
            "Status", "Your installation is lower version.", "Click to upgrade",
            () async {
          await rustDeskWinManager.closeAllSubWindows();
          bind.mainUpdateMe();
        });
      }
    } else if (isMacOS) {
      final isOutgoingOnly = bind.isOutgoingOnly();
      if (!(isOutgoingOnly || bind.mainIsCanScreenRecording(prompt: false))) {
        return _buildBannerCard("Permissions", "config_screen", "Configure",
            () async {
          bind.mainIsCanScreenRecording(prompt: true);
          watchIsCanScreenRecording = true;
        }, help: 'Help', link: translate("doc_mac_permission"));
      } else if (!isOutgoingOnly && !bind.mainIsProcessTrusted(prompt: false)) {
        return _buildBannerCard("Permissions", "config_acc", "Configure",
            () async {
          bind.mainIsProcessTrusted(prompt: true);
          watchIsProcessTrust = true;
        }, help: 'Help', link: translate("doc_mac_permission"));
      } else if (!bind.mainIsCanInputMonitoring(prompt: false)) {
        return _buildBannerCard("Permissions", "config_input", "Configure",
            () async {
          bind.mainIsCanInputMonitoring(prompt: true);
          watchIsInputMonitoring = true;
        }, help: 'Help', link: translate("doc_mac_permission"));
      } else if (!isOutgoingOnly &&
          !svcStopped.value &&
          bind.mainIsInstalled() &&
          !bind.mainIsInstalledDaemon(prompt: false)) {
        return _buildBannerCard("", "install_daemon_tip", "Install", () async {
          bind.mainIsInstalledDaemon(prompt: true);
        });
      }
    } else if (isLinux) {
      if (bind.isOutgoingOnly()) {
        return Container();
      }
      final LinuxCards = <Widget>[];
      if (bind.isSelinuxEnforcing()) {
        final keyShowSelinuxHelpTip = "show-selinux-help-tip";
        if (bind.mainGetLocalOption(key: keyShowSelinuxHelpTip) != 'N') {
          LinuxCards.add(_buildBannerCard(
            "Warning",
            "selinux_tip",
            "",
            () async {},
            help: 'Help',
            link:
                'https://rustdesk.com/docs/en/client/linux/#permissions-issue',
            closeButton: true,
            closeOption: keyShowSelinuxHelpTip,
          ));
        }
      }
      if (bind.mainCurrentIsWayland()) {
        LinuxCards.add(_buildBannerCard(
            "Warning", "wayland_experiment_tip", "", () async {},
            help: 'Help',
            link: 'https://rustdesk.com/docs/en/client/linux/#x11-required'));
      } else if (bind.mainIsLoginWayland()) {
        LinuxCards.add(_buildBannerCard("Warning",
            "Login screen using Wayland is not supported", "", () async {},
            help: 'Help',
            link: 'https://rustdesk.com/docs/en/client/linux/#login-screen'));
      }
      if (LinuxCards.isNotEmpty) {
        return Column(children: LinuxCards);
      }
    }
    if (bind.isIncomingOnly()) {
      return Align(
        alignment: Alignment.centerRight,
        child: OutlinedButton(
          onPressed: () {
            SystemNavigator.pop();
            if (isWindows) {
              exit(0);
            }
          },
          child: Text(translate('Quit')),
        ),
      ).marginAll(14);
    }
    return Container();
  }

  Widget _buildBannerCard(String title, String content, String btnText,
      GestureTapCallback onPressed,
      {String? help,
      String? link,
      bool? closeButton,
      String? closeOption}) {
    if (bind.mainGetBuildinOption(key: kOptionHideHelpCards) == 'Y' &&
        content != 'install_daemon_tip') {
      return const SizedBox();
    }
    void closeCard() async {
      if (closeOption != null) {
        await bind.mainSetLocalOption(key: closeOption, value: 'N');
        if (bind.mainGetLocalOption(key: closeOption) == 'N') {
          setState(() {
            isCardClosed = true;
          });
        }
      } else {
        setState(() {
          isCardClosed = true;
        });
      }
    }

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: PCNETColors.greenDark.withOpacity(0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: PCNETColors.greenDark.withOpacity(0.3), width: 1),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, size: 18, color: PCNETColors.greenPrimary),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (title.isNotEmpty)
                  Text(
                    translate(title),
                    style: TextStyle(
                      color: PCNETColors.greenPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ).marginOnly(bottom: 2),
                if (content.isNotEmpty)
                  Text(
                    translate(content),
                    style: TextStyle(
                      color: PCNETColors.textPrimary,
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
              ],
            ),
          ),
          if (btnText.isNotEmpty)
            Padding(
              padding: EdgeInsets.only(left: 12),
              child: ElevatedButton(
                onPressed: onPressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: PCNETColors.greenPrimary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                child: Text(translate(btnText), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              ),
            ),
          if (help != null)
            Padding(
              padding: EdgeInsets.only(left: 8),
              child: InkWell(
                onTap: () async => await launchUrl(Uri.parse(link!)),
                child: Text(
                  translate(help),
                  style: TextStyle(
                    decoration: TextDecoration.underline,
                    color: PCNETColors.greenPrimary,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          if (closeButton != null && closeButton == true)
            Padding(
              padding: EdgeInsets.only(left: 8),
              child: InkWell(
                onTap: closeCard,
                child: Icon(Icons.close, color: PCNETColors.textSecondary, size: 16),
              ),
            ),
        ],
      ),
    );
  }

  // ============ Legacy methods for compatibility ============

  buildPresetPasswordWarning() {
    return Container();
  }

  buildPluginEntry() {
    final entries = PluginUiManager.instance.entries.entries;
    return Offstage(
      offstage: entries.isEmpty,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...entries.map((entry) {
            return entry.value;
          })
        ],
      ),
    );
  }

  // ============ Lifecycle ============

  @override
  void initState() {
    super.initState();
    _updateTimer = periodic_immediate(const Duration(seconds: 1), () async {
      await gFFI.serverModel.fetchID();
      final error = await bind.mainGetError();
      if (systemError != error) {
        systemError = error;
        setState(() {});
      }
      final v = await mainGetBoolOption(kOptionStopService);
      if (v != svcStopped.value) {
        svcStopped.value = v;
        setState(() {});
      }
      if (watchIsCanScreenRecording) {
        if (bind.mainIsCanScreenRecording(prompt: false)) {
          watchIsCanScreenRecording = false;
          setState(() {});
        }
      }
      if (watchIsProcessTrust) {
        if (bind.mainIsProcessTrusted(prompt: false)) {
          watchIsProcessTrust = false;
          setState(() {});
        }
      }
      if (watchIsInputMonitoring) {
        if (bind.mainIsCanInputMonitoring(prompt: false)) {
          watchIsInputMonitoring = false;
          setState(() {});
        }
      }
      if (watchIsCanRecordAudio) {
        if (isMacOS) {
          Future.microtask(() async {
            if ((await osxCanRecordAudio() ==
                PermissionAuthorizeType.authorized)) {
              watchIsCanRecordAudio = false;
              setState(() {});
            }
          });
        } else {
          watchIsCanRecordAudio = false;
          setState(() {});
        }
      }
    });
    Get.put<RxBool>(svcStopped, tag: 'stop-service');
    rustDeskWinManager.registerActiveWindowListener(onActiveWindowChanged);

    screenToMap(window_size.Screen screen) => {
          'frame': {
            'l': screen.frame.left,
            't': screen.frame.top,
            'r': screen.frame.right,
            'b': screen.frame.bottom,
          },
          'visibleFrame': {
            'l': screen.visibleFrame.left,
            't': screen.visibleFrame.top,
            'r': screen.visibleFrame.right,
            'b': screen.visibleFrame.bottom,
          },
          'scaleFactor': screen.scaleFactor,
        };

    bool isChattyMethod(String methodName) {
      switch (methodName) {
        case kWindowBumpMouse: return true;
      }

      return false;
    }

    rustDeskWinManager.setMethodHandler((call, fromWindowId) async {
      if (!isChattyMethod(call.method)) {
        debugPrint(
          "[Main] call ${call.method} with args ${call.arguments} from window $fromWindowId");
      }
      if (call.method == kWindowMainWindowOnTop) {
        windowOnTop(null);
      } else if (call.method == kWindowRefreshCurrentUser) {
        gFFI.userModel.refreshCurrentUser();
      } else if (call.method == kWindowGetWindowInfo) {
        final screen = (await window_size.getWindowInfo()).screen;
        if (screen == null) {
          return '';
        } else {
          return jsonEncode(screenToMap(screen));
        }
      } else if (call.method == kWindowGetScreenList) {
        return jsonEncode(
            (await window_size.getScreenList()).map(screenToMap).toList());
      } else if (call.method == kWindowActionRebuild) {
        reloadCurrentWindow();
      } else if (call.method == kWindowEventShow) {
        await rustDeskWinManager.registerActiveWindow(call.arguments["id"]);
      } else if (call.method == kWindowEventHide) {
        await rustDeskWinManager.unregisterActiveWindow(call.arguments['id']);
      } else if (call.method == kWindowConnect) {
        await connectMainDesktop(
          call.arguments['id'],
          isFileTransfer: call.arguments['isFileTransfer'],
          isViewCamera: call.arguments['isViewCamera'],
          isTerminal: call.arguments['isTerminal'],
          isTcpTunneling: call.arguments['isTcpTunneling'],
          isRDP: call.arguments['isRDP'],
          password: call.arguments['password'],
          forceRelay: call.arguments['forceRelay'],
          connToken: call.arguments['connToken'],
        );
      } else if (call.method == kWindowBumpMouse) {
        return RdPlatformChannel.instance.bumpMouse(
          dx: call.arguments['dx'],
          dy: call.arguments['dy']);
      } else if (call.method == kWindowEventMoveTabToNewWindow) {
        final args = call.arguments.split(',');
        int? windowId;
        try {
          windowId = int.parse(args[0]);
        } catch (e) {
          debugPrint("Failed to parse window id '${call.arguments}': $e");
        }
        WindowType? windowType;
        try {
          windowType = WindowType.values.byName(args[3]);
        } catch (e) {
          debugPrint("Failed to parse window type '${call.arguments}': $e");
        }
        if (windowId != null && windowType != null) {
          await rustDeskWinManager.moveTabToNewWindow(
              windowId, args[1], args[2], windowType);
        }
      } else if (call.method == kWindowEventOpenMonitorSession) {
        final args = jsonDecode(call.arguments);
        final windowId = args['window_id'] as int;
        final peerId = args['peer_id'] as String;
        final display = args['display'] as int;
        final displayCount = args['display_count'] as int;
        final windowType = args['window_type'] as int;
        final screenRect = parseParamScreenRect(args);
        await rustDeskWinManager.openMonitorSession(
            windowId, peerId, display, displayCount, screenRect, windowType);
      } else if (call.method == kWindowEventRemoteWindowCoords) {
        final windowId = int.tryParse(call.arguments);
        if (windowId != null) {
          return jsonEncode(
              await rustDeskWinManager.getOtherRemoteWindowCoords(windowId));
        }
      }
    });
    _uniLinksSubscription = listenUniLinks();

    if (bind.isIncomingOnly()) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _updateWindowSize();
      });
    }
    WidgetsBinding.instance.addObserver(this);
  }

  _updateWindowSize() {
    RenderObject? renderObject = _childKey.currentContext?.findRenderObject();
    if (renderObject == null) {
      return;
    }
    if (renderObject is RenderBox) {
      final size = renderObject.size;
      if (size != imcomingOnlyHomeSize) {
        imcomingOnlyHomeSize = size;
        windowManager.setSize(getIncomingOnlyHomeSize());
      }
    }
  }

  @override
  void dispose() {
    _uniLinksSubscription?.cancel();
    Get.delete<RxBool>(tag: 'stop-service');
    _updateTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      shouldBeBlocked(_block, canBeBlocked);
    }
  }
}

void setPasswordDialog({VoidCallback? notEmptyCallback}) async {
  final pw = await bind.mainGetPermanentPassword();
  final p0 = TextEditingController(text: pw);
  final p1 = TextEditingController(text: pw);
  var errMsg0 = "";
  var errMsg1 = "";
  final RxString rxPass = pw.trim().obs;
  final rules = [
    DigitValidationRule(),
    UppercaseValidationRule(),
    LowercaseValidationRule(),
    MinCharactersValidationRule(8),
  ];
  final maxLength = bind.mainMaxEncryptLen();

  gFFI.dialogManager.show((setState, close, context) {
    submit() {
      setState(() {
        errMsg0 = "";
        errMsg1 = "";
      });
      final pass = p0.text.trim();
      if (pass.isNotEmpty) {
        final Iterable violations = rules.where((r) => !r.validate(pass));
        if (violations.isNotEmpty) {
          setState(() {
            errMsg0 =
                '${translate('Prompt')}: ${violations.map((r) => r.name).join(', ')}';
          });
          return;
        }
      }
      if (p1.text.trim() != pass) {
        setState(() {
          errMsg1 =
              '${translate('Prompt')}: ${translate("The confirmation is not identical.")}';
        });
        return;
      }
      bind.mainSetPermanentPassword(password: pass);
      if (pass.isNotEmpty) {
        notEmptyCallback?.call();
      }
      close();
    }

    return CustomAlertDialog(
      title: Text(translate("Set Password")),
      content: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 500),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(
              height: 8.0,
            ),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    obscureText: true,
                    decoration: InputDecoration(
                        labelText: translate('Password'),
                        errorText: errMsg0.isNotEmpty ? errMsg0 : null),
                    controller: p0,
                    autofocus: true,
                    onChanged: (value) {
                      rxPass.value = value.trim();
                      setState(() {
                        errMsg0 = '';
                      });
                    },
                    maxLength: maxLength,
                  ).workaroundFreezeLinuxMint(),
                ),
              ],
            ),
            Row(
              children: [
                Expanded(child: PasswordStrengthIndicator(password: rxPass)),
              ],
            ).marginSymmetric(vertical: 8),
            const SizedBox(
              height: 8.0,
            ),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    obscureText: true,
                    decoration: InputDecoration(
                        labelText: translate('Confirmation'),
                        errorText: errMsg1.isNotEmpty ? errMsg1 : null),
                    controller: p1,
                    onChanged: (value) {
                      setState(() {
                        errMsg1 = '';
                      });
                    },
                    maxLength: maxLength,
                  ).workaroundFreezeLinuxMint(),
                ),
              ],
            ),
            const SizedBox(
              height: 8.0,
            ),
            Obx(() => Wrap(
                  runSpacing: 8,
                  spacing: 4,
                  children: rules.map((e) {
                    var checked = e.validate(rxPass.value.trim());
                    return Chip(
                        label: Text(
                          e.name,
                          style: TextStyle(
                              color: checked
                                  ? const Color(0xFF0A9471)
                                  : Color.fromARGB(255, 198, 86, 157)),
                        ),
                        backgroundColor: checked
                            ? const Color(0xFFD0F7ED)
                            : Color.fromARGB(255, 247, 205, 232));
                  }).toList(),
                ))
          ],
        ),
      ),
      actions: [
        dialogButton("Cancel", onPressed: close, isOutline: true),
        dialogButton("OK", onPressed: submit),
      ],
      onSubmit: submit,
      onCancel: close,
    );
  });
}
