import 'package:flutter/cupertino.dart';

import '../../get_action_point_view_screen/model/get_all_status_model.dart';
import '../../get_action_point_view_screen/repository/get_all_status_repo.dart';
import '../model/action_point_summary_point_model.dart';
import '../model/delete_action_point_model.dart';
import '../model/get_action_point_model.dart';
import '../repository/action_summary_point_repo.dart';
import '../repository/delete_action_point_repo.dart';
import '../repository/get_action_point_repo.dart';

class DashbordViewModel extends ChangeNotifier {
  /// ================= REPOS =================
  final GetAllStatusRepository _statusRepo = GetAllStatusRepository();
  final ActionPointSummaryRepository _repository = ActionPointSummaryRepository();
  final DeleteActionPointRepository _deleteRepo = DeleteActionPointRepository();
  final GetActionPointRepository _actionRepo = GetActionPointRepository();

  /// ================= STATUS =================
  List<StatusList> _statusList = [];
  List<StatusList> get statusList => _statusList;

  bool _isStatusLoading = false;
  bool get isStatusLoading => _isStatusLoading;

  /// ================= SUMMARY =================
  ActionSummary? _summary;
  bool _isLoading = false;
  String? _error;

  ActionSummary? get summary => _summary;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// ================= FULL DATA =================
  List<ActionPoint> _allActionPoints = [];

  /// ================= FILTERED + PAGINATED =================
  List<ActionPoint> _actionPoints = [];
  List<ActionPoint> get actionPoints => _actionPoints;

  /// Paginated list for UI display
  List<ActionPoint> get paginatedList => _actionPoints;

  bool _isTableLoading = false;
  String? _tableError;

  bool get isTableLoading => _isTableLoading;
  String? get tableError => _tableError;

  /// ================= PAGINATION =================
  int _currentPage = 1;
  int _itemsPerPage = 10;
  int _totalPages = 1;
  int _totalItems = 0;

  int get currentPage => _currentPage;
  int get itemsPerPage => _itemsPerPage;
  int get totalPages => _totalPages;
  int get totalItems => _totalItems;

  bool get hasNextPage => _currentPage < _totalPages;
  bool get hasPreviousPage => _currentPage > 1;

  /// ================= FILTER STATE =================
  String _searchQuery = "";
  String _statusFilter = "All Status";

  String get searchQuery => _searchQuery;
  String get statusFilter => _statusFilter;

  /// ================= DELETE =================
  bool _isDeleting = false;
  String? _deleteMessage;
  bool _isDeleteSuccess = false;

