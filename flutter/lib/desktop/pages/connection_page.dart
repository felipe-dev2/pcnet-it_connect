// main window right pane - PCNET-IT Connect Customization

import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_hbb/consts.dart';
import 'package:flutter_hbb/desktop/widgets/popup_menu.dart';
import 'package:flutter_hbb/models/state_model.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:window_manager/window_manager.dart';
import 'package:flutter_hbb/models/peer_model.dart';

import '../../common.dart';
import '../../common/formatter/id_formatter.dart';
import '../../common/widgets/peer_tab_page.dart';
import '../../common/widgets/autocomplete.dart';
import '../../models/platform_model.dart';
import '../../desktop/widgets/material_mod_popup_menu.dart' as mod_menu;
import '../../common/pcnet_colors.dart';

class OnlineStatusWidget extends StatefulWidget {
  const OnlineStatusWidget({Key? key, this.onSvcStatusChanged})
      : super(key: key);

  final VoidCallback? onSvcStatusChanged;

  @override
  State<OnlineStatusWidget> createState() => _OnlineStatusWidgetState();
}

/// State for the connection page.
class _OnlineStatusWidgetState extends State<OnlineStatusWidget> {
  final _svcStopped = Get.find<RxBool>(tag: 'stop-service');
  final _svcIsUsingPublicServer = true.obs;
  Timer? _updateTimer;

  double get em => 14.0;
  double? get height => bind.isIncomingOnly() ? null : em * 3;

