import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../common.dart';
import '../pcnet_colors.dart';

Widget getConnectionPageTitle(BuildContext context, bool isWeb) {
  return Row(
    children: [
      Expanded(
          child: Row(
        children: [
          AutoSizeText(
            'Inserir ID PCNET-IT Connect',
            maxLines: 1,
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.merge(TextStyle(
                  height: 1,
                  color: PCNETColors.greenPrimary,
                  fontWeight: FontWeight.bold,
                )),
          ).marginOnly(right: 4),
          Tooltip(
            waitDuration: Duration(milliseconds: 300),
            message: translate(isWeb ? "web_id_input_tip" : "id_input_tip"),
            child: Icon(
              Icons.help_outline_outlined,
              size: 16,
              color: PCNETColors.greenPrimary.withOpacity(0.7),
            ),
          ),
        ],
      )),
    ],
  );
}
