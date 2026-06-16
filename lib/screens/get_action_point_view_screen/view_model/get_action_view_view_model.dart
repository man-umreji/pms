import 'dart:developer';

import 'package:flutter/material.dart';
import '../model/delete_attachments_model.dart';
import '../model/get_action_point_model.dart';
import '../model/update_action_point_model.dart';
import '../model/get_all_status_model.dart';
import '../repository/delete_attachments_repo.dart';
import '../repository/get_action_view_repo.dart';
import '../repository/update_action_point_repo.dart';
import '../repository/get_all_status_repo.dart';

class GetActionPointViewModel extends ChangeNotifier {
  final GetActionPointViewRepository _repository =
  GetActionPointViewRepository();

  final UpdateActionPointRepository _updateRepository =
  UpdateActionPointRepository();

  final GetAllStatusRepository _statusRepository =
  GetAllStatusRepository();
  // Add this in your GetActionPointViewModel class
  /// 📝 Get remarks history
  List<Remark> get remarks => _response?.data?.remarks ?? [];
  List<Projects> get projects => _response?.data?.projects ?? []; // ✅ FIXED
  /// 🔄 State
  int get meetingIdSafe => int.tryParse(meeting?.id ?? '0') ?? 0;
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isUpdating = false;
  bool get isUpdating => _isUpdating;

  String? _error;
  String? get error => _error;

  String? _updateMessage;
  String? get updateMessage => _updateMessage;

  GetActionViewResModel? _response;
  GetActionViewResModel? get response => _response;

  /// 📊 Status List from API
  List<StatusList>? _statusList;
  List<StatusList>? get statusList => _statusList;

  bool _isLoadingStatuses = false;
  bool get isLoadingStatuses => _isLoadingStatuses;

  /// 📊 Shortcuts
  List<Details> get details => _response?.data?.details ?? [];
  List<Attachments> get attachments => _response?.data?.attachments ?? [];
  Meeting? get meeting => _response?.data?.meeting;

  /// 🔍 Filter state
  String _selectedStatus = 'all';
  String get selectedStatus => _selectedStatus;

  /// 🔍 Search state
  String _searchQuery = '';
  String get searchQuery => _searchQuery;

  /// 🎯 Filtered List
  List<Details> get filteredDetails {
    var result = List<Details>.from(details); // ✅ FIXED COPY

    if (_selectedStatus != 'all') {
      result = result.where((e) =>
      (e.status ?? '').toLowerCase() == _selectedStatus.toLowerCase()).toList();
    }

    if (_searchQuery.isNotEmpty) {
      result = result.where((e) {
        return (e.description?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false) ||
            (e.assignedEmployeeName?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);
      }).toList();
    }

    return result;
  }


  /// 📊 Statistics
  int get totalCount => details.length;

  int get completedCount => details.where((d) => d.status == 'completed').length;

  int get pendingCount => details.where((d) => d.status == 'pending').length;

  int get inProgressCount => details.where((d) => d.status == 'in_progress').length;

  int get overdueCount {
    return details.where((d) {
      if (d.status == 'completed') return false;
      final targetDate = DateTime.tryParse(d.targetDate ?? '');
      return targetDate != null && targetDate.isBefore(DateTime.now());
    }).length;
  }

  double get completionPercentage {
    return totalCount > 0 ? (completedCount / totalCount) * 100 : 0;
  }
  Map<String, List<Details>> get groupedByStatus {
    final Map<String, List<Details>> grouped = {};
    for (final detail in details) {
      final status = detail.status ?? 'unknown';
      if (!grouped.containsKey(status)) {
        grouped[status] = [];
      }
      grouped[status]!.add(detail);
    }
    return grouped;
  }

  Map<String, List<Details>> get groupedByAssignee {
    final Map<String, List<Details>> grouped = {};
    for (final detail in details) {
      final assignee = detail.assignedEmployeeName ?? 'Unassigned';
      if (!grouped.containsKey(assignee)) {
        grouped[assignee] = [];
      }
      grouped[assignee]!.add(detail);
    }
    return grouped;
  }

