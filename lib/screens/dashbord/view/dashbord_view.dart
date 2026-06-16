import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import '../../get_action_point_view_screen/view/get_action_view_view.dart';
import '../../get_action_point_view_screen/view/update_action_view.dart';
import '../../get_action_point_view_screen/view_model/get_action_view_view_model.dart';
import '../../login_screen/model/login_model.dart';
import '../../login_screen/view_model/login_screen_view_model.dart';
import '../../meating_action_point_screen/view/meating_action_point_view.dart';
import '../../meating_action_point_screen/view_mode/meating_action_point_view_model.dart';
import '../../meating_screen/model/meating_model.dart';
import '../view_model/dashbord_view_model.dart';

class DashbordView extends StatefulWidget {
  String? meetingTypeId;
  DashbordView({super.key, this.meetingTypeId});

  @override
  State<DashbordView> createState() => _DashbordViewState();
}

class _DashbordViewState extends State<DashbordView> {
  String? meetingTypeId;
  int? selectedRowIndex;
  final RefreshIndicatorKey = GlobalKey<RefreshIndicatorState>();
  bool _isDeleting = false;
  String _deletingId = '';
  bool _isInitialLoading = true;
  bool _isFilterLoading = false;
  late TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
      _initializeMeetingTypes();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _initializeMeetingTypes() async {
    final meetingVm = context.read<MeatingActionPointViewModel>();
    final statusVm = context.read<DashbordViewModel>();

    if (meetingVm.meetingTypes.isEmpty) {
      await meetingVm.fetchMeetingTypes();
    }

    if (meetingVm.statusList.isEmpty) {
      await meetingVm.fetchAllStatus();
    }

    if (meetingVm.selectedMeetingType == null && meetingVm.meetingTypes.isNotEmpty) {
      final allMeetingsType = MeetingType(id: null, name: "All Meetings");
      meetingVm.setSelectedMeetingType(allMeetingsType);
      meetingTypeId = null;
    }
  }

  Future<void> _loadData() async {
    final vm = context.read<DashbordViewModel>();
    final meetingVm = context.read<MeatingActionPointViewModel>();

    await vm.refreshAllData(
      meetingTypeId ?? "",
      vm.statusFilter == 'All Status'
          ? "all"
          : vm.statusFilter.toLowerCase(),
    );
    if (meetingVm.selectedMeetingType == null &&
        meetingVm.meetingTypes.isNotEmpty) {
      final allMeetingsType = MeetingType(id: null, name: "All Meetings");
      meetingVm.setSelectedMeetingType(allMeetingsType);
      meetingTypeId = null;
    }

    if (!mounted) return;

    setState(() {
      _isInitialLoading = false;
    });
  }

  Future<void> _onRefresh() async {
    final vm = context.read<DashbordViewModel>();
    await vm.refreshAllData(
      meetingTypeId ?? "",
      vm.statusFilter == 'All Status' ? "all" : vm.statusFilter.toLowerCase(),
    );
  }

  Future<void> _applyFilters() async {
    setState(() {
      _isFilterLoading = true;
    });

    final vm = context.read<DashbordViewModel>();

    await vm.refreshAllDataWithCurrentFilters(meetingTypeId ?? "");

    if (mounted) {
      setState(() {
        _isFilterLoading = false;
      });
    }
  }

