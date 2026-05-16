enum DataSortOption { 
  nameAsc, 
  nameDesc, 
  newest, 
  oldest 
}

extension DataSortOptionExtension on DataSortOption {
  String get label {
    switch (this) {
      case DataSortOption.nameAsc: return 'A - Z';
      case DataSortOption.nameDesc: return 'Z - A';
      case DataSortOption.newest: return 'Data Terbaru';
      case DataSortOption.oldest: return 'Data Terlama';
    }
  }
}
