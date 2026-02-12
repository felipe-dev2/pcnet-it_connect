// Connection form and status widget - PCNET-IT Connect

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

/// State for the online status widget.
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
                          decoration: TextDecoration.underline,
                          fontSize: em,
                          color: PCNETColors.greenPrimary)))
              .marginOnly(left: em),
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
              ),
            ).marginSymmetric(horizontal: em),
            _buildConnStatusMsg(),
            // stop
            if (!isIncomingOnly) startServiceWidget(),
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
      style: TextStyle(
        fontSize: em,
        color: PCNETColors.textPrimary,
      ),
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

/// Connection form for connecting to a remote peer.
/// Renders as a vertical form (ID input + Connect button).
class ConnectionPage extends StatefulWidget {
  const ConnectionPage({Key? key}) : super(key: key);

  @override
  State<ConnectionPage> createState() => _ConnectionPageState();
}

/// State for the connection form.
class _ConnectionPageState extends State<ConnectionPage>
    with SingleTickerProviderStateMixin, WindowListener {
  /// Controller for the id input bar.
  final _idController = IDTextEditingController();

  final RxBool _idInputFocused = false.obs;
  final FocusNode _idFocusNode = FocusNode();
  final TextEditingController _idEditingController = TextEditingController();

  bool isWindowMinimized = false;

  final AllPeersLoader _allPeersLoader = AllPeersLoader();

  // https://github.com/flutter/flutter/issues/157244
  Iterable<Peer> _autocompleteOpts = [];

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
        Get.forceAppUpdate();
      }
      isWindowMinimized = false;
    }
  }

  @override
  void onWindowEnterFullScreen() {
    stateGlobal.resizeEdgeSize.value = 0;
  }

  @override
  void onWindowLeaveFullScreen() {
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
      _idEditingController.selection =
          TextSelection(baseOffset: 0, extentOffset: textLength);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Heading
        Text(
          'Connect to Remote Device',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: PCNETColors.textPrimary,
          ),
        ),
        SizedBox(height: 6),
        Text(
          'Enter your access to remote device',
          style: TextStyle(
            fontSize: 12,
            color: PCNETColors.textSecondary,
          ),
        ),
        SizedBox(height: 16),
        // ID input with autocomplete
        _buildIDField(context),
        SizedBox(height: 14),
        // Full-width Connect button
        SizedBox(
          width: double.infinity,
          height: 44,
          child: ElevatedButton(
            onPressed: () => onConnect(),
            style: ElevatedButton.styleFrom(
              backgroundColor: PCNETColors.greenPrimary,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Connect',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// ID input field with autocomplete
  Widget _buildIDField(BuildContext context) {
    return SizedBox(
      height: 44,
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
                  fontSize: 15,
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
                      : translate('Enter Remote ID'),
                  hintStyle: TextStyle(
                    color: PCNETColors.textSecondary,
                    fontSize: 14,
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

  /// Callback for the connect button.
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