  void _clearAllFilters() {
    final vm = context.read<DashbordViewModel>();
    final meetingVm = context.read<MeatingActionPointViewModel>();
    vm.clearFilters();
    _searchController.clear();
    final allMeetingsType = MeetingType(id: null, name: "All Meetings");
    meetingVm.setSelectedMeetingType(allMeetingsType);

    setState(() {
      meetingTypeId = null;
    });
    _applyFilters();
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<LoginProvider>();
    final vm = context.watch<DashbordViewModel>();
    final meetingVm = context.watch<MeatingActionPointViewModel>();

    final canCreateActionPoints = user.hasCreatePermission();
    final canViewActionPoints = user.hasViewPermission();
    final canEditActionPoints = user.hasUpdatePermission();
    final canDeleteActionPoint = user.hasDeletePermission();

    final paginatedList = vm.paginatedList;
    final totalItems = vm.totalItems;
    final isAnyFilterApplied = vm.searchQuery.isNotEmpty ||
        vm.statusFilter != 'All Status' ||
        (meetingTypeId != null && meetingTypeId!.isNotEmpty);

    if (_isInitialLoading) {
      return Scaffold(
        backgroundColor: Colors.grey.shade50,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(
                color: Colors.blue.shade700,
                strokeWidth: 3,
              ),
              SizedBox(height: 16.h),
              Text(
                'Loading dashboard data...',
                style: TextStyle(
                  fontSize: 14.sp,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: Stack(
        children: [
          CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    SizedBox(height: 20.h),
                    Padding(
                      padding: EdgeInsets.all(16.w),
                      child: Column(
                        children: [
                          SizedBox(height: 20.h),
                          Row(
                            children: [
                              _buildHeader(),
                              const Spacer(),
                              if (canCreateActionPoints)
                                _buildCreateButton(),
                            ],
                          ),
                          SizedBox(height: 10.h),
                          _buildMeetingTypeDropdown(meetingVm),
                          SizedBox(height: 10.h),
                          _buildSearchAndFilterRow(vm, meetingVm),
                          SizedBox(height: 5.h),

                          // Clear All Filters Button
                          if (isAnyFilterApplied) ...[
                            Row(
                              mainAxisAlignment:MainAxisAlignment.end,
                              children: [
                                _buildClearAllFiltersButton(),
                              ],
                            ),
                            SizedBox(height: 5.h),
                          ],

                          // Always show summary section
                          // SizedBox(height: 8.h),
                          _buildSummarySection(vm),
                          SizedBox(height: 24.h),

                          // Show search result info only when filters are applied
                          if (vm.searchQuery.isNotEmpty || vm.statusFilter != 'All Status') ...[
                            _buildSearchResultInfo(vm),
                            SizedBox(height: 16.h),
                          ],

                          _buildSectionHeader(totalItems),
                          SizedBox(height: 10.h),
                        ],
                      ),
                    ),
                    if (_isFilterLoading)
                      Container(
                        height: 200.h,
                        child: Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircularProgressIndicator(
                                color: Colors.blue.shade700,
                                strokeWidth: 2,
                              ),
                              SizedBox(height: 12.h),
                              Text(
                                'Applying filters...',
                                style: TextStyle(
                                  fontSize: 12.sp,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else if (paginatedList.isEmpty)
                      _buildEmptyState(vm, _onRefresh)
                    else
                      Column(
                        children: [
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            padding: EdgeInsets.symmetric(horizontal: 16.w),
                            itemCount: paginatedList.length,
                            itemBuilder: (context, index) {
                              final point = paginatedList[index];
                              final isSelected = selectedRowIndex == index;
                              final isCurrentlyDeleting = _isDeleting && _deletingId == point.id?.toString();

                              Map<String, dynamic> actionPointData = {
                                'id': point.id ?? "",
                                'meeting_id': point.id ?? "",
                                'department': point.meetingTypeName ?? "",
                                'project': point.projectName ?? "",
                                'meetingDate': point.meetingDate ?? "",
                                'createdBy': point.createdByName ?? "",
                                'createdDate': point.createdOn ?? "",
                                'total': point.totalPoints ?? "0",
                                'pending': point.pendingPoints ?? "0",
                                'progress': point.inprogressPoints ?? "0",
                                'completed': point.completedPoints ?? "0",
                                'status': point.overallStatus ?? "",
                              };

                              return _buildActionPointCard(
                                point: point,
                                actionPointData: actionPointData,
                                isSelected: isSelected,
                                index: index,
                                canViewActionPoints: canViewActionPoints,
                                canEditActionPoints: canEditActionPoints,
                                canDeleteActionPoint: canDeleteActionPoint,
                                isDeleting: isCurrentlyDeleting,
                              );
                            },
                          ),
                          if (totalItems > vm.itemsPerPage)
                            _buildPaginationWidget(vm),
                          SizedBox(height: 16.h),
                        ],
                      ),
                  ],
                ),
              ),
            ],
          ),
          if (_isFilterLoading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: Center(
                child: Container(
                  padding: EdgeInsets.all(20.r),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(
                        color: Colors.blue.shade700,
                        strokeWidth: 2,
                      ),
                      SizedBox(height: 12.h),
                      Text(
                        'Loading data...',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCreateButton() {
    return GestureDetector(
      onTap: () {
        final meetingVm = context.read<MeatingActionPointViewModel>();

        // ✅ Reset meeting type to "All Meetings"
        final allMeetingsType = MeetingType(id: null, name: "All Meetings");
        meetingVm.setSelectedMeetingType(allMeetingsType);

        setState(() {
          meetingTypeId = null;
        });

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const MeetingActionPointView(),
          ),
        ).then((_) => _onRefresh());
      },
      child: Container(
        height: 40.w,
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade600, Colors.blue.shade800],
          ),
          borderRadius: BorderRadius.circular(12.r),
          boxShadow: [
            BoxShadow(
              color: Colors.blue.shade200,
              blurRadius: 8.r,
              offset: Offset(0, 2.h),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(Icons.add, size: 18.sp, color: Colors.white),
            SizedBox(width: 8.w),
            Text(
              "Action Point",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 12.sp,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildClearAllFiltersButton() {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: ElevatedButton.icon(
        onPressed: _clearAllFilters,
        icon: Icon(Icons.clear_all, size: 16.sp),
        label: Text(
          'Clear All Filters',
          style: TextStyle(fontSize: 12.sp),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red.shade600,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.r),
          ),
        ),
      ),
    );
  }

  Widget _buildMeetingTypeDropdown(MeatingActionPointViewModel vm) {
    final List<MeetingType> dropdownItems = [
      MeetingType(id: null, name: "All Meetings"),
      ...vm.meetingTypes,
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 5.r,
            offset: Offset(0, 2.h),
          ),
        ],
      ),
      child: DropdownButtonFormField<MeetingType>(
        value: vm.selectedMeetingType ?? dropdownItems.first,
        hint: Padding(
          padding: EdgeInsets.symmetric(horizontal: 12.w),
          child: Row(
            children: [
              Icon(Icons.meeting_room, size: 18.sp, color: Colors.grey.shade500),
              SizedBox(width: 8.w),
              Text(
                "Select Meeting Type",
                style: TextStyle(color: Colors.grey.shade500, fontSize: 13.sp),
              ),
            ],
          ),
        ),
        isExpanded: true,
        items: dropdownItems.map((type) {
          bool isAllOption = type.id == null;
          return DropdownMenuItem(
            value: type,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 12.w),
              child: Row(
                children: [
                  Icon(
                    isAllOption ? Icons.select_all : Icons.meeting_room,
                    size: 18.sp,
                    color: isAllOption ? Colors.black : Colors.blue.shade400,
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Text(
                      type.name ?? "",
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w500,
                        color: isAllOption ? Colors.black : null,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
        onChanged: (value) {
          if (value != null) {
            vm.setSelectedMeetingType(value);
            setState(() {
              meetingTypeId = value.id?.toString();
            });
            _applyFilters(); // Use applyFilters instead of _loadData
          }
        },
        decoration: InputDecoration(
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.r),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.r),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
          prefixIcon: Icon(Icons.arrow_drop_down_circle, color: Colors.blue.shade700, size: 20.sp),
          suffixIcon: meetingTypeId != null && meetingTypeId!.isNotEmpty
              ? IconButton(
            icon: Icon(Icons.clear, size: 16.sp),
            onPressed: () {
              final allMeetingsType = MeetingType(id: null, name: "All Meetings");
              vm.setSelectedMeetingType(allMeetingsType);
              setState(() {
                meetingTypeId = null;
              });
              _applyFilters();
            },
          )
              : null,
        ),
        icon: Icon(Icons.arrow_drop_down, color: Colors.blue.shade700),
        dropdownColor: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
      ),
    );
  }

  Widget _buildSearchAndFilterRow(DashbordViewModel vm, MeatingActionPointViewModel meetingVm) {
    // Sync the controller with the ViewModel's search query
    if (_searchController.text != vm.searchQuery) {
      _searchController.text = vm.searchQuery;
    }

    final isFilterApplied = vm.searchQuery.isNotEmpty || vm.statusFilter != 'All Status';

    return Row(
      children: [
        Expanded(
          child: Container(
            height: 45.h,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12.r),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.shade200,
                  blurRadius: 5.r,
                  offset: Offset(0, 2.h),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                vm.setSearchQuery(value);
                _applyFilters(); // Apply filters with loader
              },
              decoration: InputDecoration(
                hintText: 'Search by ID, Department, Project...',
                hintStyle: TextStyle(fontSize: 12.sp, color: Colors.grey.shade400),
                prefixIcon: Icon(Icons.search, size: 18.sp, color: Colors.blue.shade700),
                suffixIcon: vm.searchQuery.isNotEmpty
                    ? IconButton(
                  icon: Icon(Icons.clear, size: 16.sp),
                  onPressed: () {
                    _searchController.clear();
                    vm.setSearchQuery('');
                    _applyFilters();
                  },
                )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: EdgeInsets.symmetric(vertical: 0, horizontal: 12.w),
              ),
            ),
          ),
        ),
        SizedBox(width: 12.w),

        Container(
          height: 45.h,
          padding: EdgeInsets.symmetric(horizontal: 12.w),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12.r),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.shade200,
                blurRadius: 5.r,
                offset: Offset(0, 2.h),
              ),
            ],
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: vm.statusFilter,
              icon: Icon(Icons.filter_list, size: 18.sp, color: Colors.blue.shade700),
              style: TextStyle(fontSize: 12.sp, color: Colors.grey.shade800),
              items: [
                DropdownMenuItem<String>(
                  value: 'All Status',
                  child: Row(
                    children: [
                      Icon(Icons.filter_list, size: 14.sp, color: Colors.blue),
                      SizedBox(width: 6.w),
                      Text("All Status"),
                    ],
                  ),
                ),
                ...meetingVm.statusList.map((status) {
                  return DropdownMenuItem<String>(
                    value: status.value,
                    child: Row(
                      children: [
                        Icon(
                          _getStatusIcon(status.value),
                          size: 14.sp,
                          color: _getStatusColor(status.value),
                        ),
                        SizedBox(width: 6.w),
                        Text(status.label ?? ''),
                      ],
                    ),
                  );
                }).toList(),
              ],
              onChanged: (String? newValue) async {
                final value = newValue ?? 'All Status';
                vm.setStatusFilter(value);
                _applyFilters(); // Apply filters with loader
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSummarySection(DashbordViewModel vm) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Action Points Summary",
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade800,
          ),
        ),
        SizedBox(height: 3.h),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12.w,
            mainAxisSpacing: 12.h,
            childAspectRatio: 1.5,
          ),
          itemCount: 4,
          itemBuilder: (context, index) {
            final summary = vm.summary;
            final cards = [
              {
                'title': 'Total Points',
                'value': (summary?.total ?? 0).toString(),
                'icon': Icons.task_alt,
                'color': Colors.blue
              },
              {
                'title': 'Pending',
                'value': (summary?.pending ?? 0).toString(),
                'icon': Icons.pending_actions,
                'color': Colors.orange
              },
              {
                'title': 'In Progress',
                'value': (summary?.inprogress ?? 0).toString(),
                'icon': Icons.play_circle_outline,
                'color': Colors.purple
              },
              {
                'title': 'Completed',
                'value': (summary?.completed ?? 0).toString(),
                'icon': Icons.check_circle_outline,
                'color': Colors.green
              },
            ];
            return _buildModernCard(
              cards[index]['title'] as String,
              cards[index]['value'] as String,
              cards[index]['icon'] as IconData,
              cards[index]['color'] as MaterialColor,
            );
          },
        ),
      ],
    );
  }

