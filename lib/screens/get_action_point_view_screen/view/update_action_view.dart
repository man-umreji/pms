import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';

import '../../dashbord/view/dashbord_view.dart';
import '../../login_screen/view_model/login_screen_view_model.dart';
import '../../meating_action_point_screen/model/meating_action_point_model.dart' as emp;
import '../../meating_action_point_screen/repository/meating_action_point_repo.dart';
import '../model/get_action_point_model.dart';
import '../model/get_all_status_model.dart';
import '../model/update_action_point_model.dart';
import '../repository/get_all_status_repo.dart';
import '../view_model/get_action_view_view_model.dart';


class ActionPointFormScreen extends StatefulWidget {
  final GetActionPointViewModel viewModel;
  final int meetingId;

  const ActionPointFormScreen({
    super.key,
    required this.viewModel,
    required this.meetingId,
  });

  @override
  State<ActionPointFormScreen> createState() => _ActionPointFormScreenState();
}

class _ActionPointFormScreenState extends State<ActionPointFormScreen> {
  final _formKey = GlobalKey<FormState>();

  List<TextEditingController> _descControllers = [];
  List<TextEditingController> _dateControllers = [];
  List<String?> _assigneeIds = [];
  List<String?> _selectedStatuses = [];

  final TextEditingController _remarkController = TextEditingController();

  List<emp.Data> _employees = [];
  bool _loadingEmployees = true;
  bool _submitting = false;
  List<String?> _originalStatuses = [];
  // Attachment variables
  final List<String> _newAttachmentPaths = [];
  List<Attachments> _existingAttachments = [];
  bool _isUploading = false;

  // Status list variables
  List<StatusList> _statusList = [];
  bool _isStatusLoading = false;

  // Role check
  bool get _isRole93 {
    final loginProvider = Provider.of<LoginProvider>(context, listen: false);
    final role = loginProvider.role;
    return role == "93";
  }

  @override
  void initState() {
    super.initState();
    _syncControllersFromViewModel();
    _initializeSelectedStatuses();
    _loadEmployees();
    _loadExistingAttachments();
    _fetchAllStatus();
  }

  void _initializeSelectedStatuses() {
    final details = widget.viewModel.details;

    _selectedStatuses = List.generate(
      details.length,
          (index) => details[index].status,
    );

    // ✅ store original status
    _originalStatuses = List.generate(
      details.length,
          (index) => details[index].status,
    );
  }

  void _syncControllersFromViewModel() {
    for (final c in _descControllers) {
      c.dispose();
    }
    for (final c in _dateControllers) {
      c.dispose();
    }
    final list = widget.viewModel.details;
    _descControllers =
        list.map((e) => TextEditingController(text: e.description ?? '')).toList();
    _dateControllers = list
        .map((e) => TextEditingController(text: _formatDateForField(e.targetDate)))
        .toList();
    _assigneeIds = list.map((e) => e.assignedTo?.toString()).toList();
  }

  void _loadExistingAttachments() {
    _existingAttachments = List.from(widget.viewModel.attachments);
  }

  String _formatDateForField(String? raw) {
    if (raw == null || raw.isEmpty || raw == '0000-00-00') return '';
    final iso = DateTime.tryParse(raw);
    if (iso != null) {
      return '${iso.day.toString().padLeft(2, '0')}/${iso.month.toString().padLeft(2, '0')}/${iso.year}';
    }
    if (raw.contains('/')) return raw;
    return raw;
  }

  Future<void> _loadEmployees() async {
    final m = widget.viewModel.meeting;
    if (m?.meetingTypeId == null) {
      setState(() => _loadingEmployees = false);
      return;
    }
    setState(() => _loadingEmployees = true);
    try {
      final repo = SelectEmployeeRepository();
      final res = await repo.getEmployees(
        emp.SelectEmployeeReqModel(
          meatingTypeId: m!.meetingTypeId,
          projectId: m.projectId?.toString() ?? '1',
        ),

      );
      if (!mounted) return;
      if (res.status == true && res.data != null) {
        log("employee response fetched");
        int length=res.data?.length??0;
        for(int i=0;i<length;i++){
          log(res.data?[i].id.toString()??"");
          log(res.data?[i].employeeName.toString()??"");
        }

        log("employee response fetched");
        // Deduplicate employees by ID
        final uniqueEmployees = <emp.Data>[];
        final seenIds = <String>{};

        for (var employee in res.data!) {
          final id = employee.id?.toString();
          if (id != null && !seenIds.contains(id)) {
            seenIds.add(id);
            uniqueEmployees.add(employee);
          }
        }

        setState(() => _employees = uniqueEmployees);
      }
    } finally {
      if (mounted) setState(() => _loadingEmployees = false);
    }
  }

