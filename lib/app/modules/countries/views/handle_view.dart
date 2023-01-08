import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:iptv_checker_flutter/app/modules/countries/controllers/countries_controller.dart';
import 'package:iptv_checker_flutter/utils/widget/dpad_detector.dart';

class HandleView extends StatelessWidget {
  static const _TAG = 'HandleView';

  const HandleView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    CountriesController controller = Get.put(CountriesController());
    final selectedListPanel =  Obx(() {
      final selectList =
      controller.countries.where((p0) => p0.selected.value).toList();
      return ListView.builder(
        itemCount: selectList.length,
        itemBuilder: (BuildContext context, int index) {
          final item = selectList[index];
          return Container(
              margin: const EdgeInsets.all(2),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(5),
                border: Border.all(
                    color: Colors.black,
                    width: 1),
              ),
              child: Padding(
                padding: const EdgeInsets.all(5),
                child: Row(
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
                ),
              ));
        },
      );
    });
    Row btnPanel = Row(
      children: [
        //清除
        DPadDetector(
          onTap: () {
            // print('clear');
          },
          child: ElevatedButton(
            onPressed: () {
              controller.clearSelect();
            },
            child: const Text("清除"),
          ),
        ),
        //生成
        DPadDetector(
          onTap: () {
            // print('generator');
          },
          child: ElevatedButton(
            onPressed: () {
              print('generator');
            },
            child: const Text("生成"),
          ),
        ),
      ],
    );
    return Column(
      children: [
        btnPanel,
        Expanded(
            child: SizedBox(
          height: 300,
          width: 200,
          child:selectedListPanel,
        )),
      ],
    );
  }
}
