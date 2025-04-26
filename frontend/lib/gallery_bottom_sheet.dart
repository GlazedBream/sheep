import 'package:flutter/material.dart';

class GalleryBottomSheet extends StatefulWidget {
  const GalleryBottomSheet({super.key});

  @override
  State<GalleryBottomSheet> createState() => _GalleryBottomSheetState();
}

class _GalleryBottomSheetState extends State<GalleryBottomSheet> {
  List<int> selectedIndexes = [];

  @override
  Widget build(BuildContext context) {
    final photos = List.generate(14, (index) => '사진 $index');

    return DraggableScrollableSheet(
      initialChildSize: 0.5,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (_, controller) => Column(
        children: [
          const Padding(
            padding: EdgeInsets.all(12.0),
            child: Text(
              "오늘 일기에 들어갈 사진을 선택해주세요\n최대 4장까지 가능합니다",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
          ),
          Expanded(
            child: GridView.builder(
              controller: controller,
              padding: const EdgeInsets.all(10),
              itemCount: photos.length + 1,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemBuilder: (context, index) {
                if (index == photos.length) {
                  return GestureDetector(
                    onTap: () {
                      print("사진첩으로 이동");
                    },
                    child: Container(
                      color: Colors.grey[300],
                      child: const Center(child: Text("사진첩")),
                    ),
                  );
                }

                final isSelected = selectedIndexes.contains(index);
                final selectedOrder = selectedIndexes.indexOf(index) + 1;

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      if (isSelected) {
                        selectedIndexes.remove(index);
                      } else if (selectedIndexes.length < 4) {
                        selectedIndexes.add(index);
                      }
                    });
                  },
                  child: Stack(
                    children: [
                      Container(
                        color: Colors.grey[200],
                        child: Center(child: Text(photos[index])),
                      ),
                      if (isSelected)
                        Positioned(
                          top: 5,
                          left: 5,
                          child: CircleAvatar(
                            radius: 12,
                            backgroundColor: Colors.yellow,
                            child: Text(
                              '$selectedOrder',
                              style: const TextStyle(color: Colors.black),
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
          Align(
            alignment: Alignment.bottomRight,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text("완료"),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
