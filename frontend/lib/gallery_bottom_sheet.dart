import 'package:flutter/material.dart';

class GalleryBottomSheet extends StatefulWidget {
  const GalleryBottomSheet({super.key});

  @override
  State<GalleryBottomSheet> createState() => _GalleryBottomSheetState();
}

class _GalleryBottomSheetState extends State<GalleryBottomSheet> {
  List<int> selectedIndexes = [];  // 선택된 이미지 인덱스를 저장할 리스트

  @override
  Widget build(BuildContext context) {
    final mockPhotos = [
      'assets/images/demo01.jpg',
      'assets/images/demo02.jpg',
      'assets/images/demo03.jpg',
      'assets/images/demo04.jpg',
      'assets/images/demo05.jpg',
      'assets/images/demo06.jpg',
      ...List.generate(9, (i) => 'assets/images/test$i.jpg'),
    ];

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
              "오늘 일기에 들어갈 사진을 선택해주세요\n최대 2장까지 가능합니다",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
          ),
          Expanded(
            child: GridView.builder(
              controller: controller,
              padding: const EdgeInsets.all(10),
              itemCount: mockPhotos.length + 1,  // 사진첩 추가 버튼 포함
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,  // 한 줄에 3개의 이미지를 보여줌
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemBuilder: (context, index) {
                if (index == mockPhotos.length) {
                  // 사진첩 버튼
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

                final isSelected = selectedIndexes.contains(index);  // 이미지 선택 여부
                final selectedOrder = selectedIndexes.indexOf(index) + 1;  // 선택된 이미지 번호

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      if (isSelected) {
                        selectedIndexes.remove(index);  // 이미지 선택 해제
                      } else if (selectedIndexes.length < 2) {
                        selectedIndexes.add(index);  // 최대 2장만 선택
                      }
                    });
                  },
                  child: Stack(
                    children: [
                      // 이미지 표시
                      Image.asset(
                        mockPhotos[index],
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                      ),
                      // 선택된 이미지에 번호 표시
                      if (isSelected)
                        Positioned(
                          top: 5,
                          left: 5,
                          child: CircleAvatar(
                            radius: 12,
                            backgroundColor: Colors.yellow,
                            child: Text(
                              '$selectedOrder',  // 선택된 이미지 번호
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
                  final selectedPaths = selectedIndexes
                      .map((i) => mockPhotos[i])  // 선택된 이미지 경로 리스트
                      .toList();

                  Navigator.pop(context, selectedPaths);  // 선택된 이미지 경로 반환
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