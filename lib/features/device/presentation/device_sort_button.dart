import 'package:flutter/material.dart';

import 'package:sefer/features/device/domain/device_sort.dart';

class DeviceSortButton extends StatelessWidget {
  const DeviceSortButton({
    super.key,
    required this.sort,
    required this.onSelected,
  });

  final DeviceSort sort;
  final ValueChanged<DeviceSort> onSelected;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<DeviceSort>(
      icon: const Icon(Icons.sort),
      tooltip: 'Sort: ${sort.label}',
      initialValue: sort,
      onSelected: onSelected,
      itemBuilder: (_) => [
        for (final option in DeviceSort.all)
          CheckedPopupMenuItem<DeviceSort>(
            value: option,
            checked: option == sort,
            child: Text(option.label),
          ),
      ],
    );
  }
}
