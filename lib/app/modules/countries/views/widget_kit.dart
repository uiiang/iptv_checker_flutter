import 'package:flutter/material.dart';
import 'package:iptv_checker_flutter/app/modules/countries/countries_model.dart';

Row getCountryItemRow(Data item) {
  return Row(
    children: [
      Text(
        item.flag ?? '',
        style: const TextStyle(fontSize: 22),
      ),
      Expanded(
        child: Padding(
          padding: const EdgeInsets.only(left: 5),
          child: Text(item.name ?? '',
              style: const TextStyle(
                fontSize: 12,
              ),
              softWrap: true,
              overflow: TextOverflow.fade),
        ),
      )
    ],
  );
}
