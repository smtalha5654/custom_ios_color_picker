import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

import 'color_observer.dart';
import 'extensions.dart';
import 'helpers/cache_helper.dart';

/// Default colors if history is empty
const List<Color> defaultHistoryColors = [
  Colors.black,
  Colors.white,
  Colors.red,
  Colors.green,
  Colors.blue,
  Colors.yellow,
  Colors.orange,
  Colors.purple,
  Colors.pink,
  Colors.teal,
];

class HistoryColors extends StatefulWidget {
  final ValueChanged<Color> onColorChanged;

  const HistoryColors({super.key, required this.onColorChanged});

  @override
  State<HistoryColors> createState() => _HistoryColorsState();
}

class _HistoryColorsState extends State<HistoryColors> {
  int page = 0;
  int colorPage = 0;

  final PageController pageController = PageController();

  List<Color> historyColors = [];

  @override
  void initState() {
    super.initState();
    initializeData();
  }

  Future<void> initializeData() async {
    var savedColors = await CacheHelper().getData(key: "history_colors");

    if (savedColors == null || (savedColors as List).isEmpty) {
      historyColors = List.from(defaultHistoryColors);
      setHistory();
    } else {
      for (var value in savedColors) {
        historyColors.add(HexColor.fromHex(value.toString()));
      }
      setHistory(empty: false);
    }
  }

  void setHistory({bool empty = true, bool delete = false}) {
    page = 0;

    for (int i = 0; i < historyColors.length + 1; i++) {
      if (i % 10 == 0) {
        page++;
      }
    }

    if (empty) {
      CacheHelper().setData(
        key: "history_colors",
        value: historyColors.toStringList(),
      );

      if (page > 1 && colorPage != page && !delete) {
        pageController.jumpToPage(page);
        colorPage = page;
      }
    } else {
      if (!delete) {
        Future.delayed(const Duration(milliseconds: 200)).then((v) {
          pageController.jumpToPage(page);
        });
      }
    }

    setState(() {});
  }

  @override
  void dispose() {
    pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return SizedBox(
      height: 97,
      width: screenWidth - 120,
      child: Column(
        children: [
          Expanded(
            child: PageView(
              controller: pageController,
              onPageChanged: (v) {
                setState(() {
                  colorPage = v;
                });
              },
              children: List.generate(page, (pageIndex) {
                return GridView.count(
                  physics: const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  padding: const EdgeInsets.only(left: 27, right: 17),
                  crossAxisCount: 5,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: ((screenWidth - 304) / 5),
                  dragStartBehavior: DragStartBehavior.down,
                  children: List.generate(
                    historyColors.length >= 10
                        ? (historyColors.length - (pageIndex * 10)) + 1
                        : historyColors.length + 1,
                    (index) {
                      int realIndex = index + (pageIndex * 10);

                      /// Add button
                      if (realIndex == historyColors.length) {
                        return InkWell(
                          onTap: () {
                            historyColors.add(colorController.value);
                            setHistory();
                          },
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(
                              minHeight: 30,
                              minWidth: 30,
                              maxWidth: 30,
                              maxHeight: 30,
                            ),
                            child: Container(
                              height: 30,
                              width: 30,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withValues(alpha: 0.16),
                              ),
                              child: const Icon(
                                Icons.add,
                                color: Color(0xffB0B0BD),
                              ),
                            ),
                          ),
                        );
                      }

                      /// Color item
                      return InkWell(
                        onTap: () {
                          colorController.updateColor(historyColors[realIndex]);
                          widget.onColorChanged(colorController.value);
                          setState(() {});
                        },
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            ConstrainedBox(
                              constraints: const BoxConstraints(
                                minHeight: 30,
                                minWidth: 30,
                                maxWidth: 30,
                                maxHeight: 30,
                              ),
                              child: Container(
                                height: 30,
                                width: 30,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: historyColors[realIndex],
                                ),
                              ),
                            ),

                            /// Selected indicator
                            if (colorController.value.toHex() ==
                                historyColors[realIndex].toHex())
                              Container(
                                height: 24,
                                width: 24,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 2,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                );
              }),
            ),
          ),

          /// Page indicator
          if (page > 1)
            Padding(
              padding: const EdgeInsets.only(top: 10.0),
              child: AnimatedSmoothIndicator(
                activeIndex: colorPage,
                count: page,
                effect: ScrollingDotsEffect(
                  dotHeight: 6,
                  dotWidth: 6,
                  maxVisibleDots: 11,
                  spacing: 10,
                  dotColor: Colors.white.withValues(alpha: 0.3),
                  activeDotColor: Colors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }
}