  Future<void> _pickDate(int index) async {
    // Don't allow date picking if role is 93 or if status is complete
    if (_isRole93 || _isStatusComplete(_selectedStatuses[index])) return;

    DateTime now = DateTime.now();
    DateTime initial = now;

    final t = _dateControllers[index].text.trim();
    if (t.isNotEmpty) {
      final parts = t.split('/');
      if (parts.length == 3) {
        final d = int.tryParse(parts[0]);
        final m = int.tryParse(parts[1]);
        final y = int.tryParse(parts[2]);
        if (d != null && m != null && y != null) {
          final parsedDate = DateTime(y, m, d);

          // ✅ Allow only past or today as initial
          if (parsedDate.isBefore(now) || parsedDate.isAtSameMomentAs(now)) {
            initial = parsedDate;
          }
        }
      }
    }

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000), // ✅ allow past dates
      lastDate: now,             // ❗ block future dates
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF2563EB),
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && mounted) {
      final formatted =
          '${picked.day.toString().padLeft(2, '0')}/'
          '${picked.month.toString().padLeft(2, '0')}/'
          '${picked.year}';

      setState(() => _dateControllers[index].text = formatted);
    }
  }

  // Helper method to check if status is complete
  bool _isStatusComplete(String? status) {
    if (status == null) return false;
    final lowerStatus = status.toLowerCase();
    return lowerStatus == 'complete' || lowerStatus == 'completed';
  }

  Future<void> _fetchAllStatus() async {
    setState(() => _isStatusLoading = true);

    try {
      final repo = GetAllStatusRepository();
      final response = await repo.getAllStatus();

      if (response.success == true && response.statusList != null) {
        _statusList = response.statusList!
            .where((e) => (e.value ?? "").toLowerCase() != "all")
            .toList();
      } else {
        _statusList = [];
      }
    } catch (e) {
      print("❌ STATUS FETCH ERROR: $e");
      _statusList = [];
    }

    setState(() => _isStatusLoading = false);
  }

  Future<void> _pickAttachment() async {
    if (_isRole93) return;

    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.photo_library, color: Color(0xFF2563EB)),
                title: Text('Choose from Gallery'),
                onTap: () {
                  Navigator.pop(context);
                  _pickFileFromGallery();
                },
              ),
              ListTile(
                leading: Icon(Icons.file_upload, color: Color(0xFF2563EB)),
                title: Text('Upload Document'),
                onTap: () {
                  Navigator.pop(context);
                  _pickDocument();
                },
              ),
              ListTile(
                leading: Icon(Icons.camera_alt, color: Color(0xFF2563EB)),
                title: Text('Take Photo'),
                onTap: () {
                  Navigator.pop(context);
                  _takePhoto();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _pickFileFromGallery() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: true,
    );
    if (result != null && mounted) {
      setState(() {
        for (final file in result.files) {
          if (file.path != null) {
            _newAttachmentPaths.add(file.path!);
          }
        }
      });
      _showSuccessMessage('Added ${result.files.length} image(s)');
    }
  }

  Future<void> _pickDocument() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'xls', 'xlsx', 'txt'],
      allowMultiple: true,
    );
    if (result != null && mounted) {
      setState(() {
        for (final file in result.files) {
          if (file.path != null) {
            _newAttachmentPaths.add(file.path!);
          }
        }
      });
      _showSuccessMessage('Added ${result.files.length} document(s)');
    }
  }

  Future<void> _takePhoto() async {
    _showInfoMessage('Camera functionality coming soon');
  }

  void _removeNewAttachment(int index) {
    if (_isRole93) return;

    setState(() {
      _newAttachmentPaths.removeAt(index);
    });
  }

  String _formatFileSize(String path) {
    try {
      final file = File(path);
      if (file.existsSync()) {
        final bytes = file.lengthSync();
        if (bytes < 1024) return '$bytes B';
        if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
        return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
      }
    } catch (e) {
      return 'Unknown size';
    }
    return 'Unknown size';
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.white, size: 20.sp),
            SizedBox(width: 12.w),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.r),
        ),
        margin: EdgeInsets.all(10.w),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle_outline, color: Colors.white, size: 20.sp),
            SizedBox(width: 12.w),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.r),
        ),
        margin: EdgeInsets.all(10.w),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showInfoMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.info_outline, color: Colors.white, size: 20.sp),
            SizedBox(width: 12.w),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Color(0xFF2563EB),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10.r),
        ),
        margin: EdgeInsets.all(10.w),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Widget _buildFieldLabel(String text, IconData icon) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(5.r),
          decoration: BoxDecoration(
            color: Color(0xFF2563EB).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Icon(icon, size: 16.sp, color: Color(0xFF2563EB)),
        ),
        SizedBox(width: 8.w),
        Text(
          text,
          style: TextStyle(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
            color: Color(0xFF1E293B),
          ),
        ),
      ],
    );
  }

  Widget _buildMeetingHeader(Meeting? meeting) {
    if (meeting == null) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
        ),
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF2563EB).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.meeting_room, color: Colors.white, size: 20.sp),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  meeting.meetingType ?? 'Meeting',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
              if (meeting.meetingCode != null && meeting.meetingCode!.isNotEmpty)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                  child: Text(
                    meeting.meetingCode!,
                    style: TextStyle(
                      fontSize: 10.sp,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: 12.h),
          if (meeting.meetingDate != null &&
              meeting.meetingDate!.isNotEmpty &&
              meeting.meetingDate != '0000-00-00')
            Padding(
              padding: EdgeInsets.only(bottom: 6.h),
              child: Row(
                children: [
                  Icon(Icons.calendar_today, color: Colors.white70, size: 14.sp),
                  SizedBox(width: 6.w),
                  Text(
                    'Meeting Date: ${_formatDateForDisplay(meeting.meetingDate)}',
                    style: TextStyle(fontSize: 12.sp, color: Colors.white70),
                  ),
                ],
              ),
            ),
          if (meeting.projectName != null && meeting.projectName.toString().isNotEmpty)
            Padding(
              padding: EdgeInsets.only(bottom: 6.h),
              child: Row(
                children: [
                  Icon(Icons.business, color: Colors.white70, size: 14.sp),
                  SizedBox(width: 6.w),
                  Expanded(
                    child: Text(
                      'Project: ${meeting.projectName}',
                      style: TextStyle(fontSize: 12.sp, color: Colors.white70),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          if (meeting.projectManager != null && meeting.projectManager.toString().isNotEmpty)
            Padding(
              padding: EdgeInsets.only(bottom: 6.h),
              child: Row(
                children: [
                  Icon(Icons.person_outline, color: Colors.white70, size: 14.sp),
                  SizedBox(width: 6.w),
                  Text(
                    'Project Manager: ${meeting.projectManager}',
                    style: TextStyle(fontSize: 12.sp, color: Colors.white70),
                  ),
                ],
              ),
            ),
          if (meeting.createdByName != null && meeting.createdByName!.isNotEmpty)
            Padding(
              padding: EdgeInsets.only(bottom: 6.h),
              child: Row(
                children: [
                  Icon(Icons.person_add, color: Colors.white70, size: 14.sp),
                  SizedBox(width: 6.w),
                  Text(
                    'Created By: ${meeting.createdByName}',
                    style: TextStyle(fontSize: 12.sp, color: Colors.white70),
                  ),
                ],
              ),
            ),
          if (meeting.createdOn != null && meeting.createdOn!.isNotEmpty)
            Padding(
              padding: EdgeInsets.only(bottom: 6.h),
              child: Row(
                children: [
                  Icon(Icons.access_time, color: Colors.white70, size: 14.sp),
                  SizedBox(width: 6.w),
                  Text(
                    'Created On: ${_formatDateForDisplay(meeting.createdOn)}',
                    style: TextStyle(fontSize: 12.sp, color: Colors.white70),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  String _formatDateForDisplay(String? dateString) {
    if (dateString == null || dateString.isEmpty || dateString == '0000-00-00') return '';
    if (dateString.contains(' ')) {
      final datePart = dateString.split(' ')[0];
      return _formatDateString(datePart);
    }
    return _formatDateString(dateString);
  }

  String _formatDateString(String dateString) {
    try {
      final parts = dateString.split('-');
      if (parts.length == 3) {
        return '${parts[2]}/${parts[1]}/${parts[0]}';
      }
    } catch (e) {
      return dateString;
    }
    return dateString;
  }

  Widget _buildAttachmentsSection() {
    final hasAttachments = _existingAttachments.isNotEmpty || _newAttachmentPaths.isNotEmpty;

    if (!hasAttachments && !_isUploading) {
      // Hide upload button if role is 93
      if (_isRole93) return const SizedBox.shrink();

      return Container(
        margin: EdgeInsets.only(bottom: 20.h),
        child: OutlinedButton.icon(
          onPressed: _pickAttachment,
          icon: Icon(Icons.cloud_upload_outlined, size: 18.sp),
          label: Text(
            'Upload document',
            style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w500),
          ),
          style: OutlinedButton.styleFrom(
            foregroundColor: Color(0xFF2563EB),
            side: BorderSide(color: Color(0xFF2563EB).withOpacity(0.3)),
            padding: EdgeInsets.symmetric(vertical: 12.h),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.r),
            ),
          ),
        ),
      );
    }

    return Container(
      margin: EdgeInsets.only(bottom: 20.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFieldLabel('Attachments', Icons.attachment_outlined),
          SizedBox(height: 8.h),
          Container(
            padding: EdgeInsets.all(12.r),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(14.r),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              children: [
                if (_existingAttachments.isNotEmpty) ...[
                  Padding(
                    padding: EdgeInsets.only(bottom: 8.h, left: 8.w),
                    child: Row(
                      children: [
                        Icon(Icons.cloud_done, size: 14.sp, color: Colors.green.shade600),
                        SizedBox(width: 6.w),
                        Text(
                          'Current Attachments',
                          style: TextStyle(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w600,
                            color: Colors.green.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ..._existingAttachments.asMap().entries.map((entry) {
                    final index = entry.key;
                    final attachment = entry.value;
                    final fileName = attachment.fileName ?? 'Unknown';
                    final fileExt = fileName.split('.').last.toLowerCase();
                    final isImage = ['jpg', 'jpeg', 'png', 'gif'].contains(fileExt);

                    return Container(
                      margin: EdgeInsets.only(bottom: 8.h),
                      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10.r),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(6.r),
                            decoration: BoxDecoration(
                              color: isImage ? Colors.green.shade50 : Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                            child: Icon(
                              isImage ? Icons.image : Icons.insert_drive_file,
                              size: 20.sp,
                              color: isImage ? Colors.green.shade700 : Color(0xFF2563EB),
                            ),
                          ),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  fileName,
                                  style: TextStyle(
                                    fontSize: 12.sp,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.grey.shade800,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  'Uploaded by: ${attachment.uploadedByName ?? "Unknown"}',
                                  style: TextStyle(
                                    fontSize: 10.sp,
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Only show delete button if role is NOT 93
                          if (!_isRole93)
                            IconButton(
                              onPressed: () => _onDeleteAttachment(index),
                              icon: Icon(Icons.delete_outline, size: 18.sp, color: Colors.red.shade400),
                            ),
                        ],
                      ),
                    );
                  }).toList(),
                  if (_newAttachmentPaths.isNotEmpty)
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 8.h),
                      child: Divider(color: Colors.grey.shade300),
                    ),
                ],
                if (_newAttachmentPaths.isNotEmpty) ...[
                  Padding(
                    padding: EdgeInsets.only(bottom: 8.h, left: 8.w),
                    child: Row(
                      children: [
                        Icon(Icons.cloud_upload, size: 14.sp, color: Color(0xFF2563EB)),
                        SizedBox(width: 6.w),
                        Text(
                          'New Attachments',
                          style: TextStyle(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF2563EB),
                          ),
                        ),
                      ],
                    ),
                  ),
                  ..._newAttachmentPaths.asMap().entries.map((entry) {
                    final index = entry.key;
                    final path = entry.value;
                    final fileName = path.split('/').last;
                    final fileExt = fileName.split('.').last.toLowerCase();
                    final isImage = ['jpg', 'jpeg', 'png', 'gif'].contains(fileExt);

                    return Container(
                      margin: EdgeInsets.only(bottom: 8.h),
                      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10.r),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(6.r),
                            decoration: BoxDecoration(
                              color: isImage ? Colors.green.shade50 : Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(8.r),
                            ),
                            child: Icon(
                              isImage ? Icons.image : Icons.insert_drive_file,
                              size: 20.sp,
                              color: isImage ? Colors.green.shade700 : Color(0xFF2563EB),
                            ),
                          ),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  fileName,
                                  style: TextStyle(
                                    fontSize: 12.sp,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.grey.shade800,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  _formatFileSize(path),
                                  style: TextStyle(
                                    fontSize: 10.sp,
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Only show remove button if role is NOT 93
                          if (!_isRole93)
                            IconButton(
                              onPressed: () => _removeNewAttachment(index),
                              icon: Icon(Icons.close, size: 18.sp, color: Colors.red.shade400),
                            ),
                        ],
                      ),
                    );
                  }).toList(),
                ],
                // Only show "Add More" button if role is NOT 93
                if (!_isRole93)
                  Padding(
                    padding: EdgeInsets.only(top: 8.h),
                    child: TextButton.icon(
                      onPressed: _pickAttachment,
                      icon: Icon(Icons.add, size: 16.sp),
                      label: Text(
                        'Add More',
                        style: TextStyle(fontSize: 12.sp),
                      ),
                      style: TextButton.styleFrom(
                        foregroundColor: Color(0xFF2563EB),
                      ),
                    ),
                  ),
                if (_isUploading)
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 12.h),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 20.w,
                          height: 20.h,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xFF2563EB),
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Text(
                          'Uploading...',
                          style: TextStyle(fontSize: 13.sp, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRemarkHistorySection(Meeting? meeting) {
    if (meeting == null) return const SizedBox.shrink();
    final remarks = widget.viewModel.remarks;

    if (remarks.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: EdgeInsets.only(bottom: 20.h),
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFieldLabel('Remark History', Icons.history),
          SizedBox(height: 12.h),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: remarks.length,
            separatorBuilder: (context, index) => Divider(
              color: Colors.grey.shade200,
              height: 1.h,
            ),
            itemBuilder: (context, index) {
              final remark = remarks[index];
              return Padding(
                padding: EdgeInsets.symmetric(vertical: 12.h),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: EdgeInsets.all(6.r),
                      decoration: BoxDecoration(
                        color: Color(0xFF2563EB).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                      child: Icon(
                        Icons.comment_outlined,
                        size: 16.sp,
                        color: Color(0xFF2563EB),
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
                              fontSize: 13.sp,
                              color: Color(0xFF1E293B),
                              height: 1.4,
                            ),
                          ),
                          SizedBox(height: 6.h),
                          Row(
                            children: [
                              Icon(
                                Icons.person_outline,
                                size: 10.sp,
                                color: Colors.grey.shade500,
                              ),
                              SizedBox(width: 4.w),
                              Text(
                                'Created By: ${remark.createdByName?.isNotEmpty == true
                                    ? remark.createdByName
                                    : remark.createdBy ?? "Unknown"}',
                                style: TextStyle(
                                  fontSize: 10.sp,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                              SizedBox(width: 12.w),
                              Icon(
                                Icons.access_time,
                                size: 10.sp,
                                color: Colors.grey.shade500,
                              ),
                              SizedBox(width: 4.w),
                              Text(
                                _formatDateForDisplay(remark.createdOn),
                                style: TextStyle(
                                  fontSize: 10.sp,
                                  color: Colors.grey.shade500,
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

  Widget _buildStatusDropdown(BuildContext context, int index, Details point) {
    if (_isStatusLoading) {
      return Padding(
        padding: EdgeInsets.all(8.h),
        child: CircularProgressIndicator(),
      );
    }

    String? currentStatus = _selectedStatuses.length > index
        ? _selectedStatuses[index]
        : point.status;

    final originalCompleted = _isStatusComplete(_originalStatuses[index]);
    final isCompleted = _isStatusComplete(currentStatus);

    // 👇 Get logged-in user details
    final loginProvider = Provider.of<LoginProvider>(context, listen: false);
    final loggedInUser = loginProvider.name?.toLowerCase().trim();
    final role = loginProvider.role;

    // 👇 Assigned user (⚠️ change field if needed)
    final assignedUser = point.assignedEmployeeName?.toLowerCase().trim();

    // 👇 Role check
    final isEmployee = role == "93";

    // 👇 Ownership check
    final isOwner = (loggedInUser ?? '') == (assignedUser ?? '');

    // ✅ FINAL READ-ONLY CONDITION
    final isReadOnly = originalCompleted || (isEmployee && !isOwner);

    if (isReadOnly) {
      final statusLabel = _statusList.firstWhere(
            (status) => status.value == currentStatus,
        orElse: () => StatusList(value: currentStatus, label: currentStatus),
      ).label ?? currentStatus;

      return Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: isCompleted ? Colors.green.shade50 : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: isCompleted ? Colors.green.shade200 : Colors.grey.shade200,
          ),
        ),
        child: Row(
          children: [
            if (isCompleted)
              Icon(Icons.check_circle,
                  size: 14.sp, color: Colors.green.shade700),
            if (isCompleted) SizedBox(width: 8.w),
            Expanded(
              child: Text(
                statusLabel ?? currentStatus ?? "Select status",
                style: TextStyle(
                  fontSize: 14.sp,
                  color: isCompleted
                      ? Colors.green.shade700
                      : Colors.grey.shade700,
                  fontWeight:
                  isCompleted ? FontWeight.w500 : FontWeight.normal,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return DropdownButtonFormField<String>(
      value: currentStatus,
      hint: Text(
        "Select status",
        style: TextStyle(fontSize: 13.sp, color: Colors.grey.shade400),
      ),
      isExpanded: true,
      items: _statusList.map((status) {
        return DropdownMenuItem<String>(
          value: status.value,
          child: Text(
            status.label ?? "",
            style: TextStyle(fontSize: 14.sp),
          ),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          while (_selectedStatuses.length <= index) {
            _selectedStatuses.add(null);
          }
          _selectedStatuses[index] = value;
        });
      },
      decoration: InputDecoration(
        filled: true,
        fillColor: Color(0xFFF8FAFC),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide.none,
        ),
        contentPadding:
        EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
      ),
    );
  }
  Widget _buildActionPointCard(
      BuildContext context,
      int index,
      Details point,
      ) {
    final ids = _employees.map((e) => e.id?.toString()).toSet();
    final isCompleted = _isStatusComplete(_selectedStatuses[index]);
    final isReadOnly = _isRole93 || isCompleted;

    String? ddValue = _assigneeIds[index]?.toString();

    if (ddValue != null && !ids.contains(ddValue)) {
      ddValue = null;
    }

    return Container(
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: isCompleted ? Colors.grey.shade50 : Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: isCompleted ? Colors.grey.shade300 : Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade100,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 28.w,
                height: 28.h,
                decoration: BoxDecoration(
                  gradient: isCompleted
                      ? LinearGradient(
                    colors: [Colors.grey, Colors.grey.shade600],
                  )
                      : LinearGradient(
                    colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
                  ),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      fontSize: 13.sp,
                    ),
                  ),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Text(
                  'Action Point ${index + 1}',
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                    color: isCompleted ? Colors.grey.shade600 : Color(0xFF64748B),
                  ),
                ),
              ),
              if (isCompleted)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(20.r),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.check_circle, size: 12.sp, color: Colors.green.shade700),
                      SizedBox(width: 4.w),
                      Text(
                        'Completed',
                        style: TextStyle(
                          fontSize: 10.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.green.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          SizedBox(height: 16.h),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Description',
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w500,
                  color: isReadOnly ? Colors.grey.shade500 : Color(0xFF64748B),
                ),
              ),
              SizedBox(height: 6.h),
              TextFormField(
                controller: _descControllers[index],
                maxLines: 3,
                readOnly: isReadOnly,
                style: TextStyle(
                  fontSize: 14.sp,
                  color: isReadOnly ? Colors.grey.shade600 : Color(0xFF1E293B),
                ),
                decoration: InputDecoration(
                  hintText: 'Enter description',
                  hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13.sp),
                  filled: true,
                  fillColor: isReadOnly ? Colors.grey.shade100 : Color(0xFFF8FAFC),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: BorderSide(color: Color(0xFF2563EB), width: 1.5),
                  ),
                  contentPadding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
                ),
                validator: isReadOnly ? null : (v) {
                  if (v == null || v.trim().length < 3) {
                    return 'Description required (min 3 chars)';
                  }
                  return null;
                },
              ),
            ],
          ),
          SizedBox(height: 14.h),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Assign To',
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w500,
                  color: isReadOnly ? Colors.grey.shade500 : Color(0xFF64748B),
                ),
              ),
              SizedBox(height: 6.h),
              if (_loadingEmployees)
                Container(
                  padding: EdgeInsets.symmetric(vertical: 12.h),
                  child: LinearProgressIndicator(color: Color(0xFF2563EB)),
                )
              else if (_employees.isEmpty)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
                  decoration: BoxDecoration(
                    color: isReadOnly ? Colors.grey.shade100 : Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Text(
                    point.assignedEmployeeName ?? 'No employees available',
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: isReadOnly ? Colors.grey.shade600 : Color(0xFF64748B),
                    ),
                  ),
                )
              else
                Column(
                  children: [
                    if (point.assignedTo != null &&
                        point.assignedTo.toString().isNotEmpty &&
                        !ids.contains(point.assignedTo.toString()))
                      Container(
                        margin: EdgeInsets.only(bottom: 8.h),
                        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(8.r),
                          border: Border.all(color: Colors.orange.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info_outline, size: 14.sp, color: Colors.orange.shade700),
                            SizedBox(width: 6.w),
                            Expanded(
                              child: Text(
                                'Currently: ${point.assignedEmployeeName ?? 'Unknown'} (ID: ${point.assignedTo})',
                                style: TextStyle(
                                  fontSize: 11.sp,
                                  color: Colors.orange.shade700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    _buildSearchableDropdown(
                      context: context,
                      value: ddValue,
                      items: _employees,
                      hint: point.assignedEmployeeName != null && !ids.contains(point.assignedTo?.toString())
                          ? 'Select new assignee (current: ${point.assignedEmployeeName})'
                          : 'Select employee',
                      onChanged: isReadOnly ? (value) {} : (v) {
                        print("000000000");
                        setState(() => _assigneeIds[index] = v);
                      },
                      isReadOnly: isReadOnly,
                    ),
                  ],
                ),
            ],
          ),
          SizedBox(height: 14.h),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Target Date',
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w500,
                  color: isReadOnly ? Colors.grey.shade500 : Color(0xFF64748B),
                ),
              ),
              SizedBox(height: 6.h),
              TextFormField(
                key: ValueKey('upd_date_${index}_${point.id}'),
                controller: _dateControllers[index],
                readOnly: true,
                maxLines: 1,
                style: TextStyle(
                  fontSize: 14.sp,
                  color: isReadOnly ? Colors.grey.shade600 : Color(0xFF1E293B),
                ),
                onTap: isReadOnly ? null : () => _pickDate(index),
                decoration: InputDecoration(
                  hintText: 'Select date',
                  hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13.sp),
                  suffixIcon: Icon(
                    Icons.arrow_drop_down,
                    color: isReadOnly ? Colors.grey.shade400 : Colors.grey.shade400,
                  ),
                  filled: true,
                  fillColor: isReadOnly ? Colors.grey.shade100 : Color(0xFFF8FAFC),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: BorderSide(color: Color(0xFF2563EB), width: 1.5),
                  ),
                  contentPadding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
                ),
                validator: isReadOnly ? null : (v) {
                  if (v == null || v.trim().isEmpty) {
                    return 'Target date required';
                  }
                  return null;
                },
              ),
            ],
          ),
          SizedBox(height: 14.h),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Status',
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w500,
                  color: isReadOnly && !isCompleted ? Colors.grey.shade500 : Color(0xFF64748B),
                ),
              ),
              SizedBox(height: 6.h),
              // Status remains editable even for completed items?
              // If you want to prevent status changes after completion, uncomment the condition below
              // and comment the current _buildStatusDropdown call
              /*
              if (isCompleted)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Text(
                    currentStatus ?? 'Completed',
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: Colors.grey.shade700,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                )
              else
                _buildStatusDropdown(context, index, point),
              */
              // This version allows status changes even for completed items (to revert if needed)
              _buildStatusDropdown(context, index, point),
            ],
          ),
          // Add a visual indicator for read-only mode
          //
          // if (isCompleted && !_isRole93)
          //   Padding(
          //     padding: EdgeInsets.only(top: 12.h),
          //     child: Container(
          //       padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
          //       decoration: BoxDecoration(
          //         color: Colors.green.shade50,
          //         borderRadius: BorderRadius.circular(8.r),
          //         border: Border.all(color: Colors.green.shade200),
          //       ),
          //       child: Row(
          //         children: [
          //           Icon(Icons.check_circle_outline, size: 14.sp, color: Colors.green.shade700),
          //           SizedBox(width: 8.w),
          //           Expanded(
          //             child: Text(
          //               'This action point has been completed. Now Admin can only change the status',
          //               style: TextStyle(
          //                 fontSize: 11.sp,
          //                 color: Colors.green.shade700,
          //                 fontWeight: FontWeight.w500,
          //               ),
          //             ),
          //           ),
          //         ],
          //       ),
          //     ),
          //   ),
        ],
      ),
    );
  }
  Future<void> _submit() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      _showErrorMessage('Please fill all required fields');
      return;
    }

    final details = widget.viewModel.details;

    if (details.isEmpty) {
      _showErrorMessage('No action points');
      return;
    }

    // validate assignee
    for (int i = 0; i < details.length; i++) {
      final isCompleted = _isStatusComplete(_selectedStatuses[i]);

      if (!isCompleted && (_assigneeIds[i] ?? '').isEmpty) {
        _showErrorMessage('Select assignee for item ${i + 1}');
        return;
      }
    }

    if (_remarkController.text.trim().isEmpty) {
      _showErrorMessage('Remark required');
      return;
    }

    // loader
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    final items = <ActionPointItem>[];

    for (int i = 0; i < details.length; i++) {
      final orig = details[i];
      final wasCompleted = _isStatusComplete(_originalStatuses[i]);

      /// ✅ FINAL FIX (NO FALLBACK BUG)
      final finalAssignee = (_isRole93 || wasCompleted)
          ? orig.assignedTo
          : int.tryParse(_assigneeIds[i] ?? '');

      items.add(
        ActionPointItem(
          id: orig.id,
          description: (_isRole93 || wasCompleted)
              ? (orig.description ?? '')
              : _descControllers[i].text.trim(),
          targetDate: (_isRole93 || wasCompleted)
              ? (orig.targetDate ?? '')
              : _dateControllers[i].text.trim(),
          assignedTo: finalAssignee?.toString(),
          status: _selectedStatuses[i],
        ),
      );
    }

    try {
      final ok = await widget.viewModel.bulkUpdateActionPoints(
        actionPoints: items,
        remark: _remarkController.text.trim(),
        newAttachmentPaths: _newAttachmentPaths,
      );



      if (!mounted) return;

      if (ok) {
        _showSuccessMessage("Updated successfully");
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => DashbordView()),
              (route) => false,
        );

        await widget.viewModel.fetchActionPointView(widget.meetingId);


        setState(() {
          _syncControllersFromViewModel();
          _initializeSelectedStatuses();
        });

      } else {
        _showErrorMessage("Update failed");
      }
    } catch (e) {
      Navigator.pop(context);
      _showErrorMessage("Error: $e");
    }
  }

  @override
  void dispose() {
    for (final c in _descControllers) {
      c.dispose();
    }
    for (final c in _dateControllers) {
      c.dispose();
    }
    _remarkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = widget.viewModel;
    final meeting = vm.meeting;
    final details = vm.details;

    return Scaffold(
      backgroundColor: Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          _isRole93 ? 'View Action Points' : 'Edit Action Points',
          style: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.3,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Color(0xFF1E293B),
        elevation: 0,
        centerTitle: false,
      ),
      body: vm.isLoading && details.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildMeetingHeader(meeting),
              SizedBox(height: 20.h),
              _buildAttachmentsSection(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Action Points',
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                    decoration: BoxDecoration(
                      color: Color(0xFF2563EB).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20.r),
                    ),
                    child: Text(
                      '${details.length} items',
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2563EB),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12.h),
              if (details.isEmpty)
                Container(
                  padding: EdgeInsets.all(32.r),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16.r),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.inbox_outlined, size: 48.sp, color: Colors.grey.shade400),
                      SizedBox(height: 12.h),
                      Text(
                        'No Action Points',
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        'This meeting has no action points to edit',
                        style: TextStyle(
                          fontSize: 13.sp,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ],
                  ),
                )
              else
                ...List.generate(details.length, (index) {
                  return Padding(
                    padding: EdgeInsets.only(bottom: 16.h),
                    child: _buildActionPointCard(context, index, details[index]),
                  );
                }),
              SizedBox(height: 16.h),

              // SINGLE REMARK HISTORY SECTION
              _buildRemarkHistorySection(meeting),
              SizedBox(height: 16.h),

              // Add Remark Section (Remains editable for role 93)
              Container(
                padding: EdgeInsets.all(16.r),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFieldLabel('Add a Remark', Icons.comment_outlined),
                    SizedBox(height: 8.h),
                    TextFormField(
                      controller: _remarkController,
                      maxLines: 3,
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: Color(0xFF1E293B),
                        fontWeight: FontWeight.w400,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Add a remark for these updates...',
                        hintStyle: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w400,
                        ),
                        filled: true,
                        fillColor: Color(0xFFF8FAFC),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.r),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.r),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12.r),
                          borderSide: BorderSide(color: Color(0xFF2563EB), width: 1.5),
                        ),
                        contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Remark is required';
                        }
                        if (v.trim().length < 3) {
                          return 'Remark must be at least 3 characters';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
              SizedBox(height: 24.h),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submitting || details.isEmpty ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF10B981),
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 16.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14.r),
                    ),
                    elevation: 0,
                    disabledBackgroundColor: Colors.grey.shade300,
                  ),
                  child: Text(
                    'Save Changes',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 32.h),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _onDeleteAttachment(int index) async {
    final attachment = _existingAttachments[index];

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r),
          ),
          title: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.red),
              SizedBox(width: 8.w),
              Text("Delete Attachment"),
            ],
          ),
          content: Text(
            "Are you sure you want to delete this attachment?\n\nThis action cannot be undone.",
            style: TextStyle(fontSize: 13.sp),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text("Cancel"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.r),
                ),
              ),
              onPressed: () => Navigator.pop(context, true),
              child: Text("Delete"),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    final success = await widget.viewModel.deleteAttachment(
      meetingId: widget.meetingId,
      attachmentId: int.tryParse(attachment.id ?? "0") ?? 0,
    );

    if (success) {
      setState(() {
        _existingAttachments.removeAt(index);
      });
      _showSuccessMessage("Attachment deleted successfully");
    } else {
      _showErrorMessage(
        widget.viewModel.deleteMessage ?? "Failed to delete attachment",
      );
    }
  }
  Widget _buildSearchableDropdown({
    required BuildContext context,
    required String? value,
    required List<emp.Data> items,
    required String hint,
    required Function(String?) onChanged,
    required bool isReadOnly,
  }) {
    // Find selected employee
    final selectedEmployee = items.firstWhere(
          (e) => e.id?.toString() == value,
      orElse: () => emp.Data(),
    );

    return GestureDetector(
      onTap: isReadOnly
          ? null
          : () {
        _showEmployeeSearchDialog(
          context: context,
          items: items,
          currentValue: value,
          onSelected: (val) {
            if (!isReadOnly) {
              onChanged(val); // 🔥 ensure update happens
            }
          },
        );
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: isReadOnly ? Colors.grey.shade100 : Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: isReadOnly ? Colors.grey.shade200 : Colors.transparent,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                selectedEmployee.employeeName ?? hint,
                style: TextStyle(
                  fontSize: 14.sp,
                  color: selectedEmployee.id != null
                      ? Color(0xFF1E293B)
                      : Colors.grey.shade400,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(
              Icons.arrow_drop_down,
              color: isReadOnly ? Colors.grey.shade400 : Color(0xFF2563EB),
              size: 20.sp,
            ),
          ],
        ),
      ),
    );
  }
  // Widget _buildSearchableDropdown({
  //   required BuildContext context,
  //   required String? value,
  //   required List<emp.Data> items,
  //   required String hint,
  //   required Function(String?) onChanged,
  //   required bool isReadOnly,
  // }) {
  //   final selectedEmployee = items.firstWhere(
  //         (e) => e.id?.toString() == value,
  //     orElse: () => emp.Data(),
  //   );
  //
  //   return GestureDetector(
  //     onTap: isReadOnly ? null : () {
  //       _showEmployeeSearchDialog(
  //         context: context,
  //         items: items,
  //         currentValue: value,
  //         onSelected: onChanged,
  //       );
  //     },
  //     child: Container(
  //       padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
  //       decoration: BoxDecoration(
  //         color: isReadOnly ? Colors.grey.shade100 : Color(0xFFF8FAFC),
  //         borderRadius: BorderRadius.circular(12.r),
  //         border: Border.all(
  //           color: isReadOnly ? Colors.grey.shade200 : Colors.transparent,
  //         ),
  //       ),
  //       child: Row(
  //         children: [
  //           Expanded(
  //             child: Text(
  //               selectedEmployee.employeeName ?? hint,
  //               style: TextStyle(
  //                 fontSize: 14.sp,
  //                 color: selectedEmployee.id != null
  //                     ? Color(0xFF1E293B)
  //                     : Colors.grey.shade400,
  //               ),
  //               overflow: TextOverflow.ellipsis,
  //             ),
  //           ),
  //           Icon(
  //             Icons.arrow_drop_down,
  //             color: isReadOnly ? Colors.grey.shade400 : Color(0xFF2563EB),
  //             size: 20.sp,
  //           ),
  //         ],
  //       ),
  //     ),
  //   );
  // }

  void _showEmployeeSearchDialog({
    required BuildContext context,
    required List<emp.Data> items,
    required String? currentValue,
    required Function(String?) onSelected,
  }) {
    final TextEditingController searchController = TextEditingController();
    String searchQuery = '';

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            final filteredItems = searchQuery.isEmpty
                ? items
                : items.where((item) {
              final employeeName = item.employeeName?.toLowerCase() ?? '';
              return employeeName.contains(searchQuery.toLowerCase());
            }).toList();

            return Dialog(
              backgroundColor: Colors.transparent,
              elevation: 0,
              child: Container(
                height: MediaQuery.of(context).size.height * 0.65,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28.r),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Header with drag indicator
                    Container(
                      padding: EdgeInsets.only(top: 16.h, bottom: 8.h),
                      child: Column(
                        children: [
                          Container(
                            width: 40.w,
                            height: 4.h,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade300,
                              borderRadius: BorderRadius.circular(2.r),
                            ),
                          ),
                          SizedBox(height: 12.h),
                          Text(
                            'Select Employee',
                            style: TextStyle(
                              fontSize: 18.sp,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Search Bar
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(16.r),
                          border: Border.all(
                            color: searchQuery.isNotEmpty ? Color(0xFF6366F1) : Colors.grey.shade200,
                            width: 1.5,
                          ),
                        ),
                        child: TextField(
                          controller: searchController,
                          autofocus: true,
                          style: TextStyle(fontSize: 15.sp),
                          decoration: InputDecoration(
                            hintText: 'Search employees...',
                            hintStyle: TextStyle(
                              fontSize: 14.sp,
                              color: Colors.grey.shade400,
                            ),
                            prefixIcon: Icon(
                              Icons.search_rounded,
                              size: 20.sp,
                              color: searchQuery.isNotEmpty ? Color(0xFF6366F1) : Colors.grey.shade400,
                            ),
                            suffixIcon: searchQuery.isNotEmpty
                                ? GestureDetector(
                              onTap: () {
                                searchController.clear();
                                setState(() {
                                  searchQuery = '';
                                });
                              },
                              child: Container(
                                margin: EdgeInsets.all(8.r),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade200,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.close_rounded,
                                  size: 16.sp,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            )
                                : null,
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 14.h),
                          ),
                          onChanged: (value) {
                            setState(() {
                              searchQuery = value;
                            });
                          },
                        ),
                      ),
                    ),

                    // Employee List
                    Expanded(
                      child: filteredItems.isEmpty
                          ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 80.w,
                              height: 80.w,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade50,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.search_off_rounded,
                                size: 40.sp,
                                color: Colors.grey.shade400,
                              ),
                            ),
                            SizedBox(height: 16.h),
                            Text(
                              'No employees found',
                              style: TextStyle(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            SizedBox(height: 4.h),
                            Text(
                              'Try adjusting your search',
                              style: TextStyle(
                                fontSize: 13.sp,
                                color: Colors.grey.shade400,
                              ),
                            ),
                          ],
                        ),
                      )
                          : ListView.builder(
                        padding: EdgeInsets.symmetric(horizontal: 12.w),
                        itemCount: filteredItems.length,
                        itemBuilder: (context, index) {
                          final employee = filteredItems[index];
                          final isSelected = employee.id?.toString() == currentValue;

                          return Container(
                            margin: EdgeInsets.only(bottom: 8.h),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? Color(0xFF6366F1).withOpacity(0.05)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(16.r),
                              border: Border.all(
                                color: isSelected
                                    ? Color(0xFF6366F1).withOpacity(0.3)
                                    : Colors.grey.shade100,
                                width: 1,
                              ),
                            ),
                            child: ListTile(
                              contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
                              leading: Container(
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? Color(0xFF6366F1).withOpacity(0.15)
                                      : Colors.grey.shade100,
                                  shape: BoxShape.circle,
                                ),
                                child: CircleAvatar(
                                  backgroundColor: Colors.transparent,
                                  radius: 20.r,
                                  child: Icon(
                                    Icons.person_outline_rounded,
                                    size: 20.sp,
                                    color: isSelected ? Color(0xFF6366F1) : Colors.grey.shade500,
                                  ),
                                ),
                              ),
                              title: Text(
                                employee.employeeName ?? 'Unnamed Employee',
                                style: TextStyle(
                                  fontSize: 15.sp,
                                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                                  color: isSelected ? Color(0xFF6366F1) : Color(0xFF1E293B),
                                ),
                              ),
                              subtitle: employee.id != null
                                  ? Text(
                                employee.employeeName!,
                                style: TextStyle(
                                  fontSize: 12.sp,
                                  color: Colors.grey.shade500,
                                ),
                              )
                                  : null,
                              trailing: isSelected
                                  ? Container(
                                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 5.h),
                                decoration: BoxDecoration(
                                  color: Color(0xFF6366F1).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20.r),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.check_circle_rounded,
                                      size: 16.sp,
                                      color: Color(0xFF6366F1),
                                    ),
                                    SizedBox(width: 4.w),
                                    Text(
                                      'Selected',
                                      style: TextStyle(
                                        fontSize: 11.sp,
                                        fontWeight: FontWeight.w500,
                                        color: Color(0xFF6366F1),
                                      ),
                                    ),
                                  ],
                                ),
                              )
                                  : null,
                              onTap: () {
                                Navigator.pop(dialogContext);
                                onSelected(employee.id?.toString());
                              },
                            ),
                          );
                        },
                      ),
                    ),

                    // Cancel Button
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
                      child: GestureDetector(
                        onTap: () => Navigator.pop(dialogContext),
                        child: Container(
                          width: double.infinity,
                          height: 48.h,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(16.r),
                            border: Border.all(
                              color: Colors.grey.shade200,
                              width: 1,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              'Cancel',
                              style: TextStyle(
                                fontSize: 15.sp,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
  // void _showEmployeeSearchDialog({
  //   required BuildContext context,
  //   required List<emp.Data> items,
  //   required String? currentValue,
  //   required Function(String?) onSelected,
  // }) {
  //   final TextEditingController searchController = TextEditingController();
  //   String searchQuery = '';
  //
  //   showDialog(
  //     context: context,
  //     builder: (dialogContext) {
  //       return StatefulBuilder(
  //         builder: (context, setState) {
  //           final filteredItems = searchQuery.isEmpty
  //               ? items
  //               : items.where((item) {
  //             final employeeName = item.employeeName?.toLowerCase() ?? '';
  //             return employeeName.contains(searchQuery.toLowerCase());
  //           }).toList();
  //
  //           return Dialog(
  //             shape: RoundedRectangleBorder(
  //               borderRadius: BorderRadius.circular(20.r),
  //             ),
  //             child: Container(
  //               height: MediaQuery.of(context).size.height * 0.7,
  //               padding: EdgeInsets.all(16.r),
  //               child: Column(
  //                 children: [
  //                   TextField(
  //                     controller: searchController,
  //                     autofocus: true,
  //                     decoration: InputDecoration(
  //                       hintText: 'Search employees...',
  //                       hintStyle: TextStyle(fontSize: 13.sp, color: Colors.grey.shade400),
  //                       prefixIcon: Icon(Icons.search, size: 20.sp, color: Colors.grey.shade500),
  //                       suffixIcon: searchQuery.isNotEmpty
  //                           ? IconButton(
  //                         icon: Icon(Icons.clear, size: 18.sp),
  //                         onPressed: () {
  //                           searchController.clear();
  //                           setState(() {
  //                             searchQuery = '';
  //                           });
  //                         },
  //                       )
  //                           : null,
  //                       border: OutlineInputBorder(
  //                         borderRadius: BorderRadius.circular(12.r),
  //                         borderSide: BorderSide(color: Colors.grey.shade300),
  //                       ),
  //                       enabledBorder: OutlineInputBorder(
  //                         borderRadius: BorderRadius.circular(12.r),
  //                         borderSide: BorderSide(color: Colors.grey.shade300),
  //                       ),
  //                       focusedBorder: OutlineInputBorder(
  //                         borderRadius: BorderRadius.circular(12.r),
  //                         borderSide: BorderSide(color: Color(0xFF2563EB), width: 1.5),
  //                       ),
  //                       contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
  //                     ),
  //                     onChanged: (value) {
  //                       setState(() {
  //                         searchQuery = value;
  //                       });
  //                     },
  //                   ),
  //                   SizedBox(height: 16.h),
  //                   Expanded(
  //                     child: filteredItems.isEmpty
  //                         ? Center(
  //                       child: Column(
  //                         mainAxisAlignment: MainAxisAlignment.center,
  //                         children: [
  //                           Icon(Icons.search_off, size: 48.sp, color: Colors.grey.shade400),
  //                           SizedBox(height: 12.h),
  //                           Text(
  //                             'No employees found',
  //                             style: TextStyle(
  //                               fontSize: 14.sp,
  //                               color: Colors.grey.shade500,
  //                             ),
  //                           ),
  //                         ],
  //                       ),
  //                     )
  //                         : ListView.builder(
  //                       itemCount: filteredItems.length,
  //                       itemBuilder: (context, index) {
  //                         final employee = filteredItems[index];
  //                         final isSelected = employee.id?.toString() == currentValue;
  //
  //                         return ListTile(
  //                           leading: CircleAvatar(
  //                             backgroundColor: isSelected
  //                                 ? Color(0xFF2563EB).withOpacity(0.1)
  //                                 : Colors.grey.shade100,
  //                             radius: 16.r,
  //                             child: Icon(
  //                               Icons.person,
  //                               size: 16.sp,
  //                               color: isSelected ? Color(0xFF2563EB) : Colors.grey.shade500,
  //                             ),
  //                           ),
  //                           title: Text(
  //                             employee.employeeName ?? '',
  //                             style: TextStyle(
  //                               fontSize: 14.sp,
  //                               fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
  //                               color: isSelected ? Color(0xFF2563EB) : Color(0xFF1E293B),
  //                             ),
  //                           ),
  //                           trailing: isSelected
  //                               ? Icon(Icons.check_circle, size: 18.sp, color: Color(0xFF10B981))
  //                               : null,
  //                           onTap: () {
  //                             Navigator.pop(dialogContext);
  //                             onSelected(employee.id?.toString());
  //                           },
  //                         );
  //                       },
  //                     ),
  //                   ),
  //                   SizedBox(height: 12.h),
  //                   TextButton(
  //                     onPressed: () => Navigator.pop(dialogContext),
  //                     child: Text(
  //                       'Cancel',
  //                       style: TextStyle(
  //                         fontSize: 14.sp,
  //                         color: Colors.grey.shade600,
  //                       ),
  //                     ),
  //                   ),
  //                 ],
  //               ),
  //             ),
  //           );
  //         },
  //       );
  //     },
  //   );
  // }

  // Future<String?> _buildEmployeeSearchDialog({
  //   required BuildContext context,
  //   required List<emp.Data> items,
  //   required String? currentValue,
  // }) async {
  //   final TextEditingController searchController = TextEditingController();
  //   String searchQuery = '';
  //
  //   return showDialog<String>(
  //     context: context,
  //     builder: (dialogContext) {
  //       return StatefulBuilder(
  //         builder: (context, setState) {
  //           final filteredItems = searchQuery.isEmpty
  //               ? items
  //               : items.where((item) {
  //             final employeeName = item.employeeName?.toLowerCase() ?? '';
  //             return employeeName.contains(searchQuery.toLowerCase());
  //           }).toList();
  //
  //           return Dialog(
  //             shape: RoundedRectangleBorder(
  //               borderRadius: BorderRadius.circular(20.r),
  //             ),
  //             child: Container(
  //               height: MediaQuery.of(context).size.height * 0.7,
  //               padding: EdgeInsets.all(16.r),
  //               child: Column(
  //                 children: [
  //                   TextField(
  //                     controller: searchController,
  //                     autofocus: true,
  //                     decoration: InputDecoration(
  //                       hintText: 'Search employees...',
  //                       hintStyle: TextStyle(fontSize: 13.sp, color: Colors.grey.shade400),
  //                       prefixIcon: Icon(Icons.search, size: 20.sp, color: Colors.grey.shade500),
  //                       suffixIcon: searchQuery.isNotEmpty
  //                           ? IconButton(
  //                         icon: Icon(Icons.clear, size: 18.sp),
  //                         onPressed: () {
  //                           searchController.clear();
  //                           setState(() {
  //                             searchQuery = '';
  //                           });
  //                         },
  //                       )
  //                           : null,
  //                       border: OutlineInputBorder(
  //                         borderRadius: BorderRadius.circular(12.r),
  //                         borderSide: BorderSide(color: Colors.grey.shade300),
  //                       ),
  //                       enabledBorder: OutlineInputBorder(
  //                         borderRadius: BorderRadius.circular(12.r),
  //                         borderSide: BorderSide(color: Colors.grey.shade300),
  //                       ),
  //                       focusedBorder: OutlineInputBorder(
  //                         borderRadius: BorderRadius.circular(12.r),
  //                         borderSide: BorderSide(color: Color(0xFF2563EB), width: 1.5),
  //                       ),
  //                       contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
  //                     ),
  //                     onChanged: (value) {
  //                       setState(() {
  //                         searchQuery = value;
  //                       });
  //                     },
  //                   ),
  //                   SizedBox(height: 16.h),
  //                   Expanded(
  //                     child: filteredItems.isEmpty
  //                         ? Center(
  //                       child: Column(
  //                         mainAxisAlignment: MainAxisAlignment.center,
  //                         children: [
  //                           Icon(Icons.search_off, size: 48.sp, color: Colors.grey.shade400),
  //                           SizedBox(height: 12.h),
  //                           Text(
  //                             'No employees found',
  //                             style: TextStyle(
  //                               fontSize: 14.sp,
  //                               color: Colors.grey.shade500,
  //                             ),
  //                           ),
  //                         ],
  //                       ),
  //                     )
  //                         : ListView.builder(
  //                       itemCount: filteredItems.length,
  //                       itemBuilder: (context, index) {
  //                         final employee = filteredItems[index];
  //                         final isSelected = employee.id?.toString() == currentValue;
  //
  //                         return ListTile(
  //                           leading: CircleAvatar(
  //                             backgroundColor: isSelected
  //                                 ? Color(0xFF2563EB).withOpacity(0.1)
  //                                 : Colors.grey.shade100,
  //                             radius: 16.r,
  //                             child: Icon(
  //                               Icons.person,
  //                               size: 16.sp,
  //                               color: isSelected ? Color(0xFF2563EB) : Colors.grey.shade500,
  //                             ),
  //                           ),
  //                           title: Text(
  //                             employee.employeeName ?? '',
  //                             style: TextStyle(
  //                               fontSize: 14.sp,
  //                               fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
  //                               color: isSelected ? Color(0xFF2563EB) : Color(0xFF1E293B),
  //                             ),
  //                           ),
  //                           trailing: isSelected
  //                               ? Icon(Icons.check_circle, size: 18.sp, color: Color(0xFF10B981))
  //                               : null,
  //                           onTap: () {
  //                             Navigator.pop(context, employee.id?.toString());
  //                           },
  //                         );
  //                       },
  //                     ),
  //                   ),
  //                   SizedBox(height: 12.h),
  //                   TextButton(
  //                     onPressed: () => Navigator.pop(context),
  //                     child: Text(
  //                       'Cancel',
  //                       style: TextStyle(
  //                         fontSize: 14.sp,
  //                         color: Colors.grey.shade600,
  //                       ),
  //                     ),
  //                   ),
  //                 ],
  //               ),
  //             ),
  //           );
  //         },
  //       );
  //     },
  //   );
  // }
}