  void onUsePublicServerGuide() {
    const url = "https://rustdesk.com/pricing";
    canLaunchUrlString(url).then((can) {
      if (can) {
        launchUrlString(url);
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _updateTimer = periodic_immediate(Duration(seconds: 1), () async {
      updateStatus();
    });
  }

  @override
  void dispose() {
    _updateTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isIncomingOnly = bind.isIncomingOnly();
    startServiceWidget() => Offstage(
          offstage: !_svcStopped.value,
          child: InkWell(
                  onTap: () async {
                    await start_service(true);
                  },
                  child: Text(translate("Start service"),
                      style: TextStyle(
                          decoration: TextDecoration.underline, fontSize: em)))
              .marginOnly(left: em),
        );

    setupServerWidget() => Flexible(
          child: Offstage(
            offstage: !(!_svcStopped.value &&
                stateGlobal.svcStatus.value == SvcStatus.ready &&
                _svcIsUsingPublicServer.value),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(', ', style: TextStyle(fontSize: em)),
                Flexible(
                  child: InkWell(
                    onTap: onUsePublicServerGuide,
                    child: Row(
                      children: [
                        Flexible(
                          child: Text(
                            translate('setup_server_tip'),
                            style: TextStyle(
                                decoration: TextDecoration.underline,
                                fontSize: em),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              ],
            ),
          ),
        );

    basicWidget() => Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              height: 8,
              width: 8,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(4),
                color: _svcStopped.value ||
                        stateGlobal.svcStatus.value == SvcStatus.connecting
                    ? PCNETColors.statusConnecting
                    : (stateGlobal.svcStatus.value == SvcStatus.ready
                        ? PCNETColors.statusOnline
                        : PCNETColors.statusError),
                boxShadow: stateGlobal.svcStatus.value == SvcStatus.ready
                    ? PCNETColors.neonGlow
                    : null,
              ),
            ).marginSymmetric(horizontal: em),
            Container(
              width: isIncomingOnly ? 226 : null,
              child: _buildConnStatusMsg(),
            ),
            // stop
            if (!isIncomingOnly) startServiceWidget(),
            // ready && public
            // No need to show the guide if is custom client.
            if (!isIncomingOnly) setupServerWidget(),
          ],
        );

    return Container(
      height: height,
      child: Obx(() => isIncomingOnly
          ? Column(
              children: [
                basicWidget(),
                Align(
                        child: startServiceWidget(),
                        alignment: Alignment.centerLeft)
                    .marginOnly(top: 2.0, left: 22.0),
              ],
            )
          : basicWidget()),
    ).paddingOnly(right: isIncomingOnly ? 8 : 0);
  }

  _buildConnStatusMsg() {
    widget.onSvcStatusChanged?.call();
    return Text(
      _svcStopped.value
          ? translate("Service is not running")
          : stateGlobal.svcStatus.value == SvcStatus.connecting
              ? translate("connecting_status")
              : stateGlobal.svcStatus.value == SvcStatus.notReady
                  ? translate("not_ready_status")
                  : translate('Ready'),
      style: TextStyle(fontSize: em),
    );
  }

  updateStatus() async {
    final status =
        jsonDecode(await bind.mainGetConnectStatus()) as Map<String, dynamic>;
    final statusNum = status['status_num'] as int;
    if (statusNum == 0) {
      stateGlobal.svcStatus.value = SvcStatus.connecting;
    } else if (statusNum == -1) {
      stateGlobal.svcStatus.value = SvcStatus.notReady;
    } else if (statusNum == 1) {
      stateGlobal.svcStatus.value = SvcStatus.ready;
    } else {
      stateGlobal.svcStatus.value = SvcStatus.notReady;
    }
    _svcIsUsingPublicServer.value = await bind.mainIsUsingPublicServer();
    try {
      stateGlobal.videoConnCount.value = status['video_conn_count'] as int;
    } catch (_) {}
  }
}

/// Connection page for connecting to a remote peer.
class ConnectionPage extends StatefulWidget {
  const ConnectionPage({Key? key}) : super(key: key);

  @override
  State<ConnectionPage> createState() => _ConnectionPageState();
}

/// State for the connection page.
class _ConnectionPageState extends State<ConnectionPage>
    with SingleTickerProviderStateMixin, WindowListener {
  /// Controller for the id input bar.
  final _idController = IDTextEditingController();

  final RxBool _idInputFocused = false.obs;
  final FocusNode _idFocusNode = FocusNode();
  final TextEditingController _idEditingController = TextEditingController();

  String selectedConnectionType = 'Connect';

  bool isWindowMinimized = false;

  final AllPeersLoader _allPeersLoader = AllPeersLoader();

  // https://github.com/flutter/flutter/issues/157244
  Iterable<Peer> _autocompleteOpts = [];

  final _menuOpen = false.obs;

  @override
  void initState() {
    super.initState();
    _allPeersLoader.init(setState);
    _idFocusNode.addListener(onFocusChanged);
    if (_idController.text.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        final lastRemoteId = await bind.mainGetLastRemoteId();
        if (lastRemoteId != _idController.id) {
          setState(() {
            _idController.id = lastRemoteId;
          });
        }
      });
    }
    Get.put<TextEditingController>(_idEditingController);
    Get.put<IDTextEditingController>(_idController);
    windowManager.addListener(this);
  }

  @override
  void dispose() {
    _idController.dispose();
    windowManager.removeListener(this);
    _allPeersLoader.clear();
    _idFocusNode.removeListener(onFocusChanged);
    _idFocusNode.dispose();
    _idEditingController.dispose();
    if (Get.isRegistered<IDTextEditingController>()) {
      Get.delete<IDTextEditingController>();
    }
    if (Get.isRegistered<TextEditingController>()) {
      Get.delete<TextEditingController>();
    }
    super.dispose();
  }

  @override
  void onWindowEvent(String eventName) {
    super.onWindowEvent(eventName);
    if (eventName == 'minimize') {
      isWindowMinimized = true;
    } else if (eventName == 'maximize' || eventName == 'restore') {
      if (isWindowMinimized && isWindows) {
        // windows can't update when minimized.
        Get.forceAppUpdate();
      }
      isWindowMinimized = false;
    }
  }

  @override
  void onWindowEnterFullScreen() {
    // Remove edge border by setting the value to zero.
    stateGlobal.resizeEdgeSize.value = 0;
  }

  @override
  void onWindowLeaveFullScreen() {
    // Restore edge border to default edge size.
    stateGlobal.resizeEdgeSize.value = stateGlobal.isMaximized.isTrue
        ? kMaximizeEdgeSize
        : windowResizeEdgeSize;
  }

  @override
  void onWindowClose() {
    super.onWindowClose();
    bind.mainOnMainWindowClose();
  }

  void onFocusChanged() {
    _idInputFocused.value = _idFocusNode.hasFocus;
    if (_idFocusNode.hasFocus) {
      if (_allPeersLoader.needLoad) {
        _allPeersLoader.getAllPeers();
      }

      final textLength = _idEditingController.value.text.length;
      // Select all to facilitate removing text, just following the behavior of address input of chrome.
      _idEditingController.selection =
          TextSelection(baseOffset: 0, extentOffset: textLength);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: PCNETColors.blackPrimary,
      child: Column(
        children: [
          // Connection toolbar - compact horizontal bar
          Container(
            padding: EdgeInsets.fromLTRB(16, 10, 16, 10),
            decoration: BoxDecoration(
              color: PCNETColors.surfaceColor,
              border: Border(
                bottom: BorderSide(color: PCNETColors.dividerColor, width: 1),
              ),
            ),
            child: _buildConnectionToolbar(context),
          ),
          // Peers list - takes all remaining space
          Expanded(child: PeerTabPage().paddingOnly(left: 12.0, right: 12.0)),
        ],
      ),
    );
  }

  /// Compact connection toolbar - single horizontal row
  Widget _buildConnectionToolbar(BuildContext context) {
    return Row(
      children: [
        Icon(Icons.link, size: 16, color: PCNETColors.greenPrimary),
        SizedBox(width: 8),
        Text(
          translate('Control Remote Desktop'),
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: PCNETColors.textSecondary,
          ),
        ),
        SizedBox(width: 16),
        // Connection input field - expands to fill space
        Expanded(child: _buildCompactIDField(context)),
        SizedBox(width: 10),
        // Connect button
        SizedBox(
          height: 36,
          child: ElevatedButton(
            onPressed: () => onConnect(),
            style: ElevatedButton.styleFrom(
              backgroundColor: PCNETColors.greenPrimary,
              foregroundColor: PCNETColors.blackPrimary,
              elevation: 0,
              padding: EdgeInsets.symmetric(horizontal: 20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              "Conectar",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
        ),
        SizedBox(width: 6),
        // More options dropdown
        _buildMoreOptionsButton(context),
      ],
    );
  }

  /// Compact ID input field styled as a search bar
  Widget _buildCompactIDField(BuildContext context) {
    return SizedBox(
      height: 36,
      child: RawAutocomplete<Peer>(
        optionsBuilder: (TextEditingValue textEditingValue) {
          if (textEditingValue.text == '') {
            _autocompleteOpts = const Iterable<Peer>.empty();
          } else if (_allPeersLoader.peers.isEmpty &&
              !_allPeersLoader.isPeersLoaded) {
            Peer emptyPeer = Peer(
              id: '', username: '', hostname: '', alias: '',
              platform: '', tags: [], hash: '', password: '',
              forceAlwaysRelay: false, rdpPort: '', rdpUsername: '',
              loginName: '', device_group_name: '', note: '',
            );
            _autocompleteOpts = [emptyPeer];
          } else {
            String textWithoutSpaces = textEditingValue.text.replaceAll(" ", "");
            if (int.tryParse(textWithoutSpaces) != null) {
              textEditingValue = TextEditingValue(
                text: textWithoutSpaces,
                selection: textEditingValue.selection,
              );
            }
            String textToFind = textEditingValue.text.toLowerCase();
            _autocompleteOpts = _allPeersLoader.peers
                .where((peer) =>
                    peer.id.toLowerCase().contains(textToFind) ||
                    peer.username.toLowerCase().contains(textToFind) ||
                    peer.hostname.toLowerCase().contains(textToFind) ||
                    peer.alias.toLowerCase().contains(textToFind))
                .toList();
          }
          return _autocompleteOpts;
        },
        focusNode: _idFocusNode,
        textEditingController: _idEditingController,
        fieldViewBuilder: (
          BuildContext context,
          TextEditingController fieldTextEditingController,
          FocusNode fieldFocusNode,
          VoidCallback onFieldSubmitted,
        ) {
          updateTextAndPreserveSelection(
              fieldTextEditingController, _idController.text);
          return Obx(() => TextField(
                autocorrect: false,
                enableSuggestions: false,
                keyboardType: TextInputType.visiblePassword,
                focusNode: fieldFocusNode,
                style: const TextStyle(
                  fontFamily: 'WorkSans',
                  fontSize: 14,
                  height: 1.2,
                  color: PCNETColors.textPrimary,
                ),
                maxLines: 1,
                cursorColor: PCNETColors.greenPrimary,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: PCNETColors.grayDark,
                  counterText: '',
                  hintText: _idInputFocused.value
                      ? null
                      : 'Digite o ID de conexão',
                  hintStyle: TextStyle(
                    color: PCNETColors.textSecondary,
                    fontSize: 13,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 0),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: PCNETColors.borderColor,
                      width: 1,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(
                      color: PCNETColors.greenPrimary,
                      width: 2,
                    ),
                  ),
                ),
                controller: fieldTextEditingController,
                inputFormatters: [IDTextInputFormatter()],
                onChanged: (v) {
                  _idController.id = v;
                },
                onSubmitted: (_) {
                  onConnect();
                },
              ).workaroundFreezeLinuxMint());
        },
        onSelected: (option) {
          setState(() {
            _idController.id = option.id;
            FocusScope.of(context).unfocus();
          });
        },
        optionsViewBuilder: (BuildContext context,
            AutocompleteOnSelected<Peer> onSelected,
            Iterable<Peer> options) {
          options = _autocompleteOpts;
          double maxHeight = options.length * 50;
          if (options.length == 1) maxHeight = 52;
          else if (options.length == 3) maxHeight = 146;
          else if (options.length == 4) maxHeight = 193;
          maxHeight = maxHeight.clamp(0, 200);

          return Align(
            alignment: Alignment.topLeft,
            child: Container(
                decoration: BoxDecoration(
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 8,
                      spreadRadius: 0,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                    borderRadius: BorderRadius.circular(5),
                    child: Material(
                      elevation: 4,
                      color: PCNETColors.grayDark,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxHeight: maxHeight,
                          maxWidth: 319,
                        ),
                        child: _allPeersLoader.peers.isEmpty &&
                                !_allPeersLoader.isPeersLoaded
                            ? Container(
                                height: 80,
                                color: PCNETColors.grayDark,
                                child: Center(
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      PCNETColors.greenPrimary,
                                    ),
                                  ),
                                ))
                            : Padding(
                                padding: const EdgeInsets.only(top: 5),
                                child: ListView(
                                  children: options
                                      .map((peer) =>
                                          AutocompletePeerTile(
                                              onSelect: () =>
                                                  onSelected(peer),
                                              peer: peer))
                                      .toList(),
                                ),
                              ),
                      ),
                    ))),
          );
        },
      ),
    );
  }

  /// More options dropdown button
  Widget _buildMoreOptionsButton(BuildContext context) {
    return Container(
      height: 36,
      width: 36,
      decoration: BoxDecoration(
        border: Border.all(color: PCNETColors.borderColor, width: 1),
        borderRadius: BorderRadius.circular(8),
        color: PCNETColors.grayDark,
      ),
      child: Center(
        child: StatefulBuilder(
          builder: (context, setState) {
            var offset = Offset(0, 0);
            return Obx(() => InkWell(
                  child: _menuOpen.value
                      ? Transform.rotate(
                          angle: 3.14159,
                          child: Icon(
                            IconFont.more,
                            size: 14,
                            color: PCNETColors.greenPrimary,
                          ),
                        )
                      : Icon(
                          IconFont.more,
                          size: 14,
                          color: PCNETColors.textSecondary,
                        ),
                  onTapDown: (e) {
                    offset = e.globalPosition;
                  },
                  onTap: () async {
                    _menuOpen.value = true;
                    final x = offset.dx;
                    final y = offset.dy;
                    await mod_menu
                        .showMenu(
                      context: context,
                      position: RelativeRect.fromLTRB(x, y, x, y),
                      items: [
                        ('Transfer file', () => onConnect(isFileTransfer: true)),
                        ('View camera', () => onConnect(isViewCamera: true)),
                        ('${translate('Terminal')} (beta)', () => onConnect(isTerminal: true)),
                      ]
                          .map((e) => MenuEntryButton<String>(
                                childBuilder: (TextStyle? style) => Text(
                                  translate(e.$1),
                                  style: style,
                                ),
                                proc: () => e.$2(),
                                padding: EdgeInsets.symmetric(
                                    horizontal: kDesktopMenuPadding.left),
                                dismissOnClicked: true,
                              ))
                          .map((e) => e.build(
                              context,
                              const MenuConfig(
                                  commonColor: CustomPopupMenuTheme.commonColor,
                                  height: CustomPopupMenuTheme.height,
                                  dividerHeight: CustomPopupMenuTheme.dividerHeight)))
                          .expand((i) => i)
                          .toList(),
                      elevation: 8,
                    )
                        .then((_) {
                      _menuOpen.value = false;
                    });
                  },
                ));
          },
        ),
      ),
    );
  }

  /// Callback for the connect button.
  /// Connects to the selected peer.
  void onConnect(
      {bool isFileTransfer = false,
      bool isViewCamera = false,
      bool isTerminal = false}) {
    var id = _idController.id;
    connect(context, id,
        isFileTransfer: isFileTransfer,
        isViewCamera: isViewCamera,
        isTerminal: isTerminal);
  }

}