  /// 🚀 FETCH DATA
  Future<void> fetchActionPointView(int meetingId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final req = GetActionPointViewReqModel(meetingId: meetingId);
      final res = await _repository.getActionPointView(req);

      if (res.success == true) {
        _response = res;
        log(res.data.toString());
        // Load status list after successful data fetch
        await loadStatusList();
      } else {
        _error = "Failed to load data";
      }
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  /// 📋 Load Status List from API
  Future<void> loadStatusList() async {
    _isLoadingStatuses = true;
    notifyListeners();

    try {
      final res = await _statusRepository.getAllStatus();
      if (res.success == true && res.statusList != null) {
        _statusList = res.statusList;
        print("✅ Loaded ${_statusList?.length} statuses");
      } else {
        print("❌ Failed to load statuses");
      }
    } catch (e) {
      print("❌ Error loading statuses: $e");
    }

    _isLoadingStatuses = false;
    notifyListeners();
  }

  /// 🏷️ Get Status Label by Value
  String getStatusLabel(String? statusValue) {
    if (statusValue == null) return 'Unknown';
    if (_statusList == null) return statusValue;

    final status = _statusList!.firstWhere(
          (s) => s.value?.toLowerCase() == statusValue.toLowerCase(),
      orElse: () => StatusList(value: statusValue, label: statusValue),
    );
    return status.label ?? statusValue;
  }

  /// 🏷️ Get Status Value by Label
  String? getStatusValue(String? statusLabel) {
    if (statusLabel == null) return null;
    if (_statusList == null) return statusLabel;

    final status = _statusList!.firstWhere(
          (s) => s.label?.toLowerCase() == statusLabel.toLowerCase(),
      orElse: () => StatusList(value: statusLabel, label: statusLabel),
    );
    return status.value ?? statusLabel;
  }

  /// 🎨 Get Status Color
  Color getStatusColor(String? statusValue) {
    switch (statusValue?.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'in_progress':
        return Colors.blue;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
  final DeleteAttachmentsRepository _deleteRepo = DeleteAttachmentsRepository();


  /// 🔄 REFRESH
  Future<void> refresh(int meetingId) async {
    await fetchActionPointView(meetingId);
  }
  bool _isDeleting = false;
  bool get isDeleting => _isDeleting;

  String? _deleteMessage;
  String? get deleteMessage => _deleteMessage;

  Future<bool> deleteAttachment({
    required int meetingId,
    required int attachmentId,
  }) async {
    _isDeleting = true;
    _deleteMessage = null;
    notifyListeners();

    try {
      final res = await _deleteRepo.deleteAttachment(
        DeleteAttachmentsReqModel(
          meetingId: meetingId,
          attachmentId: attachmentId,
        ),
      );

      if (res.success == true) {
        _deleteMessage = res.message ?? "Deleted successfully";

        /// 🔥 OPTION 1: REMOVE LOCALLY (FAST UI)
        _response?.data?.attachments?.removeWhere(
              (a) => a.id == attachmentId.toString(),
        );

        /// 🔥 OPTION 2 (Recommended): REFRESH FROM API
        await fetchActionPointView(meetingId);

        _isDeleting = false;
        notifyListeners();
        return true;
      } else {
        _deleteMessage = res.message ?? "Delete failed";
      }
    } catch (e) {
      _deleteMessage = "Something went wrong: ${e.toString()}";
    }

    _isDeleting = false;
    notifyListeners();
    return false;
  }
  /// 🧹 CLEAR
  void clear() {
    _response = null;
    _error = null;
    _searchQuery = '';
    _selectedStatus = 'all';
    notifyListeners();
  }

  /// 🎯 SET FILTER
  void setStatusFilter(String status) {
    _selectedStatus = status;
    notifyListeners();
  }

  /// 🔍 SET SEARCH QUERY
  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  /// 🧹 CLEAR SEARCH
  void clearSearch() {
    _searchQuery = '';
    notifyListeners();
  }

  /// 🎯 GET DETAILS BY STATUS
  List<Details> getDetailsByStatus(String status) {
    if (status == 'all') return details;
    return details.where((d) => d.status == status).toList();
  }

  /// 🎯 GET DETAILS BY ASSIGNEE
  List<Details> getDetailsByAssignee(String assigneeName) {
    return details.where((d) => d.assignedEmployeeName == assigneeName).toList();
  }

  /// 🎯 GET OVERDUE DETAILS
  List<Details> getOverdueDetails() {
    return details.where((d) {
      if (d.status == 'completed') return false;
      final targetDate = DateTime.tryParse(d.targetDate ?? '');
      return targetDate != null && targetDate.isBefore(DateTime.now());
    }).toList();
  }

  /// 🎯 GET DETAILS BY DATE RANGE
  List<Details> getDetailsByDateRange(DateTime startDate, DateTime endDate) {
    return details.where((d) {
      final targetDate = DateTime.tryParse(d.targetDate ?? '');
      if (targetDate == null) return false;
      return targetDate.isAfter(startDate.subtract(const Duration(days: 1))) &&
          targetDate.isBefore(endDate.add(const Duration(days: 1)));
    }).toList();
  }

  /// 🎯 GET UPCOMING DETAILS (next 7 days)
  List<Details> getUpcomingDetails() {
    final now = DateTime.now();
    final nextWeek = now.add(const Duration(days: 7));
    return details.where((d) {
      if (d.status == 'completed') return false;
      final targetDate = DateTime.tryParse(d.targetDate ?? '');
      if (targetDate == null) return false;
      return targetDate.isAfter(now) && targetDate.isBefore(nextWeek);
    }).toList();
  }

  /// 🎯 CHECK IF DETAIL EXISTS
  bool hasDetails() => details.isNotEmpty;

  /// 🎯 GET DETAIL BY ID
  Details? getDetailById(String id) {
    try {
      return details.firstWhere((d) => d.id == id);
    } catch (e) {
      return null;
    }
  }

  /// 🎯 GET ATTACHMENTS BY ACTION POINT ID
  List<Attachments> getAttachmentsByActionPointId(String actionPointId) {
    return attachments.where((a) => a.actionPointId == actionPointId).toList();
  }

  /// 🎯 GET ATTACHMENT COUNT
  int getAttachmentCount(String actionPointId) {
    return getAttachmentsByActionPointId(actionPointId).length;
  }

  /// ✏️ UPDATE SINGLE ACTION POINT (NEW VERSION)
  Future<bool> updateActionPoint({
    required String actionPointId,
    required String description,
    required String targetDate,
    required String assignedTo,
    required String remark,


    String? status,
  }) async {
    _isUpdating = true;
    _updateMessage = null;
    notifyListeners();

    try {
      final actionPoint = ActionPointItem(
        id: actionPointId,
        description: description,
        targetDate: targetDate,
        assignedTo: assignedTo,
        status: status,
      );

      final model = UpdateGetActionViewReqModel(
        meetingId: int.tryParse(meeting?.id ?? '0'),
        remark: remark,
        meetingDate: meeting?.meetingDate,
        actionPoints: [actionPoint],
        attachments: _attachments,
      );

      final res = await _updateRepository.updateActionPoint(model);

      if (res.status == true) {
        _updateMessage = res.message ?? "Updated successfully";

        /// 🔥 CLEAR LOCAL ATTACHMENTS AFTER SUCCESS
        clearAttachments();

        /// 🔥 SAFE MEETING ID PARSE
        final meetingId = int.tryParse(meeting?.id ?? '0') ?? 0;

        /// 🔥 REFRESH DATA
        if (meetingId != 0) {
          await fetchActionPointView(meetingId);
        }

        _isUpdating = false;
        notifyListeners();
        return true;
      } else {
        _updateMessage = res.message ?? "Update failed";
      }
    } catch (e) {
      _updateMessage = "Something went wrong: ${e.toString()}";
    }

    _isUpdating = false;
    notifyListeners();
    return false;
  }
  Future<bool> updateActionPointStatus({
    required String actionPointId,
    required String newStatus,
    required String remark,
  }) async {
    _isUpdating = true;
    _updateMessage = null;
    notifyListeners();

    try {
      // Get existing action point details
      final existingDetail = getDetailById(actionPointId);
      if (existingDetail == null) {
        _updateMessage = "Action point not found";
        _isUpdating = false;
        notifyListeners();
        return false;
      }

      final actionPoint = ActionPointItem(
        id: actionPointId,
        description: existingDetail.description,
        targetDate: existingDetail.targetDate,
        assignedTo: existingDetail.assignedTo,
        status: newStatus,
      );

      final model = UpdateGetActionViewReqModel(
        meetingId: int.tryParse(meeting?.id ?? '0'),
        remark: remark,
        meetingDate: meeting?.meetingDate,
        actionPoints: [actionPoint],
        attachments: _attachments,
      );

      final res = await _updateRepository.updateActionPoint(model);

      if (res.status == true) {
        _updateMessage = res.message ?? "Status updated successfully";
        final meetingId = int.tryParse(meeting?.id ?? '0') ?? 0;
        if (meetingId != 0) {
          await fetchActionPointView(meetingId);
        }

        _isUpdating = false;
        notifyListeners();
        return true;
      } else {
        _updateMessage = res.message ?? "Update failed";
      }
    } catch (e) {
      _updateMessage = "Something went wrong: ${e.toString()}";
    }

    _isUpdating = false;
    notifyListeners();
    return false;
  }
  // oru data pass akunnilla onnu nokko urgent ahnu
  Future<bool> createNewActionPoint({
    required String description,
    required String targetDate,
    required String assignedTo,
    required String remark,
  }) async {
    _isUpdating = true;
    _updateMessage = null;
    notifyListeners();

    try {
      final actionPoint = ActionPointItem(
        id: null, // No ID for new action point
        description: description,
        targetDate: targetDate,
        assignedTo: assignedTo,
      );

      final model = UpdateGetActionViewReqModel(
        meetingId: int.tryParse(meeting?.id ?? '0'),
        remark: remark,
        meetingDate: meeting?.meetingDate,
        actionPoints: [actionPoint],
        attachments: _attachments,
      );

      final res = await _updateRepository.updateActionPoint(model);

      if (res.status == true) {
        _updateMessage = res.message ?? "Action point created successfully";

        // Clear local attachments after success
        clearAttachments();

        // Refresh data
        final meetingId = int.tryParse(meeting?.id ?? '0') ?? 0;
        if (meetingId != 0) {
          await fetchActionPointView(meetingId);
        }

        _isUpdating = false;
        notifyListeners();
        return true;
      } else {
        _updateMessage = res.message ?? "Creation failed";
      }
    } catch (e) {
      _updateMessage = "Something went wrong: ${e.toString()}";
    }

    _isUpdating = false;
    notifyListeners();
    return false;
  }

  Future<bool> bulkUpdateActionPoints({
    required List<ActionPointItem> actionPoints,
    required String remark,
    List<String>? newAttachmentPaths, // Add this parameter
  }) async {
    _isUpdating = true;
    _updateMessage = null;
    notifyListeners();

    try {
      // Format dates in action points to API format (yyyy-MM-dd)
      final formattedActionPoints = actionPoints.map((point) {
        return ActionPointItem(
          id: point.id,
          description: point.description,
          targetDate: formatDateForApi(point.targetDate ?? ""),
          assignedTo: point.assignedTo,
          status: point.status,
        );
      }).toList();
      final meetingId = int.tryParse(meeting?.id ?? '0');
      if (meetingId == null || meetingId == 0) {
        _updateMessage = "Invalid meeting ID";
        _isUpdating = false;
        notifyListeners();
        return false;
      }
      final List<String> allAttachments = [];

      if (_attachments.isNotEmpty) {
        allAttachments.addAll(_attachments);
      }
      if (newAttachmentPaths != null && newAttachmentPaths.isNotEmpty) {
        allAttachments.addAll(newAttachmentPaths);
        print("Adding ${newAttachmentPaths.length} new attachments");
      }

      print("Total attachments to send: ${allAttachments.length}");

      final model = UpdateGetActionViewReqModel(
        meetingId: meetingId,
        remark: remark,
        meetingDate: meeting?.meetingDate ?? '',
        actionPoints: formattedActionPoints,
        attachments: allAttachments.isNotEmpty ? List<String>.from(allAttachments) : [],
      );
      print("fsfsfs");
      log(model.toJson().toString());
      print("fsfsfs");
      final res = await _updateRepository.updateActionPoint(model);

      if (res.status == true) {
        _updateMessage = res.message ?? "Bulk update successful";

        clearAttachments();
        if (meetingId != 0) {
          await fetchActionPointView(meetingId);
        }

        _isUpdating = false;
        notifyListeners();
        return true;
      } else {
        _updateMessage = res.message ?? "Bulk update failed";
      }
    } catch (e) {
      _updateMessage = "Something went wrong: ${e.toString()}";
      print("Error in bulkUpdateActionPoints: $e");
    }

    _isUpdating = false;
    notifyListeners();
    return false;
  }

// Add this helper method to format dates for API
  String formatDateForApi(String uiDate) {
    if (uiDate.isEmpty) return '';
    try {
      if (RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(uiDate)) {
        return uiDate;
      }
      // Convert from dd/MM/yyyy to yyyy-MM-dd
      if (uiDate.contains('/')) {
        final parts = uiDate.split('/');
        if (parts.length == 3) {
          return '${parts[2]}-${parts[1]}-${parts[0]}';
        }
      }
      return uiDate;
    } catch (e) {
      return uiDate;
    }
  }

// Add this helper method to format dates for display
  String formatDateForDisplay(String? apiDate) {
    if (apiDate == null || apiDate.isEmpty || apiDate == '0000-00-00') return '';
    try {
      // Convert from yyyy-MM-dd to dd/MM/yyyy
      if (apiDate.contains('-')) {
        final parts = apiDate.split('-');
        if (parts.length == 3) {
          return '${parts[2]}/${parts[1]}/${parts[0]}';
        }
      }
      return apiDate;
    } catch (e) {
      return apiDate;
    }
  }

  /// 📝 BULK UPDATE MULTIPLE ACTION POINTS
  // Future<bool> bulkUpdateActionPoints({
  //   required List<ActionPointItem> actionPoints,
  //   required String remark,
  // }) async {
  //   _isUpdating = true;
  //   _updateMessage = null;
  //   notifyListeners();
  //
  //   try {
  //     final model = UpdateGetActionViewReqModel(
  //       meetingId: int.tryParse(meeting?.id ?? '0'),
  //       remark: remark,
  //       meetingDate: meeting?.meetingDate,
  //       actionPoints: actionPoints,
  //       attachments: _attachments,
  //     );
  //
  //     final res = await _updateRepository.updateActionPoint(model);
  //
  //     if (res.status == true) {
  //       _updateMessage = res.message ?? "Bulk update successful";
  //
  //       clearAttachments();
  //
  //       final meetingId = int.tryParse(meeting?.id ?? '0') ?? 0;
  //       if (meetingId != 0) {
  //         await fetchActionPointView(meetingId);
  //       }
  //
  //       _isUpdating = false;
  //       notifyListeners();
  //       return true;
  //     } else {
  //       _updateMessage = res.message ?? "Bulk update failed";
  //     }
  //   } catch (e) {
  //     _updateMessage = "Something went wrong: ${e.toString()}";
  //   }
  //
  //   _isUpdating = false;
  //   notifyListeners();
  //   return false;
  // }
  // nokko
  // old data ahnu pas akunnath
  /// 📎 ADD ATTACHMENT (LOCAL STATE)
  List<String> _attachments = [];
  List<String> get localAttachments => _attachments;

  void addAttachment(String path) {
    _attachments.add(path);
    notifyListeners();
  }

  void removeAttachment(int index) {
    _attachments.removeAt(index);
    notifyListeners();
  }

  void clearAttachments() {
    _attachments.clear();
    notifyListeners();
  }

  /// 📎 GET ATTACHMENT FILE NAME
  String getAttachmentFileName(String path) {
    return path.split('/').last;
  }

  /// 📎 GET ATTACHMENT EXTENSION
  String getAttachmentExtension(String path) {
    final fileName = getAttachmentFileName(path);
    final extension = fileName.split('.').last;
    return extension.toLowerCase();
  }

  /// 📎 CHECK IF ATTACHMENT IS IMAGE
  bool isImageAttachment(String path) {
    const imageExtensions = ['jpg', 'jpeg', 'png', 'gif', 'webp', 'bmp'];
    return imageExtensions.contains(getAttachmentExtension(path));
  }

  /// 📎 CHECK IF ATTACHMENT IS PDF
  bool isPdfAttachment(String path) {
    return getAttachmentExtension(path) == 'pdf';
  }

  /// 📎 CHECK IF ATTACHMENT IS DOCUMENT
  bool isDocumentAttachment(String path) {
    const docExtensions = ['doc', 'docx', 'xls', 'xlsx', 'ppt', 'pptx', 'txt'];
    return docExtensions.contains(getAttachmentExtension(path));
  }

  /// 🎯 EXPORT DETAILS TO CSV (for reporting)
  String exportDetailsToCsv() {
    if (details.isEmpty) return '';

    final buffer = StringBuffer();

    // Header
    buffer.writeln('ID,Description,Status,Assigned To,Target Date,Created On');

    // Data
    for (final detail in details) {
      buffer.writeln(
        '"${detail.id ?? ''}",'
            '"${detail.description?.replaceAll('"', '""') ?? ''}",'
            '"${getStatusLabel(detail.status)}",'
            '"${detail.assignedEmployeeName ?? ''}",'
            '"${detail.targetDate ?? ''}",'
            '"${detail.createdOn ?? ''}"',
      );
    }

    return buffer.toString();
  }

  /// 🎯 GET SUMMARY TEXT
  String getSummaryText() {
    return 'Total: $totalCount | '
        'Completed: $completedCount | '
        'Pending: $pendingCount | '
        'In Progress: $inProgressCount | '
        'Overdue: $overdueCount';
  }

  /// 🎯 VALIDATE ACTION POINT
  bool validateActionPoint(Details detail) {
    if (detail.description?.isEmpty ?? true) return false;
    if (detail.assignedTo?.isEmpty ?? true) return false;
    if (detail.targetDate?.isEmpty ?? true) return false;
    return true;
  }
  List<Details> getInvalidActionPoints() {
    return details.where((d) => !validateActionPoint(d)).toList();
  }

  /// 🎯 SORT DETAILS
  void sortDetailsBy(String field, {bool ascending = true}) {
    if (details.isEmpty) return;

    void sortByDate(List<Details> list, String? Function(Details) getDate, bool ascending) {
      list.sort((a, b) {
        final dateA = DateTime.tryParse(getDate(a) ?? '');
        final dateB = DateTime.tryParse(getDate(b) ?? '');
        if (dateA == null && dateB == null) return 0;
        if (dateA == null) return ascending ? 1 : -1;
        if (dateB == null) return ascending ? -1 : 1;
        return ascending ? dateA.compareTo(dateB) : dateB.compareTo(dateA);
      });
    }

    switch (field) {
      case 'targetDate':
        sortByDate(details, (d) => d.targetDate, ascending);
        break;
      case 'createdOn':
        sortByDate(details, (d) => d.createdOn, ascending);
        break;
      case 'status':
        details.sort((a, b) => ascending
            ? (a.status ?? '').compareTo(b.status ?? '')
            : (b.status ?? '').compareTo(a.status ?? ''));
        break;
      case 'assignedTo':
        details.sort((a, b) => ascending
            ? (a.assignedEmployeeName ?? '').compareTo(b.assignedEmployeeName ?? '')
            : (b.assignedEmployeeName ?? '').compareTo(a.assignedEmployeeName ?? ''));
        break;
    }

    notifyListeners();
  }
  List<DropdownMenuItem<String>> getStatusDropdownItems() {
    if (_statusList == null) return [];

    return _statusList!.map((status) {
      return DropdownMenuItem<String>(
        value: status.value,
        child: Text(status.label ?? status.value ?? ''),
      );
    }).toList();
  }

  List<Map<String, String>> getStatusFilterOptions() {
    final options = <Map<String, String>>[
      {'value': 'all', 'label': 'All'}
    ];

    if (_statusList != null) {
      options.addAll(
          _statusList!.map((status) => {
            'value': status.value ?? '',
            'label': status.label ?? status.value ?? '',
          })
      );
    }

    return options;
  }
}