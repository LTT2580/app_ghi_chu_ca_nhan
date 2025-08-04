class DatabaseConstants {
  static const String dbName = 'task_manager.db';
  static const int dbVersion = 2;

  // Table names
  static const String tableUsers = 'users';
  static const String tableNhomViec = 'nhom_viec';
  static const String tableNhiemVu = 'nhiem_vu';

  // Common column names
  static const String columnId = 'id';
  static const String columnUserId = 'user_id';

  // Users table columns
  static const String columnName = 'name';
  static const String columnEmail = 'email';
  static const String columnMatKhau = 'matkhau';
  static const String columnAvatar = 'avatar';

  // NhomViec table columns
  static const String columnTitle = 'title';
  static const String columnDescription = 'description';
  static const String columnTimeRange = 'time_range';
  static const String columnColor = 'color';
  static const String columnParentGroupId = 'parent_group_id';

  // NhiemVu table columns
  static const String columnSubtitle = 'subtitle';
  static const String columnDate = 'date';
  static const String columnStartTime = 'start_time';
  static const String columnEndTime = 'end_time';
  static const String columnIsCompleted = 'is_completed';
  static const String columnGroupId = 'group_id';
}