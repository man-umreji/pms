import 'package:flutter/material.dart';
import 'package:pms/screens/get_action_point_view_screen/view/update_action_view.dart';
import 'package:provider/provider.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:open_file/open_file.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:intl/intl.dart';
import '../../main_screen/view/main_screen_view.dart';
import '../model/get_action_point_model.dart';
import '../model/get_all_status_model.dart';
import '../model/update_action_point_model.dart';
import '../view_model/get_action_view_view_model.dart';
import '../../../network/end_point.dart';

class ActionPointViewScreen extends StatefulWidget {
  final int meetingId;

  const ActionPointViewScreen({
    super.key,
    required this.meetingId,
  });

  @override
  State<ActionPointViewScreen> createState() => _ActionPointViewScreenState();
}

class _ActionPointViewScreenState extends State<ActionPointViewScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      Provider.of<GetActionPointViewModel>(context, listen: false)
          .fetchActionPointView(widget.meetingId);
    });
  }

  void _navigateToUpdateScreen() {
    final vm = Provider.of<GetActionPointViewModel>(context, listen: false);

    if (vm.details.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'No action points to update',
            style: TextStyle(fontSize: 13.sp),
          ),
          backgroundColor: Colors.orange.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.r),
          ),
        ),
      );
      return;
    }
    print("ofofof");
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ActionPointFormScreen(
          viewModel: vm,
          meetingId: widget.meetingId,
        ),
      ),
    ).then((result) {
      if (result == true) {
        vm.refresh(widget.meetingId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(
          "Action Points",
          style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold),
        ),
        actions: [
          Padding(
            padding: EdgeInsets.only(right: 12.w),
            child: GestureDetector(
              onTap: _navigateToUpdateScreen,
              child: Container(
                height: 40.w,
                width: 120.w,
                decoration: BoxDecoration(
                  color: Colors.blue[700],
                  borderRadius: BorderRadius.circular(6.w),
                ),
                child: Center(
                  child: Text(
                    "Update Action point",
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 12.sp
                    ),
                  ),
                ),
              ),
            ),
          )
        ],
        elevation: 0,
        centerTitle: false,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.grey.shade800,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.grey.shade100,
                blurRadius: 10,
                offset: Offset(0, 2),
              ),
            ],
          ),
        ),
      ),
      body: Consumer<GetActionPointViewModel>(
        builder: (context, vm, child) {
          if (vm.isLoading) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 40.w,
                    height: 40.h,
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      color: Colors.blue.shade600,
                    ),
                  ),
                  SizedBox(height: 16.h),
                  Text(
                    "Loading action points...",
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ],
              ),
            );
          }

          if (vm.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64.sp, color: Colors.grey.shade400),
                  SizedBox(height: 16.h),
                  Text(
                    vm.error!,
                    style: TextStyle(color: Colors.grey.shade600),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 16.h),
                  ElevatedButton.icon(
                    onPressed: () => vm.refresh(widget.meetingId),
                    icon: Icon(Icons.refresh),
                    label: Text("Retry"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade600,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          if (vm.details.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inbox_outlined, size: 80.sp, color: Colors.grey.shade400),
                  SizedBox(height: 16.h),
                  Text(
                    "No Action Points Found",
                    style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w600, color: Colors.grey.shade600),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    "Tap the + button to create one",
                    style: TextStyle(fontSize: 14.sp, color: Colors.grey.shade500),
                  ),
                  SizedBox(height: 24.h),
                  ElevatedButton.icon(
                    onPressed: () => vm.refresh(widget.meetingId),
                    icon: Icon(Icons.refresh),
                    label: Text("Refresh"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade600,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => vm.refresh(widget.meetingId),
            color: Colors.blue.shade600,
            child: CustomScrollView(
              slivers: [
                SliverToBoxAdapter(child: _buildMeetingHeader(vm)),
                SliverPadding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                  sliver: SliverToBoxAdapter(
                    child: _buildSectionHeader(vm.details.length),
                  ),
                ),
                SliverPadding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                          (context, index) => _buildActionPointCard(vm.details[index], vm),
                      childCount: vm.details.length,
                    ),
                  ),
                ),
                if (vm.remarks.isNotEmpty)
                  SliverToBoxAdapter(child: _buildRemarkHistorySection(vm)),
                if (vm.attachments.isNotEmpty)
                  SliverToBoxAdapter(child: _buildAttachmentsSectionList(vm)),
                SliverToBoxAdapter(child: SizedBox(height: 32.h)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildRemarkHistorySection(GetActionPointViewModel vm) {
    final remarks = vm.remarks;
    final meeting = vm.meeting;
    if (meeting == null) return SizedBox.shrink();

    if (remarks.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade100,
            blurRadius: 10.r,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(16.w),
            child: Row(
              children: [
                Icon(Icons.history, color: Colors.blue.shade600, size: 22.sp),
                SizedBox(width: 8.w),
                Text(
                  "Remark History",
                  style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade800
                  ),
                ),
                const Spacer(),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                  child: Text(
                    "${remarks.length}",
                    style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.blue.shade600
                    ),
                  ),
                ),
              ],
            ),
          ),
          Divider(color: Colors.grey.shade100, height: 0),
          ListView.separated(
            itemCount: remarks.length,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            separatorBuilder: (context, index) => Divider(color: Colors.grey.shade100, height: 0),
            itemBuilder: (context, index) {
              final remark = remarks[index];
              return Container(
                padding: EdgeInsets.all(16.w),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 40.w,
                      height: 40.w,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.blue.shade400, Colors.blue.shade700],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: const Center(
                        child: Icon(Icons.edit_note_outlined, color: Colors.white),
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            remark.remark ?? '',
                            style: TextStyle(
                              fontSize: 14.sp,
                              color: Colors.grey.shade800,
                              height: 1.4,
                            ),
                          ),
                          SizedBox(height: 10.h),
                          // Fixed alignment for metadata section
                          Wrap(
                            spacing: 8.w,
                            runSpacing: 8.h,
                            children: [
                              // Created by chip
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade50,
                                  borderRadius: BorderRadius.circular(12.r),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.person_outline,
                                      size: 12.sp,
                                      color: Colors.blue.shade600,
                                    ),
                                    SizedBox(width: 4.w),
                                    Text(
                                      'Created By: ${remark.createdByName?.isNotEmpty == true
                                          ? remark.createdByName
                                          : remark.createdBy ?? "Unknown"}',
                                      style: TextStyle(
                                        fontSize: 11.sp,
                                        color: Colors.blue.shade700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Timestamp chip
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(12.r),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.access_time,
                                      size: 12.sp,
                                      color: Colors.grey.shade600,
                                    ),
                                    SizedBox(width: 4.w),
                                    Text(
                                      _formatRemarkDate(remark.createdOn ?? ""),
                                      style: TextStyle(
                                        fontSize: 11.sp,
                                        color: Colors.grey.shade700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  String getUserName(Remark remark) {
    if (remark.createdByName != null &&
        remark.createdByName!.trim().isNotEmpty) {
      return remark.createdByName!;
    }

    return "User ID: ${remark.createdBy}";
  }

  String _formatRemarkDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) {
      return "Unknown date";
    }

    try {
      DateTime? parsedDate;

      if (dateString.contains('T')) {
        parsedDate = DateTime.tryParse(dateString);
      } else if (dateString.contains('-') && dateString.contains(':')) {
        parsedDate = DateTime.tryParse(dateString.replaceAll(' ', 'T'));
      } else if (dateString.contains('-')) {
        parsedDate = DateTime.tryParse(dateString);
      } else if (dateString.contains('/')) {
        final parts = dateString.split('/');
        if (parts.length == 3) {
          parsedDate = DateTime.tryParse('${parts[2]}-${parts[1]}-${parts[0]}');
        }
      }

      if (parsedDate != null && parsedDate.year > 1900) {
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final yesterday = today.subtract(Duration(days: 1));
        final remarkDate = DateTime(parsedDate.year, parsedDate.month, parsedDate.day);

        if (remarkDate == today) {
          return "Today at ${parsedDate.hour.toString().padLeft(2, '0')}:${parsedDate.minute.toString().padLeft(2, '0')}";
        } else if (remarkDate == yesterday) {
          return "Yesterday at ${parsedDate.hour.toString().padLeft(2, '0')}:${parsedDate.minute.toString().padLeft(2, '0')}";
        } else {
          return "${parsedDate.day.toString().padLeft(2, '0')}/${parsedDate.month.toString().padLeft(2, '0')}/${parsedDate.year} at ${parsedDate.hour.toString().padLeft(2, '0')}:${parsedDate.minute.toString().padLeft(2, '0')}";
        }
      }

      return dateString;
    } catch (e) {
      return dateString;
    }
  }

  Widget _buildSectionHeader(int count) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 4.w,
              height: 20.h,
              decoration: BoxDecoration(
                color: Colors.blue.shade600,
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
            SizedBox(width: 8.w),
            Text(
              "Action Points",
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
            SizedBox(width: 8.w),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(20.r),
              ),
              child: Text(
                "Total Action Point: $count",
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.blue.shade600,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
  Widget _buildMeetingHeader(GetActionPointViewModel vm) {
    final meeting = vm.meeting;
    final projects = vm.projects;

    if (meeting == null) return SizedBox.shrink();

    /// 🔍 Find matching project
    Projects? selectedProject;
    if (projects.isNotEmpty && meeting.projectId != null) {
      try {
        selectedProject = projects.firstWhere(
              (p) => p.id.toString() == meeting.projectId.toString(),
        );
      } catch (_) {
        selectedProject = null;
      }
    }

    final isProjectMeeting =
        meeting.meetingType?.toLowerCase().contains("project") ?? false;

    return Container(
      margin: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade600, Colors.blue.shade400],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.shade200,
            blurRadius: 20.r,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(20.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            /// 🔹 TOP ROW (Code + Date)
            Row(
              children: [
                _chip(meeting.meetingCode ?? "N/A"),
                Spacer(),
                _chipWithIcon(
                  Icons.calendar_today,
                  meeting.meetingDate ?? "No Date",
                ),
              ],
            ),

            SizedBox(height: 16.h),

            /// 🔹 MEETING TYPE
            Text(
              meeting.meetingType ?? "Meeting",
              style: TextStyle(
                color: Colors.white,
                fontSize: 22.sp,
                fontWeight: FontWeight.bold,
              ),
            ),

            SizedBox(height: 10.h),
            _infoRows(Icons.tag, "Meeting ID",meeting.id),
            _infoRow(Icons.person, "Created by", meeting.createdByName),
            _infoRow(Icons.access_time, "Created on", meeting.createdOn),
            if (isProjectMeeting && selectedProject != null) ...[
              SizedBox(height: 12.h),
              // Divider(color: Colors.white30),


              // _infoRow(Icons.code, "Code", selectedProject.projectCode),
              if (isProjectMeeting && selectedProject != null) ...[
                // SizedBox(height: 12.h),
                // Divider(color: Colors.white30),


                _infoRow(
                  Icons.business,
                  "Project",
                  selectedProject.name,
                  isBold: true,
                ),
                _infoRow(
                  Icons.supervisor_account,
                  "Project Manager",
                  meeting.projectManager,
                ),
              // _infoRow(Icons.person_outline, "Project Head", selectedProject.projectHeadId),
                // _infoRow(Icons.account_tree, "Vertical", selectedProject.verticalId),
              // _infoRow(Icons.work_outline, "Portfolio", selectedProject.portfolioId),
            ],
          ],
        ])
      ),
    );
  }
  Widget _infoRows(IconData icon, String label, String? value, {bool isBold = false}) {
    return Padding(
      padding: EdgeInsets.only(top: 6.h),
      child: Row(
        children: [
          Icon(icon, size: 14.sp, color: Colors.white70),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              "$label: AP${value ?? '-'}",
              style: TextStyle(
                color: isBold ? Colors.white : Colors.white70,
                fontSize: 13.sp,
                fontWeight: isBold ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }
  Widget _infoRow(IconData icon, String label, String? value, {bool isBold = false}) {
    return Padding(
      padding: EdgeInsets.only(top: 6.h),
      child: Row(
        children: [
          Icon(icon, size: 14.sp, color: Colors.white70),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              "$label: ${value ?? '-'}",
              style: TextStyle(
                color: isBold ? Colors.white : Colors.white70,
                fontSize: 13.sp,
                fontWeight: isBold ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String text) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 12.sp,
        ),
      ),
    );
  }

  Widget _chipWithIcon(IconData icon, String text) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Row(
        children: [
          Icon(icon, size: 12.sp, color: Colors.white),
          SizedBox(width: 4.w),
          Text(
            text,
            style: TextStyle(color: Colors.white, fontSize: 12.sp),
          ),
        ],
      ),
    );
  }
  // Widget _buildMeetingHeader(GetActionPointViewModel vm) {
  //   final meeting = vm.meeting;
  //   if (meeting == null) return SizedBox.shrink();
  //
  //   return Container(
  //     margin: EdgeInsets.all(16.w),
  //     decoration: BoxDecoration(
  //       gradient: LinearGradient(
  //         colors: [Colors.blue.shade600, Colors.blue.shade400],
  //         begin: Alignment.topLeft,
  //         end: Alignment.bottomRight,
  //       ),
  //       borderRadius: BorderRadius.circular(20.r),
  //       boxShadow: [
  //         BoxShadow(
  //           color: Colors.blue.shade200,
  //           blurRadius: 20.r,
  //           offset: Offset(0, 8),
  //         ),
  //       ],
  //     ),
  //     child: Padding(
  //       padding: EdgeInsets.all(20.w),
  //       child: Column(
  //         crossAxisAlignment: CrossAxisAlignment.start,
  //         children: [
  //           Row(
  //             children: [
  //               Container(
  //                 padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
  //                 decoration: BoxDecoration(
  //                   color: Colors.white.withOpacity(0.2),
  //                   borderRadius: BorderRadius.circular(20.r),
  //                 ),
  //                 child: Text(
  //                   meeting.meetingCode ?? "N/A",
  //                   style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12.sp),
  //                 ),
  //               ),
  //               Spacer(),
  //               Container(
  //                 padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
  //                 decoration: BoxDecoration(
  //                   color: Colors.white.withOpacity(0.2),
  //                   borderRadius: BorderRadius.circular(20.r),
  //                 ),
  //                 child: Row(
  //                   mainAxisSize: MainAxisSize.min,
  //                   children: [
  //                     Icon(Icons.calendar_today, size: 12.sp, color: Colors.white),
  //                     SizedBox(width: 4.w),
  //                     Text(
  //                       meeting.meetingDate ?? "No Date",
  //                       style: TextStyle(color: Colors.white, fontSize: 12.sp),
  //                     ),
  //                   ],
  //                 ),
  //               ),
  //             ],
  //           ),
  //           SizedBox(height: 16.h),
  //           Text(
  //             meeting.meetingType ?? "Meeting",
  //             style: TextStyle(color: Colors.white, fontSize: 22.sp, fontWeight: FontWeight.bold),
  //           ),
  //           SizedBox(height: 12.h),
  //
  //           Row(
  //             children: [
  //               Icon(Icons.person, size: 14.sp, color: Colors.white70),
  //               SizedBox(width: 8.w),
  //               Text(
  //                 "Created by: ${meeting.createdByName ?? "Unknown"}",
  //                 style: TextStyle(color: Colors.white70, fontSize: 13.sp),
  //               ),
  //             ],
  //           ),
  //           if (meeting.projectName != null) ...[
  //             SizedBox(height: 8.h),
  //             Row(
  //               children: [
  //                 Icon(Icons.business, size: 14.sp, color: Colors.white70),
  //                 SizedBox(width: 8.w),
  //                 Text(
  //                   "Project: ${meeting.projectName}",
  //                   style: TextStyle(color: Colors.white70, fontSize: 13.sp),
  //                 ),
  //               ],
  //             ),
  //           ],
  //         ],
  //       ),
  //     ),
  //   );
  // }

  Widget _buildActionPointCard(Details item, GetActionPointViewModel vm) {
    final statusColor = _getStatusColor(item.status);
    final statusIcon = _getStatusIcon(item.status);

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade100,
            blurRadius: 10.r,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16.r),
        child: InkWell(
          borderRadius: BorderRadius.circular(16.r),
          child: Padding(
            padding: EdgeInsets.all(16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 4.w,
                      height: 60.h,
                      decoration: BoxDecoration(
                        color: statusColor,
                        borderRadius: BorderRadius.circular(2.r),
                      ),
                    ),
                    SizedBox(width: 12.w),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.description ?? "No Description",
                            style: TextStyle(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade800
                            ),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 8.h),
                          // Wrap(
                          //   spacing: 8.w,
                          //   runSpacing: 8.h,
                          //   children: [
                          //     _buildStatusChip(item.status ?? "Unknown", statusColor, statusIcon),
                          //     if (item.targetDate != null)
                          //       _buildDateChip(item.targetDate!),
                          //     SizedBox(width: 20.w),
                          //
                          //   ],
                          // ),
                        ],
                      ),
                    ),
                  ],
                ),
                // SizedBox(height: 16.h),
                Divider(color: Colors.grey.shade100),
                 SizedBox(height: 5.h),
                _buildDetailedInfoGrid(item),
                SizedBox(height: 12.h),
                Divider(color: Colors.grey.shade100),
                SizedBox(height: 12.h),
                _buildMetadataSection(item),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailedInfoGrid(Details item) {
    return GridView.count(
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 12.h,
      crossAxisSpacing: 12.w,
      childAspectRatio: 2.5,
      children: [
        _buildDetailedInfoItem(
          "Assigned To",
          item.assignedEmployeeName ?? "Unassigned",
          Icons.person_outline,
          Colors.blue,
        ),
        _buildDetailedInfoItem(
          "Sub Project",
          item.subProjectName?.toString() ?? "Not Assigned",
          Icons.account_tree_outlined,
          Colors.green,
        ),
        _buildDetailedInfoItem(
          "Status",
          item.status ?? "Unknown",
          Icons.flag,
          _getStatusColor(item.status),
        ),
        _buildDetailedInfoItem(
          "Target Date",
          _formatDate(item.targetDate),
          Icons.calendar_today,
          Colors.orange,
        ),
        if (item.id != null)
          _buildDetailedInfoItem(
            "AP ID",
            "APD${item.id!}",
            Icons.numbers,
            Colors.purple,
          ),
      ],
    );
  }

  Widget _buildDetailedInfoItem(String label, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 2.h, horizontal: 12.w),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(6.w),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Icon(icon, size: 16.sp, color: color),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10.sp,
                    color: Colors.grey.shade500,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade800,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // IMPROVED _buildMetadataSection with proper date formatting and better design
  Widget _buildMetadataSection(Details item) {
    final DateFormat dateFormat = DateFormat('dd MMM yyyy, hh:mm a');

    return Row(
      children: [
        Expanded(
          child: Container(
            padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 14.w),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.grey.shade50,
                  Colors.grey.shade100,
                ],
              ),
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(
                color: Colors.grey.shade200,
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(4.r),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Icon(
                        Icons.calendar_today,
                        size: 12.sp,
                        color: Colors.orange.shade700,
                      ),
                    ),
                    SizedBox(width: 6.w),
                    Text(
                      "Created On",
                      style: TextStyle(
                        fontSize: 10.sp,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8.h),
                Text(
                  _formatFullDateTime(item.createdOn, dateFormat),
                  style: TextStyle(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade800,
                  ),
                ),
              ],
            ),
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: Container(
            padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 14.w),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.grey.shade50,
                  Colors.grey.shade100,
                ],
              ),
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(
                color: Colors.grey.shade200,
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(4.r),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Icon(
                        Icons.update,
                        size: 12.sp,
                        color: Colors.blue.shade700,
                      ),
                    ),
                    SizedBox(width: 6.w),
                    Text(
                      "Updated On",
                      style: TextStyle(
                        fontSize: 10.sp,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 8.h),
                Text(
                  _formatFullDateTime(item.updatedOn ?? item.createdOn, dateFormat),
                  style: TextStyle(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade800,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Helper method to format full date and time
  String _formatFullDateTime(String? dateString, DateFormat dateFormat) {
    if (dateString == null || dateString.isEmpty) return "Unknown date";

    try {
      DateTime? dateTime;

      // Try parsing ISO format (2026-04-16T20:19:00)
      if (dateString.contains('T')) {
        dateTime = DateTime.tryParse(dateString);
      }
      // Try parsing format with space (2026-04-16 20:19:00)
      else if (dateString.contains(' ') && dateString.contains('-')) {
        dateTime = DateTime.tryParse(dateString.replaceFirst(' ', 'T'));
      }
      // Try parsing timestamp (milliseconds since epoch)
      else if (int.tryParse(dateString) != null) {
        dateTime = DateTime.fromMillisecondsSinceEpoch(int.parse(dateString));
      }

      if (dateTime != null && dateTime.year > 1900) {
        return dateFormat.format(dateTime);
      }

      return dateString;
    } catch (e) {
      return dateString;
    }
  }

  Widget _buildMetadataItem(String label, String user, String date, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 12.w),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 12.sp, color: color),
              SizedBox(width: 4.w),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10.sp,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          SizedBox(height: 4.h),
          Text(
            user,
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade800,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            _formatDate(date),
            style: TextStyle(
              fontSize: 10.sp,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(String text, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10.sp, color: color),
          SizedBox(width: 4.w),
          Text(
            text,
            style: TextStyle(
              fontSize: 10.sp,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) {
      return "No date";
    }

    try {
      final String dateStr = dateString.trim();
      DateTime? parsedDate;

      if (dateStr.contains('T')) {
        parsedDate = DateTime.tryParse(dateStr.split('T')[0]);
      } else if (dateStr.contains('-')) {
        parsedDate = DateTime.tryParse(dateStr);
      } else if (dateStr.contains('/')) {
        final parts = dateStr.split('/');
        if (parts.length == 3) {
          parsedDate = DateTime.tryParse('${parts[2]}-${parts[1]}-${parts[0]}');
          if (parsedDate == null) {
            parsedDate = DateTime.tryParse('${parts[2]}-${parts[0]}-${parts[1]}');
          }
        }
      }

      if (parsedDate != null && parsedDate.year > 1900) {
        return "${parsedDate.day.toString().padLeft(2, '0')}/${parsedDate.month.toString().padLeft(2, '0')}/${parsedDate.year}";
      }

      return dateStr;
    } catch (e) {
      return dateString ?? "Invalid date";
    }
  }

  Widget _buildStatusChip(String status, Color color, IconData icon) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12.sp, color: color),
          SizedBox(width: 4.w),
          Text(status, style: TextStyle(fontSize: 11.sp, fontWeight: FontWeight.w500, color: color)),
        ],
      ),
    );
  }

  Widget _buildDateChip(String date) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12.r),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.event, size: 12.sp, color: Colors.grey.shade600),
          SizedBox(width: 4.w),
          Text(
              _formatDate(date),
              style: TextStyle(fontSize: 11.sp, color: Colors.grey.shade600)
          ),
        ],
      ),
    );
  }

  IconData _getStatusIcon(String? status) {
    switch (status?.toLowerCase()) {
      case 'completed':
        return Icons.check_circle;
      case 'in progress':
        return Icons.play_circle;
      case 'pending':
        return Icons.pending;
      default:
        return Icons.help_outline;
    }
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'in_progress':
      case 'inprogress':
        return Colors.blue;
      case 'completed':
      case 'done':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Widget _buildAttachmentsSectionList(GetActionPointViewModel vm) {
    return Container(
      margin: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade100,
            blurRadius: 10.r,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(16.w),
            child: Row(
              children: [
                Icon(Icons.attach_file, color: Colors.blue.shade600),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(
                    "Attachments",
                    style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold, color: Colors.grey.shade800),
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                  child: Text(
                    "${vm.attachments.length}",
                    style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.blue.shade600
                    ),
                  ),
                ),
              ],
            ),
          ),
          Divider(color: Colors.grey.shade100, height: 0),
          ListView.separated(
            itemCount: vm.attachments.length,
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            separatorBuilder: (context, index) => Divider(color: Colors.grey.shade100, height: 0),
            itemBuilder: (context, index) {
              final file = vm.attachments[index];
              return InkWell(
                onTap: () => _downloadAndOpenFile(file),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        width: 36.w,
                        height: 36.w,
                        decoration: BoxDecoration(
                          color: _getFileIconColor(file.fileName).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Icon(
                          _getFileIcon(file.fileName),
                          color: _getFileIconColor(file.fileName),
                          size: 18.sp,
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              file.fileName ?? "Unnamed File",
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13.sp,
                                color: Colors.grey.shade800,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              "${file.uploadedByName ?? "Unknown"} • ${_formatDate(file.uploadedOn)}",
                              style: TextStyle(fontSize: 10.sp, color: Colors.grey.shade500),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(16.r),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.open_in_new, size: 12.sp, color: Colors.blue.shade600),
                            SizedBox(width: 4.w),
                            Text(
                              "Open",
                              style: TextStyle(
                                fontSize: 11.sp,
                                fontWeight: FontWeight.w500,
                                color: Colors.blue.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  IconData _getFileIcon(String? fileName) {
    if (fileName == null) return Icons.insert_drive_file;

    final extension = fileName.split('.').last.toLowerCase();

    switch (extension) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'xls':
      case 'xlsx':
        return Icons.table_chart;
      case 'ppt':
      case 'pptx':
        return Icons.slideshow;
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
      case 'webp':
        return Icons.image;
      case 'mp4':
      case 'mov':
      case 'avi':
        return Icons.video_file;
      case 'mp3':
      case 'wav':
        return Icons.audiotrack;
      case 'txt':
        return Icons.text_snippet;
      case 'zip':
      case 'rar':
        return Icons.folder_zip;
      default:
        return Icons.insert_drive_file;
    }
  }

  Color _getFileIconColor(String? fileName) {
    if (fileName == null) return Colors.blue;

    final extension = fileName.split('.').last.toLowerCase();

    switch (extension) {
      case 'pdf':
        return Colors.red;
      case 'doc':
      case 'docx':
        return Colors.blue;
      case 'xls':
      case 'xlsx':
        return Colors.green;
      case 'ppt':
      case 'pptx':
        return Colors.orange;
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
      case 'webp':
        return Colors.purple;
      case 'mp4':
      case 'mov':
        return Colors.teal;
      default:
        return Colors.blue;
    }
  }

  Future<void> _downloadAndOpenFile(Attachments file) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Opening ${file.fileName}..."),
          duration: const Duration(seconds: 15),
        ),
      );

      String fileUrl = file.filePath ?? '';
      if (fileUrl.isEmpty) {
        throw Exception('File URL is empty');
      }

      if (!fileUrl.startsWith('http://') && !fileUrl.startsWith('https://')) {
        if (fileUrl.startsWith('/')) {
          fileUrl = fileUrl.substring(1);
        }
        fileUrl = '${Endpoint.pmsBaseUrl}$fileUrl';
        print('Full URL: $fileUrl');
      }

      print('Downloading from URL: $fileUrl');

      final response = await http.get(Uri.parse(fileUrl));
      if (response.statusCode != 200) {
        throw Exception('Failed to download file: HTTP ${response.statusCode}');
      }

      final directory = await getTemporaryDirectory();
      final filePath = '${directory.path}/${file.fileName}';
      final savedFile = File(filePath);
      await savedFile.writeAsBytes(response.bodyBytes);

      print('File saved to: $filePath');

      ScaffoldMessenger.of(context).clearSnackBars();

      final result = await OpenFile.open(filePath);

      if (result.type == ResultType.done) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("${file.fileName} opened successfully"),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.r),
            ),
          ),
        );
      } else {
        throw Exception('Failed to open file: ${result.message}');
      }
    } catch (e) {
      print('Error opening file: $e');
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error_outline, color: Colors.white, size: 18.sp),
              SizedBox(width: 8.w),
              Expanded(child: Text("Failed to open: ${e.toString()}")),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.r),
          ),
        ),
      );
    }
  }

  void _showAttachmentOptions(BuildContext context, Attachments file) {
    print('Attachment clicked: ${file.fileName}');
    print('File path: ${file.filePath}');
    print('Uploaded by: ${file.uploadedByName}');
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (BuildContext context) {
        return Container(
          padding: EdgeInsets.all(16.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
              SizedBox(height: 16.h),
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(12.w),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Icon(Icons.insert_drive_file, color: Colors.blue.shade600, size: 24.sp),
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          file.fileName ?? "Unnamed File",
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade800,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 4.h),
                        Text(
                          "Uploaded by: ${file.uploadedByName ?? "Unknown"}",
                          style: TextStyle(fontSize: 12.sp, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 16.h),
              Divider(color: Colors.grey.shade100),
              _buildOptionTile(
                context: context,
                icon: Icons.download,
                title: "Download",
                color: Colors.blue,
                onTap: () {
                  Navigator.pop(context);
                  _downloadFile(file);
                },
              ),
              _buildOptionTile(
                context: context,
                icon: Icons.open_in_browser,
                title: "Open",
                color: Colors.green,
                onTap: () {
                  Navigator.pop(context);
                  _openFile(file);
                },
              ),
              SizedBox(height: 8.h),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOptionTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: EdgeInsets.all(8.w),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10.r),
        ),
        child: Icon(icon, color: color, size: 20.sp),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 14.sp,
          fontWeight: FontWeight.w500,
          color: Colors.grey.shade800,
        ),
      ),
      onTap: onTap,
    );
  }

  void _downloadFile(Attachments file) async {
    try {
      if (Platform.isAndroid) {
        if (await Permission.storage.isDenied) {
          if (await Permission.photos.request().isGranted ||
              await Permission.videos.request().isGranted ||
              await Permission.audio.request().isGranted) {
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text("Storage permission required to download files"),
                backgroundColor: Colors.orange,
              ),
            );
            return;
          }
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 20.w,
                height: 20.h,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              ),
              SizedBox(width: 12.w),
              Text("Downloading ${file.fileName}..."),
            ],
          ),
          duration: Duration(seconds: 2),
        ),
      );

      final fileUrl = file.filePath ?? '';
      if (fileUrl.isEmpty) {
        throw Exception('File URL is empty');
      }

      print('Downloading from URL: $fileUrl');

      final response = await http.get(Uri.parse(fileUrl));
      if (response.statusCode != 200) {
        throw Exception('Failed to download file: HTTP ${response.statusCode}');
      }

      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/${file.fileName}';
      final savedFile = File(filePath);
      await savedFile.writeAsBytes(response.bodyBytes);

      print('File saved to: $filePath');

      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("✅ Downloaded: ${file.fileName}"),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.r),
          ),
          action: SnackBarAction(
            label: "Open",
            textColor: Colors.white,
            onPressed: () => _openLocalFile(filePath),
          ),
        ),
      );
    } catch (e) {
      print('Download error: $e');
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("❌ Download failed: ${e.toString()}"),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.r),
          ),
        ),
      );
    }
  }

  void _openFile(Attachments file) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/${file.fileName}';
      final localFile = File(filePath);

      if (await localFile.exists()) {
        await _openLocalFile(filePath);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Downloading file first..."),
            duration: Duration(seconds: 1),
          ),
        );

        await _downloadAndOpen(file);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("❌ Failed to open file: ${e.toString()}"),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.r),
          ),
        ),
      );
    }
  }

  Future<void> _downloadAndOpen(Attachments file) async {
    try {
      final response = await http.get(Uri.parse(file.filePath ?? ''));
      if (response.statusCode != 200) {
        throw Exception('Failed to download file');
      }

      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/${file.fileName}';
      final savedFile = File(filePath);
      await savedFile.writeAsBytes(response.bodyBytes);

      await _openLocalFile(filePath);
    } catch (e) {
      throw Exception('Failed to download and open file: $e');
    }
  }

  Future<void> _openLocalFile(String filePath) async {
    final result = await OpenFile.open(filePath);

    if (result.type == ResultType.done) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("📄 File opened successfully"),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.r),
          ),
        ),
      );
    } else {
      throw Exception('Failed to open file: ${result.message}');
    }
  }
}