  bool get isDeleting => _isDeleting;
  String? get deleteMessage => _deleteMessage;
  bool get isDeleteSuccess => _isDeleteSuccess;
  bool _isLoadingData = false;
  Future<void> fetchSummary({
    required String meetingTypeId,
    String status = "all",
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await _repository.getSummary(
        ActionPointSummaryPointsReqModel(
          status: status,
          meetingTypeId: meetingTypeId,
        ),
      );

      if (result.success == true && result.actionSummary != null) {
        _summary = result.actionSummary;
      } else {
        _summary = null;
        _error = "Failed to load summary";
      }
    } catch (e) {
      _summary = null;
      _error = "Something went wrong";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  Future<void> fetchActionPoints({
    required String meetingTypeId,
    String status = "all",
  }) async {
    _isTableLoading = true;
    _tableError = null;
    notifyListeners();

    try {
      final res = await _actionRepo.getActionPoints(
        GetActionPointReqModel(
          status: status,
          meetingTypeId: meetingTypeId,
        ),
      );

      if (res.success == true && res.actionPoint != null) {
        _allActionPoints = res.actionPoint!;

        /// Reset to first page when loading new data
        _currentPage = 1;

        /// Apply filters + pagination
        _applyFiltersAndPagination();
      } else {
        _allActionPoints = [];
        _actionPoints = [];
        _totalItems = 0;
        _totalPages = 1;
        _tableError = "No data found";
      }
    } catch (e) {
      _allActionPoints = [];
      _actionPoints = [];
      _totalItems = 0;
      _totalPages = 1;
      _tableError = "Something went wrong";
    } finally {
      _isTableLoading = false;
      notifyListeners();
    }
  }

  /// =========================================================
  /// 🔥 FILTER + PAGINATION LOGIC (PRIVATE)
  /// ======================================================
  /// Refresh both action points and summary with current filters
  Future<void> refreshAllDataWithCurrentFilters(String meetingTypeId) async {
    String statusValue = _statusFilter == 'All Status' ? "all" : _statusFilter.toLowerCase();

    await Future.wait([
      fetchActionPoints(
        meetingTypeId: meetingTypeId,
        status: statusValue,
      ),
      fetchSummary(
        meetingTypeId: meetingTypeId,
        status: statusValue,
      ),
    ]);
  }
  void _applyFiltersAndPagination() {
    List<ActionPoint> tempList = List.from(_allActionPoints);

    /// 🔍 SEARCH
    if (_searchQuery.isNotEmpty) {
      tempList = tempList.where((point) {
        return (point.id?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false) ||
            (point.projectName?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false) ||
            (point.meetingTypeName?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false) ||
            (point.createdByName?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);
      }).toList();
    }

    /// 🎯 STATUS
    if (_statusFilter != "All Status") {
      tempList = tempList.where((point) {
        return (point.overallStatus ?? "")
            .toLowerCase()
            .replaceAll(" ", "_") ==
            _statusFilter.toLowerCase().replaceAll(" ", "_");
      }).toList();
    }
    // if (_statusFilter != "All Status") {
    //   tempList = tempList.where((point) {
    //     return point.overallStatus?.toLowerCase() ==
    //         _statusFilter.toLowerCase();
    //   }).toList();
    // }

    /// 🔢 PAGINATION
    _totalItems = tempList.length;
    _totalPages = _totalItems > 0
        ? (_totalItems / _itemsPerPage).ceil()
        : 1;

    /// Ensure current page is valid
    if (_currentPage < 1) _currentPage = 1;
    if (_currentPage > _totalPages && _totalPages > 0) _currentPage = _totalPages;

    /// Calculate pagination indices
    int start = (_currentPage - 1) * _itemsPerPage;
    int end = start + _itemsPerPage;

    /// Apply pagination
    if (start < tempList.length) {
      _actionPoints = tempList.sublist(
        start,
        end > tempList.length ? tempList.length : end,
      );
    } else {
      _actionPoints = [];
    }

    notifyListeners();
  }
  void setSearchQuery(String query) {
    _searchQuery = query;
    _currentPage = 1;
    _applyFiltersAndPagination();
  }
  void setStatusFilter(String status) {
    _statusFilter = status;
    _currentPage = 1;
    _applyFiltersAndPagination();
  }

  void clearFilters() {
    _searchQuery = "";
    _statusFilter = "All Status";
    _currentPage = 1;
    _applyFiltersAndPagination();
  }

  /// =========================================================
  /// 🔥 PAGINATION CONTROLS
  /// =========================================================

  /// Go to specific page
  void setPage(int page) {
    if (page < 1 || page > _totalPages) return;
    if (page == _currentPage) return;

    _currentPage = page;
    _applyFiltersAndPagination();
  }

  /// Go to next page
  void nextPage() {
    if (hasNextPage) {
      _currentPage++;
      _applyFiltersAndPagination();
    }
  }

  /// Go to previous page
  void previousPage() {
    if (hasPreviousPage) {
      _currentPage--;
      _applyFiltersAndPagination();
    }
  }

  /// Go to first page
  void firstPage() {
    if (_currentPage != 1) {
      _currentPage = 1;
      _applyFiltersAndPagination();
    }
  }

  /// Go to last page
  void lastPage() {
    if (_currentPage != _totalPages && _totalPages > 0) {
      _currentPage = _totalPages;
      _applyFiltersAndPagination();
    }
  }

  /// Change items per page
  void setItemsPerPage(int items) {
    if (_itemsPerPage == items) return;

    _itemsPerPage = items;
    _currentPage = 1; // Reset to first page when changing items per page
    _applyFiltersAndPagination();
  }

  /// =========================================================
  /// 🔥 DELETE ACTION POINT
  /// =========================================================
  Future<void> deleteActionPoint(String meetingId) async {
    _isDeleting = true;
    _deleteMessage = null;
    _isDeleteSuccess = false;
    notifyListeners();

    try {
      final response = await _deleteRepo.deleteActionPoint(
        DeleteActionPointReqModel(meetingId: meetingId),
      );

      if (response.success == true) {
        _isDeleteSuccess = true;
        _deleteMessage = response.message ?? "Deleted successfully";

        /// ✅ Remove item locally (instant UI update)
        _allActionPoints.removeWhere((e) => e.id == meetingId);

        /// ✅ Re-apply filters + pagination
        _applyFiltersAndPagination();
      } else {
        _isDeleteSuccess = false;
        _deleteMessage = response.message ?? "Delete failed";
      }
    } catch (e) {
      _isDeleteSuccess = false;
      _deleteMessage = "Something went wrong";
    }

    _isDeleting = false;
    notifyListeners();
  }

  /// =========================================================
  /// 🔥 STATUS LIST
  /// =========================================================
  Future<void> loadStatusList() async {
    // Prevent duplicate calls
    if (_isStatusLoading) return;

    _isStatusLoading = true;
    notifyListeners();

    try {
      final res = await _statusRepo.getAllStatus();
      if (res.success == true && res.statusList != null) {
        _statusList = res.statusList!;
      }
    } catch (e) {
      print("Status error: $e");
    } finally {
      _isStatusLoading = false;
      notifyListeners();
    }
  }

  /// =========================================================
  Future<void> refreshAllData(String meetingTypeId, String status) async {
    if (_isLoadingData) return;

    _isLoadingData = true;

    _isLoading = true;
    _isTableLoading = true;
    _isStatusLoading = true;
    notifyListeners();

    _currentPage = 1;
    _searchQuery = "";
    // DON'T reset status filter here - keep the current filter
    // _statusFilter = "All Status"; // REMOVED THIS

    try {
      await Future.wait([
        fetchSummary(meetingTypeId: meetingTypeId, status: status),
        fetchActionPoints(meetingTypeId: meetingTypeId, status: status),
        loadStatusList(),
      ]);
    } catch (e) {
      print("❌ ERROR: $e");
    }

    _isLoadingData = false;
    _isLoading = false;
    _isTableLoading = false;
    _isStatusLoading = false;

    notifyListeners();
  }

  Future<void> refreshSummary(String meetingTypeId) async {
    await fetchSummary(meetingTypeId: meetingTypeId);
  }
  /// Update summary based on current filters
  Future<void> updateSummaryWithCurrentFilters(String meetingTypeId) async {
    String statusValue = _statusFilter == 'All Status' ? "all" : _statusFilter.toLowerCase();
    await fetchSummary(
      meetingTypeId: meetingTypeId,
      status: statusValue,
    );
  }
  void clearSummary() {
    _summary = null;
    notifyListeners();
  }

  /// =========================================================
  /// 🔥 UTILITY GETTERS
  /// =========================================================

  /// Get current range of items being displayed
  String getDisplayRange() {
    if (_totalItems == 0) return "0 of 0";

    int start = (_currentPage - 1) * _itemsPerPage + 1;
    int end = start + _actionPoints.length - 1;

    return "$start-$end of $_totalItems";
  }
}