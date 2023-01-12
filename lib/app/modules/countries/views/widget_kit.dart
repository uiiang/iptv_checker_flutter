import 'package:flutter/material.dart';
import 'package:iptv_checker_flutter/app/modules/countries/countries_model.dart';

Container buildStatusPanel(title, type) => Container(
      width: 50,
      height: 15,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
        Icon(
          type == 'ok' ? Icons.check_circle : Icons.error,
          size: 14,
          color: type == 'ok' ? Colors.green : Colors.red,
        ),
        Text(
          title,
          style: const TextStyle(fontSize: 12),
        ),
      ]),
    );

Container buildEpgFlag(bool hasEpg) => Container(
      width: 30,
      height: 15,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: hasEpg ? Colors.green.shade500 : Colors.grey.shade500,
        borderRadius: BorderRadius.circular(5),
        // border: Border.all(color: Colors.black, width: 0),
      ),
      child: const Text(
        "EPG",
        style: TextStyle(color: Colors.white, fontSize: 8),
      ),
    );

Container buildHandleBtn(String title, {bool disable = false}) => Container(
      margin: const EdgeInsets.all(2),
      padding: const EdgeInsets.only(left: 10, top: 5, right: 10, bottom: 5),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: disable ? Colors.grey.shade500 : Colors.greenAccent.shade700,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: Colors.black, width: 0),
      ),
      child: Text(
        title,
        style: const TextStyle(color: Colors.white),
      ),
    );

Row getCountryItemRow(Data item, {fontSize = 14.0}) => Row(
      children: [
        Text(
          item.flag ?? '',
          style: const TextStyle(fontSize: 22),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(left: 5),
            child: Text(item.name ?? '',
                style: TextStyle(fontSize: fontSize),
                textScaleFactor: 1,
                softWrap: true,
                overflow: TextOverflow.fade),
          ),
        )
      ],
    );