  Widget _buildSearchResultInfo(DashbordViewModel vm) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 16.w),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(
        children: [
          Icon(Icons.search, size: 16.sp, color: Colors.blue.shade700),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              'Found ${vm.totalItems} result(s) for "${vm.searchQuery.isEmpty ? vm.statusFilter : vm.searchQuery}"',
              style: TextStyle(
                fontSize: 12.sp,
                color: Colors.blue.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          if (vm.searchQuery.isNotEmpty || vm.statusFilter != 'All Status')
            GestureDetector(
              onTap: () {
                _searchController.clear();
                vm.clearFilters();
                _applyFilters();
              },
              child: Container(
                padding: EdgeInsets.all(4.w),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.close, size: 14.sp, color: Colors.blue.shade700),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(int totalItems) {
    return Row(
      children: [
        Container(
          width: 4.w,
          height: 24.h,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue.shade400, Colors.blue.shade700],
            ),
            borderRadius: BorderRadius.circular(2.r),
          ),
        ),
        SizedBox(width: 8.w),
        Text(
          "Meeting Action Points",
          style: TextStyle(
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
            color: Colors.grey.shade800,
          ),
        ),
        const Spacer(),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue.shade50, Colors.blue.shade100],
            ),
            borderRadius: BorderRadius.circular(20.r),
          ),
          child: Row(
            children: [
              Icon(Icons.list_alt, size: 14.sp, color: Colors.blue.shade700),
              SizedBox(width: 4.w),
              Text(
                '$totalItems Records',
                style: TextStyle(
                  fontSize: 12.sp,
                  color: Colors.blue.shade700,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(DashbordViewModel vm, VoidCallback onRefresh) {
    return Container(
      height: 400.h,
      margin: EdgeInsets.symmetric(horizontal: 16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 10.r,
            offset: Offset(0, 5.h),
          ),
        ],
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inbox,
              size: 80.w,
              color: Colors.grey.shade400,
            ),
            SizedBox(height: 16.h),
            Text(
              'No Data Found',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              vm.searchQuery.isNotEmpty || vm.statusFilter != 'All Status'
                  ? 'No results match your search criteria'
                  : 'Pull down to refresh or add new action points',
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.grey.shade500,
              ),
            ),
            if (vm.searchQuery.isNotEmpty || vm.statusFilter != 'All Status')
              SizedBox(height: 16.h),
            if (vm.searchQuery.isNotEmpty || vm.statusFilter != 'All Status')
              ElevatedButton.icon(
                onPressed: () {
                  _searchController.clear();
                  vm.clearFilters();
                  _applyFilters();
                },
                icon: Icon(Icons.clear),
                label: Text('Clear Filters'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade700,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                ),
              )
            else
              SizedBox(height: 16.h),
            if (vm.searchQuery.isEmpty && vm.statusFilter == 'All Status')
              ElevatedButton.icon(
                onPressed: onRefresh,
                icon: Icon(Icons.refresh),
                label: Text('Refresh'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade700,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionPointCard({
    required dynamic point,
    required actionPointData,
    required bool isSelected,
    required int index,
    required bool canViewActionPoints,
    required bool canEditActionPoints,
    required bool canDeleteActionPoint,
    required bool isDeleting,
  }) {
    final bool isMeetingType = point.meetingTypeName != null && point.meetingTypeName!.isNotEmpty;

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: BoxDecoration(
        color: isSelected ? Colors.blue.shade50 : Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 8.r,
            offset: Offset(0, 3.h),
          ),
        ],
        border: Border.all(
          color: isSelected ? Colors.blue.shade300 : Colors.grey.shade200,
          width: 1.5,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            setState(() {
              selectedRowIndex = index;
            });
          },
          borderRadius: BorderRadius.circular(20.r),
          child: Padding(
            padding: EdgeInsets.only(left: 12.w, right: 12.w, top: 12.h, bottom: 12.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 12.w),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.blue.shade50, Colors.blue.shade100],
                    ),
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Text(
                    point.meetingTypeName ?? "Meeting Type",
                    style: TextStyle(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade900,
                    ),
                  ),
                ),
                SizedBox(height: 12.h),
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.blue.shade50, Colors.blue.shade100],
                        ),
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                      child: Text(
                        "AP${point.id ?? ""}",
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 12.sp,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ),
                    SizedBox(width: 10.w),
                    _buildStatusChip(point.overallStatus ?? ""),
                    const Spacer(),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (canViewActionPoints && !isDeleting)
                          _buildActionButton(
                            icon: Icons.visibility,
                            color: Colors.blue,
                            onTap: () async {
                              print("ofofof");
                              print(actionPointData['meeting_id']?.toString());
                              setState(() {
                                selectedRowIndex = index;
                              });
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ActionPointViewScreen(
                                    meetingId: int.tryParse(
                                      actionPointData['meeting_id']?.toString() ?? '0',
                                    ) ?? 0,
                                  ),
                                ),
                              );
                              _onRefresh();
                            },
                          ),
                        if (canEditActionPoints && !isDeleting)
                          _buildActionButton(
                            icon: Icons.edit,
                            color: Colors.orange,
                            onTap: () async {
                              setState(() {
                                selectedRowIndex = index;
                              });
                              final meetingId = int.tryParse(
                                actionPointData['meeting_id']?.toString() ?? '0',
                              ) ?? 0;
                              final viewModel = context.read<GetActionPointViewModel>();

                              showDialog(
                                context: context,
                                barrierDismissible: false,
                                builder: (context) => Center(
                                  child: Container(
                                    padding: EdgeInsets.all(20.r),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(20.r),
                                    ),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        CircularProgressIndicator(color: Colors.blue.shade700),
                                        SizedBox(height: 12.h),
                                        Text(
                                          'Loading...',
                                          style: TextStyle(fontSize: 14.sp),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );

                              await viewModel.fetchActionPointView(meetingId);

                              if (mounted) Navigator.pop(context);

                              if (!context.mounted) return;
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => ActionPointFormScreen(
                                    viewModel: viewModel,
                                    meetingId: meetingId,
                                  ),
                                ),
                              );
                              _onRefresh();
                            },
                          ),
                        if (canDeleteActionPoint)
                          if (isDeleting)
                            Container(
                              margin: EdgeInsets.only(left: 8.w),
                              padding: EdgeInsets.all(8.w),
                              child: SizedBox(
                                width: 18.sp,
                                height: 18.sp,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.red,
                                ),
                              ),
                            )
                          else
                            _buildActionButton(
                              icon: Icons.delete,
                              color: Colors.red,
                              onTap: () {
                                setState(() {
                                  selectedRowIndex = index;
                                });
                                _deleteActionPoint(actionPointData, index);
                              },
                            ),
                      ],
                    ),
                  ],
                ),
                SizedBox(height: 16.h),
                Divider(height: 1, color: Colors.grey.shade200),
                SizedBox(height: 12.h),
                if (isMeetingType && point.projectName != null && point.projectName!.isNotEmpty) ...[
                  Container(

                    padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                    decoration: BoxDecoration(
                      // color: Colors.purple.shade50,
                      borderRadius: BorderRadius.circular(10.r),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.folder_special,
                          size: 18.sp,
                          color: Colors.purple.shade700,
                        ),
                        SizedBox(width: 8.w),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Project",
                                style: TextStyle(
                                  fontSize: 10.sp,
                                  color: Colors.purple.shade600,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                point.projectName ?? "",
                                style: TextStyle(
                                  fontSize: 14.sp,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.purple.shade900,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 6.h),
                ],


                // Info chips - Excluding project name since it's shown separately above
                Wrap(
                  spacing: 8.w,
                  runSpacing: 8.h,
                  children: [
                    // Only show these info chips, project name removed from here
                    _buildInfoChip(
                      name: 'Meeting Date',
                      icon: Icons.event_outlined,
                      label: point.meetingDate ?? "",
                    ),
                    _buildInfoChip(
                      name: 'Created by',
                      icon: Icons.person_outline,
                      label: point.createdByName ?? "",
                    ),
                    _buildInfoChip(
                      name: 'Create Date',
                      icon: Icons.calendar_today_outlined,
                      label: point.createdOn ?? "",
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required String name,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            name,
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 4.h),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 14.sp,
                color: Colors.blue.shade600,
              ),
              SizedBox(width: 6.w),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11.sp,
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(left: 8.w),
        padding: EdgeInsets.all(8.w),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10.r),
        ),
        child: Icon(
          icon,
          size: 18.sp,
          color: color,
        ),
      ),
    );
  }

  // Pagination Widgets
  Widget _buildPaginationWidget(DashbordViewModel vm) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 16.h, horizontal: 16.w),
      padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 5.r,
            offset: Offset(0, -2.h),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                vm.getDisplayRange(),
                style: TextStyle(
                  fontSize: 12.sp,
                  color: Colors.grey.shade600,
                ),
              ),
              _buildItemsPerPageDropdown(vm),
            ],
          ),
          SizedBox(height: 12.h),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildPaginationButton(
                  icon: Icons.chevron_left,
                  onTap: vm.hasPreviousPage ? () => vm.previousPage() : null,
                  isEnabled: vm.hasPreviousPage,
                ),
                SizedBox(width: 4.w),
                _buildPageNumbers(vm),
                SizedBox(width: 4.w),
                _buildPaginationButton(
                  icon: Icons.chevron_right,
                  onTap: vm.hasNextPage ? () => vm.nextPage() : null,
                  isEnabled: vm.hasNextPage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPageNumbers(DashbordViewModel vm) {
    List<int> pagesToShow = _getPagesToShow(vm.currentPage, vm.totalPages);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: pagesToShow.map((page) {
        if (page == -1) {
          return Padding(
            padding: EdgeInsets.symmetric(horizontal: 2.w),
            child: Text(
              '...',
              style: TextStyle(
                fontSize: 12.sp,
                color: Colors.grey.shade600,
              ),
            ),
          );
        }

        final isSelected = page == vm.currentPage;

        return GestureDetector(
          onTap: vm.isTableLoading ? null : () => vm.setPage(page),
          child: Container(
            margin: EdgeInsets.symmetric(horizontal: 2.w),
            width: 32.w,
            height: 32.w,
            decoration: BoxDecoration(
              color: isSelected ? Colors.blue.shade700 : Colors.transparent,
              borderRadius: BorderRadius.circular(8.r),
              border: isSelected
                  ? null
                  : Border.all(color: Colors.grey.shade300),
            ),
            child: Center(
              child: Text(
                page.toString(),
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? Colors.white : Colors.grey.shade700,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  List<int> _getPagesToShow(int currentPage, int totalPages) {
    List<int> pages = [];

    if (totalPages <= 5) {
      for (int i = 1; i <= totalPages; i++) {
        pages.add(i);
      }
    } else {
      pages.add(1);

      if (currentPage > 3) {
        pages.add(-1);
      }

      int start = currentPage - 1;
      int end = currentPage + 1;

      if (start <= 2) start = 2;
      if (end >= totalPages - 1) end = totalPages - 1;

      for (int i = start; i <= end; i++) {
        if (i > 1 && i < totalPages) {
          pages.add(i);
        }
      }

      if (currentPage < totalPages - 2) {
        pages.add(-1);
      }

      pages.add(totalPages);
    }

    return pages;
  }

  Widget _buildPaginationButton({
    required IconData icon,
    required VoidCallback? onTap,
    required bool isEnabled,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(6.w),
        decoration: BoxDecoration(
          color: isEnabled ? Colors.blue.shade50 : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(6.r),
          border: Border.all(
            color: isEnabled ? Colors.blue.shade200 : Colors.grey.shade300,
          ),
        ),
        child: Icon(
          icon,
          size: 18.sp,
          color: isEnabled ? Colors.blue.shade700 : Colors.grey.shade400,
        ),
      ),
    );
  }

  Widget _buildItemsPerPageDropdown(DashbordViewModel vm) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6.w),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(6.r),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: vm.itemsPerPage,
          icon: Icon(Icons.arrow_drop_down, size: 16.sp),
          style: TextStyle(fontSize: 11.sp, color: Colors.grey.shade700),
          items: const [
            DropdownMenuItem(value: 10, child: Text('10')),
            DropdownMenuItem(value: 25, child: Text('25')),
            DropdownMenuItem(value: 50, child: Text('50')),
            DropdownMenuItem(value: 100, child: Text('100')),
          ],
          onChanged: (value) {
            if (value != null) {
              vm.setItemsPerPage(value);
            }
          },
        ),
      ),
    );
  }

  IconData _getStatusIcon(String? status) {
    switch (status?.toLowerCase()) {
      case 'pending':
        return Icons.pending;
      case 'in_progress':
        return Icons.play_circle_outline;
      case 'completed':
        return Icons.check_circle_outline;
      default:
        return Icons.help_outline;
    }
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'in_progress':
        return Colors.blue;
      case 'completed':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(10.w),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue.shade400, Colors.blue.shade700],
            ),
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Icon(Icons.dashboard, color: Colors.white, size: 24.sp),
        ),
        SizedBox(width: 12.w),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Dashboard",
              style: TextStyle(
                fontSize: 24.sp,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildModernCard(String title, String value, IconData icon, MaterialColor color) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color.shade400, color.shade700],
        ),
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 10.r,
            offset: Offset(0, 4.h),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8.w),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Icon(icon, color: Colors.white, size: 24.sp),
                ),
                SizedBox(width: 6.w),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 32.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.h),
            Text(
              title,
              style: TextStyle(
                fontSize: 11.sp,
                color: Colors.white.withOpacity(0.9),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color color;
    IconData icon;

    switch (status.toLowerCase()) {
      case 'pending':
        color = Colors.orange;
        icon = Icons.pending;
        break;
      case 'in progress':
        color = Colors.blue;
        icon = Icons.play_circle_outline;
        break;
      case 'completed':
        color = Colors.green;
        icon = Icons.check_circle_outline;
        break;
      default:
        color = Colors.grey;
        icon = Icons.help_outline;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
        ),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14.sp, color: color),
          SizedBox(width: 6.w),
          Text(
            status.toUpperCase(),
            style: TextStyle(
              fontSize: 10.sp,
              fontWeight: FontWeight.w700,
              color: color,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  void _deleteActionPoint(Map<String, dynamic> actionPointData, int index) async {
    final vm = context.read<DashbordViewModel>();
    final meetingId = actionPointData['id']?.toString() ?? '';

    final shouldDelete = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20.r)),
          title: Row(
            children: [
              Icon(Icons.warning_amber_rounded,
                  color: Colors.red, size: 28.sp),
              SizedBox(width: 10.w),
              Text("Delete Action Point",
                  style: TextStyle(fontSize: 14.sp)),
            ],
          ),
          content: Text(
            "Are you sure you want to delete $meetingId? This action cannot be undone.",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text("Cancel",
                  style: TextStyle(color: Colors.grey.shade600)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.r)),
              ),
              onPressed: () => Navigator.pop(context, true),
              child: const Text("Delete"),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true) return;

    if (mounted) {
      setState(() {
        _isDeleting = true;
        _deletingId = meetingId;
      });
    }

    await vm.deleteActionPoint(meetingId);

    if (mounted) {
      setState(() {
        _isDeleting = false;
        _deletingId = '';
      });
    }

    if (mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  vm.isDeleteSuccess
                      ? Icons.check_circle
                      : Icons.error,
                  color: Colors.white,
                  size: 20.sp,
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Text(
                    vm.deleteMessage ?? "Delete operation completed",
                  ),
                ),
              ],
            ),
            backgroundColor:
            vm.isDeleteSuccess ? Colors.green : Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.r),
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      });
    }

    if (mounted) {
      _onRefresh();
    }
  }
}