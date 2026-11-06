sealed class DeviceSelectionPurpose {
  const DeviceSelectionPurpose();
}

class ManageDeviceFiles extends DeviceSelectionPurpose {
  const ManageDeviceFiles();
}

class AddFilesToCollection extends DeviceSelectionPurpose {
  const AddFilesToCollection(this.collectionId);

  final String collectionId;
}
