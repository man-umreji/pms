import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import '../../meating_screen/model/meating_model.dart';
import '../model/generate_action_point_ai_model.dart';
import '../model/get_active_project_model.dart';
import '../model/get_user_list_model.dart';
import '../model/meating_action_point_model.dart';
import '../view_mode/meating_action_point_view_model.dart';
import 'package:speech_to_text/speech_to_text.dart';
class MeetingActionPointView extends StatefulWidget {
  const MeetingActionPointView({super.key});

  @override
  State<MeetingActionPointView> createState() =>
      _MeetingActionPointViewState();
}

class _MeetingActionPointViewState extends State<MeetingActionPointView> {
  late stt.SpeechToText _speech;
  bool _isListening = false;
  String _text = '';
  double _soundLevel = 0.0;
  String finalText = "";
  String currentText = "";
  bool _isRestarting = false;

  Timer? _silenceTimer;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _initSpeech();

    Future.microtask(() {
      final vm = context.read<MeatingActionPointViewModel>();
      vm.fetchMeetingTypes();
      vm.fetchActiveProjects();
      vm.fetchAllStatus();
      vm.fetchUserList();
    });
  }

  void _initSpeech() {
    _speech = stt.SpeechToText();
  }
  void _restartListening(TextEditingController controller) {
    if (!_isListening || _isRestarting) return;

    _isRestarting = true;

    Future.delayed(const Duration(milliseconds: 400), () async {
      print(" Restarting mic...");

      try {
        await _speech.stop();
      } catch (_) {}

      _isRestarting = false;

      if (_isListening) {
        _startListening(controller);
      }
    });
  }

  void _startListening(TextEditingController controller) async {
    if (_speech.isListening) return;

    print("Starting...");

    bool available = await _speech.initialize(
      onStatus: (status) {
        print("STATUS: $status");
        if ((status == 'done' || status == 'notListening') && _isListening) {
          _restartListening(controller);
        }
      },
      onError: (error) {
        print("ERROR: $error");
        _restartListening(controller);
      },
    );

    if (!available) {
      print(" Mic not available");
      return;
    }
    await _speech.stop();
    await Future.delayed(const Duration(milliseconds: 200));

    setState(() => _isListening = true);

    _speech.listen(
      onResult: (result) {
        if (result.finalResult) {
          controller.text =
              (controller.text + " " + result.recognizedWords).trim();

          controller.selection = TextSelection.fromPosition(
            TextPosition(offset: controller.text.length),
          );
        }
      },
      partialResults: true,
      localeId: 'en_US',
      cancelOnError: false,
    );
  }
  void _stopListening() {
    _isRestarting = false;

    if (_isListening) {
      _speech.stop();

      setState(() {
        _isListening = false;
        currentText = "";
      });
    }
  }

  String? _validateMeetingType(MeatingActionPointViewModel vm) {
    if (vm.selectedMeetingType == null) {
      return "Please select a meeting type";
    }
    return null;
  }

  String? _validateProject(MeatingActionPointViewModel vm) {
    if (vm.isProjectMeetingSelected && vm.selectedProject == null) {
      return "Please select a project";
    }
    return null;
  }

  String? _validateMeetingDate(MeatingActionPointViewModel vm) {
    if (vm.dateController.text.trim().isEmpty) {
      return "Please select meeting date";
    }
    return null;
  }

  String? _validateMeetingNotes(MeatingActionPointViewModel vm) {
    final text = vm.notesController.text.trim();
    //
    // if (text.isEmpty) {
    //   return "Please enter meeting notes";
    // }

    // if (text.length < 10) {
    //   return "Meeting notes should be at least 10 characters";
    // }

    return null;
  }

  String? _validateActionPoints(MeatingActionPointViewModel vm) {

    // 🔥 NEW: Meeting type validation
    if (vm.selectedMeetingType == null) {
      return "Please select a meeting type";
    }

    // // 🔥 Optional: ensure at least one action point exists
    // if (vm.actionPoints.isEmpty) {
    //   return "Please generate or add at least one action point";
    // }

    // 🔥 Duplicate check
    if (vm.hasDuplicates()) {
      final duplicates = vm.getDuplicateDescriptions();
      return "Duplicate action points found: ${duplicates.take(2).join(", ")}${duplicates.length > 2 ? "..." : ""}";
    }

    // 🔥 Validate each action point
    for (int i = 0; i < vm.actionPoints.length; i++) {
      final point = vm.actionPoints[i];

      if (point.description == null || point.description!.trim().isEmpty) {
        return "Action point ${i + 1} has no description";
      }

      final assignedId = point.assignedToId;
      if (assignedId == null || assignedId.isEmpty) {
        return "Please assign an employee to action point ${i + 1}";
      }
    }

    return null;
  }

  String? _validateCCEmail(String? email) {
    if (email == null || email.trim().isEmpty) {
      return null;
    }

    final emailRegex =
    RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');

    // Split by comma
    final emails = email.split(',');

    for (var e in emails) {
      final trimmedEmail = e.trim();

      if (trimmedEmail.isEmpty) continue;

      if (!emailRegex.hasMatch(trimmedEmail)) {
        return "Please enter valid email addresses (comma separated)";
      }
    }

    return null;
  }

  Future<bool> _validateAndSubmit(MeatingActionPointViewModel vm) async {
    vm.clearFormErrors();
    // vm.clearCCRecipients();

    List<String> errors = [];

    final meetingTypeError = _validateMeetingType(vm);
    if (meetingTypeError != null) errors.add(meetingTypeError);

    final projectError = _validateProject(vm);
    if (projectError != null) errors.add(projectError);

    final dateError = _validateMeetingDate(vm);
    if (dateError != null) errors.add(dateError);

    final notesError = _validateMeetingNotes(vm);
    if (notesError != null) errors.add(notesError);

    final actionPointsError = _validateActionPoints(vm);
    if (actionPointsError != null) errors.add(actionPointsError);

    final ccEmailError = _validateCCEmail(vm.ccController.text);
    if (ccEmailError != null) errors.add(ccEmailError);

    if (errors.isNotEmpty) {
      _showValidationDialog(errors);
      return false;
    }

    final freshVm = context.read<MeatingActionPointViewModel>(); // 🔥 FIX

    await freshVm.createActionPoint(
      projectId: freshVm.selectedProject?.id ?? "1",
      context: context,
    );

    return true;
  }

  void _showValidationDialog(List<String> errors) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange.shade700),
            SizedBox(width: 10.w),
            Text(
              "Validation Errors",
              style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Container(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Please fix the following issues:",
                style: TextStyle(fontSize: 14.sp, color: Colors.grey.shade700),
              ),
              SizedBox(height: 16.h),
              ...errors.map((error) => Padding(
                padding: EdgeInsets.only(bottom: 8.h),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.error, color: Colors.red.shade400, size: 16.sp),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: Text(
                        error,
                        style: TextStyle(fontSize: 13.sp, color: Colors.grey.shade800),
                      ),
                    ),
                  ],
                ),
              )),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              "OK",
              style: TextStyle(color: Colors.blue.shade700, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: _buildAppBar(),
      body: Consumer<MeatingActionPointViewModel>(
        builder: (context, vm, child) {
          if (vm.isLoading) {
            return _buildLoadingState();
          }

          if (vm.error != null) {
            return _buildErrorState(vm.error!);
          }

          return SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 16.h),
                  _buildHeaderSection(),
                  SizedBox(height: 24.h),
                  Container(
                    margin: EdgeInsets.symmetric(horizontal: 16.w),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20.r),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.shade200,
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 24.h),

                        _buildModernLabel("Meeting Type *", Icons.meeting_room),
                        _buildModernDropdownMeeting(vm),
                        if (vm.isProjectMeetingSelected) ...[
                          _buildDivider(),
                          _buildModernLabel("Project *", Icons.folder),
                          _buildProjectDropdown(vm),
                          _buildDivider(),
                          _buildModernLabel("Project Manager Name", Icons.person),
                          _buildModernTextField(
                            TextEditingController(
                              text:
                              "${vm.projectManagerNameController.text}"
                                  "${vm.projectManagerEmailController.text.isNotEmpty ? " (${vm.projectManagerEmailController.text})" : ""}",
                            ),
                            "Project Manager Name",
                            prefixIcon: Icons.person,
                            readOnly: true,
                          ),
                        ],
                        _buildDivider(),

                        _buildModernLabel("Meeting Date *", Icons.calendar_today),
                        _buildModernDateField(
                          vm.dateController,
                              (apiDate) {
                            vm.setApiDate(apiDate);
                          },
                        ),

                        _buildDivider(),
                        _buildModernLabel("Mail ID for CC (Optional)", Icons.person),

                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
                          child: _buildUserDropdown(vm),
                        ),
                        // _buildModernTextField(vm.ccController, "Enter email address",
                        //     prefixIcon: Icons.email_outlined,
                        //     validator: (value) => _validateCCEmail(value)),

                        _buildDivider(),

                        _buildModernLabel("Meeting Notes *", Icons.description),
                        _buildModernVoiceTextField(vm.notesController, "Record or type meeting notes..."),

                        SizedBox(height: 24.h),

                        _buildGenerateButton(vm),

                        SizedBox(height: 16.h),

                        if (vm.isAiLoading) _buildAiLoadingIndicator(),
                        if (vm.aiError != null) _buildAiError(vm.aiError!),

                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
                          child: Row(
                            children: [
                              Expanded(
                                child: _buildModernLabel("Manual Action Points", Icons.add_task),
                              ),
                              GestureDetector(
                                onTap: () => _showAddActionPointDialog(vm),
                                child: Container(
                                  padding: EdgeInsets.all(8.r),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [Colors.green.shade500, Colors.green.shade700],
                                    ),
                                    borderRadius: BorderRadius.circular(12.r),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.add, color: Colors.white, size: 18.sp),
                                      SizedBox(width: 4.w),
                                      Text(
                                        "Add New",
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 12.sp,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        if (vm.actionPoints.isNotEmpty) ...[
                          SizedBox(height: 8.h),
                          _buildActionPointsHeader(vm),
                          _buildModernActionPointsList(vm),
                        ],

                        SizedBox(height: 24.h),

                        _buildAttachmentsSection(vm),

                        SizedBox(height: 32.h),

                        _buildSaveButton(vm),

                        SizedBox(height: 24.h),
                      ],
                    ),
                  ),
                  SizedBox(height: 30.h),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _showAddActionPointDialog(MeatingActionPointViewModel vm) {
    final descriptionController = TextEditingController();
    DateTime? selectedDate;
    Data? selectedEmployee;
    final dialogFormKey = GlobalKey<FormState>();

    bool _isDuplicate(String description, String? assignedToId) {
      return vm.actionPoints.any((point) =>
      point.description?.trim().toLowerCase() == description.trim().toLowerCase() &&
          point.assignedToId == assignedToId);
    }

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(28.r),
              ),
              elevation: 0,
              backgroundColor: Colors.transparent,
              child: SingleChildScrollView(
                child: Form(
                  key: dialogFormKey,
                  child: Container(
                    width: MediaQuery.of(context).size.width * 0.85,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(28.r),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 30,
                          offset: const Offset(0, 15),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: EdgeInsets.all(24.r),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Color(0xFF0F766E),
                                Color(0xFF0D9488),
                                Color(0xFF14B8A6),
                              ],
                            ),
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(28.r),
                              topRight: Radius.circular(28.r),
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: EdgeInsets.all(12.r),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(16.r),
                                ),
                                child: Icon(
                                  Icons.add_rounded,
                                  color: Colors.white,
                                  size: 24.sp,
                                ),
                              ),
                              SizedBox(width: 16.w),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Create New Action",
                                      style: TextStyle(
                                        fontSize: 20.sp,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                        letterSpacing: -0.3,
                                      ),
                                    ),
                                    SizedBox(height: 4.h),
                                    Text(
                                      "Add a task to track progress",
                                      style: TextStyle(
                                        fontSize: 13.sp,
                                        color: Colors.white.withOpacity(0.85),
                                        letterSpacing: -0.2,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              GestureDetector(
                                onTap: () => Navigator.pop(context),
                                child: Container(
                                  padding: EdgeInsets.all(8.r),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(12.r),
                                  ),
                                  child: Icon(
                                    Icons.close_rounded,
                                    color: Colors.white,
                                    size: 18.sp,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        Padding(
                          padding: EdgeInsets.all(24.r),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Description Field
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        "Description",
                                        style: TextStyle(
                                          fontSize: 14.sp,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF1F2937),
                                        ),
                                      ),
                                      SizedBox(width: 4.w),
                                      Text(
                                        "*",
                                        style: TextStyle(
                                          fontSize: 14.sp,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFFEF4444),
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 8.h),
                                  Container(
                                    decoration: BoxDecoration(
                                      color: Color(0xFFF9FAFB),
                                      borderRadius: BorderRadius.circular(14.r),
                                      border: Border.all(color: Color(0xFFE5E7EB)),
                                    ),
                                    child: TextFormField(
                                      controller: descriptionController,
                                      maxLines: 3,
                                      style: TextStyle(
                                        fontSize: 14.sp,
                                        color: Color(0xFF1F2937),
                                      ),
                                      validator: (value) {
                                        if (value == null || value.trim().isEmpty) {
                                          return "Please enter action description";
                                        }
                                        if (value.trim().length < 5) {
                                          return "Description must be at least 5 characters";
                                        }
                                        if (selectedEmployee != null &&
                                            _isDuplicate(value, selectedEmployee!.id)) {
                                          return "This action point already exists for this employee";
                                        }
                                        return null;
                                      },
                                      onChanged: (value) {
                                        if (selectedEmployee != null &&
                                            _isDuplicate(value, selectedEmployee!.id)) {
                                          dialogFormKey.currentState?.validate();
                                        }
                                      },
                                      decoration: InputDecoration(
                                        hintText: "What needs to be done?",
                                        hintStyle: TextStyle(
                                          color: Color(0xFF9CA3AF),
                                          fontSize: 14.sp,
                                        ),
                                        border: InputBorder.none,
                                        contentPadding: EdgeInsets.all(14.r),
                                        prefixIcon: Padding(
                                          padding: EdgeInsets.all(12.r),
                                          child: Icon(
                                            Icons.edit_note_rounded,
                                            color: Color(0xFF0D9488),
                                            size: 20.sp,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 20.h),

                              // Assignee Field
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        "Assign To",
                                        style: TextStyle(
                                          fontSize: 14.sp,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF1F2937),
                                        ),
                                      ),
                                      SizedBox(width: 4.w),
                                      Text(
                                        "*",
                                        style: TextStyle(
                                          fontSize: 14.sp,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFFEF4444),
                                        ),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 8.h),
                                  Container(
                                    decoration: BoxDecoration(
                                      color: Color(0xFFF9FAFB),
                                      borderRadius: BorderRadius.circular(14.r),
                                      border: Border.all(color: Color(0xFFE5E7EB)),
                                    ),
                                    child: _buildSearchableEmployeeDropdown(
                                      vm: vm,
                                      selectedEmployee: selectedEmployee,
                                      onChanged: (value) {
                                        setState(() {
                                          selectedEmployee = value;
                                        });
                                        dialogFormKey.currentState?.validate();
                                      },
                                      validator: (value) {
                                        if (value == null) {
                                          return "Please assign to a team member";
                                        }
                                        if (descriptionController.text.trim().isNotEmpty &&
                                            _isDuplicate(descriptionController.text, value.id)) {
                                          return "This action point already exists for this employee";
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 10.h),

                              // Target Date Card
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Target Date",
                                    style: TextStyle(
                                      fontSize: 14.sp,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF1F2937),
                                    ),
                                  ),
                                  SizedBox(height: 8.h),
                                  GestureDetector(
                                    onTap: () async {
                                      final picked = await showDatePicker(
                                        context: context,
                                        initialDate: DateTime.now(),
                                        firstDate: DateTime.now(),
                                        lastDate: DateTime(2035),
                                        builder: (context, child) {
                                          return Theme(
                                            data: Theme.of(context).copyWith(
                                              colorScheme: ColorScheme.light(
                                                primary: Color(0xFF0D9488),
                                                onPrimary: Colors.white,
                                                surface: Colors.white,
                                                onSurface: Colors.black,
                                              ),
                                              dialogBackgroundColor: Colors.white,
                                            ),
                                            child: child!,
                                          );
                                        },
                                      );
                                      if (picked != null) {
                                        setState(() {
                                          selectedDate = picked;
                                        });
                                      }
                                    },
                                    child: Container(
                                      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
                                      decoration: BoxDecoration(
                                        color: Color(0xFFF9FAFB),
                                        borderRadius: BorderRadius.circular(14.r),
                                        border: Border.all(color: Color(0xFFE5E7EB)),
                                      ),
                                      child: Row(
                                        children: [
                                          Container(
                                            padding: EdgeInsets.all(10.r),
                                            decoration: BoxDecoration(
                                              color: Color(0xFFE6F7F5),
                                              borderRadius: BorderRadius.circular(12.r),
                                            ),
                                            child: Icon(
                                              Icons.calendar_today_rounded,
                                              color: Color(0xFF0D9488),
                                              size: 18.sp,
                                            ),
                                          ),
                                          SizedBox(width: 14.w),
                                          Expanded(
                                            child: Text(
                                              selectedDate != null
                                                  ? _formatDate(selectedDate!)
                                                  : "No deadline set",
                                              style: TextStyle(
                                                fontSize: 14.sp,
                                                fontWeight: FontWeight.w500,
                                                color: selectedDate != null
                                                    ? Color(0xFF1F2937)
                                                    : Color(0xFF9CA3AF),
                                              ),
                                            ),
                                          ),
                                          Icon(
                                            Icons.keyboard_arrow_down_rounded,
                                            color: Color(0xFF0D9488),
                                            size: 20.sp,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        Container(
                          padding: EdgeInsets.all(20.r),
                          decoration: BoxDecoration(
                            border: Border(
                              top: BorderSide(color: Color(0xFFE5E7EB), width: 1),
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () => Navigator.pop(context),
                                  style: OutlinedButton.styleFrom(
                                    padding: EdgeInsets.symmetric(vertical: 12.h),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12.r),
                                    ),
                                    side: BorderSide(color: Color(0xFFD1D5DB)),
                                    foregroundColor: Color(0xFF6B7280),
                                  ),
                                  child: Text(
                                    "Cancel",
                                    style: TextStyle(
                                      fontSize: 15.sp,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(width: 12.w),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () {
                                    if (dialogFormKey.currentState!.validate()) {
                                      final description = descriptionController.text.trim();
                                      final assignedToId = selectedEmployee?.id;

                                      if (_isDuplicate(description, assignedToId)) {
                                        _showCustomSnackBar(
                                          context,
                                          "This action point already exists for this employee!",
                                          Colors.orange,
                                        );
                                        return;
                                      }

                                      final apiDate = selectedDate != null
                                          ? "${selectedDate!.year}-${selectedDate!.month.toString().padLeft(2, '0')}-${selectedDate!.day.toString().padLeft(2, '0')}"
                                          : null;

                                      bool success = vm.addManualActionPoint(
                                        description: description,
                                        assignedToId: assignedToId,
                                        targetDate: apiDate,
                                      );

                                      if (success) {
                                        Navigator.pop(context);
                                        _showCustomSnackBar(
                                          context,
                                          "Action point created successfully!",
                                          Color(0xFF10B981),
                                        );
                                      } else {
                                        _showCustomSnackBar(
                                          context,
                                          "Duplicate action point not added",
                                          Colors.orange,
                                        );
                                      }
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Color(0xFF0D9488),
                                    padding: EdgeInsets.symmetric(vertical: 12.h),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12.r),
                                    ),
                                    elevation: 0,
                                    foregroundColor: Colors.white,
                                  ),
                                  child: Text(
                                    "Create Action",
                                    style: TextStyle(
                                      fontSize: 15.sp,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSearchableEmployeeDropdown({
    required MeatingActionPointViewModel vm,
    required Data? selectedEmployee,
    required void Function(Data?) onChanged,
    required String? Function(Data?) validator,
  }) {
    String searchQuery = '';

    return StatefulBuilder(
      builder: (context, setState) {
        List<Data> filteredEmployees = vm.employees;

        if (searchQuery.isNotEmpty) {
          filteredEmployees = vm.employees.where((emp) {
            final name = (emp.employeeName ?? "").toLowerCase();
            final query = searchQuery.toLowerCase();
            return name.contains(query);
          }).toList();
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(14.r),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.search, size: 20.sp, color: Colors.blue.shade600),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: TextField(
                      autofocus: false,
                      decoration: InputDecoration(
                        hintText: "Search by name...",
                        hintStyle: TextStyle(
                          fontSize: 13.sp,
                          color: Colors.grey.shade500,
                        ),
                        border: InputBorder.none,
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(vertical: 12.h),
                      ),
                      onChanged: (value) {
                        setState(() {
                          searchQuery = value;
                        });
                      },
                    ),
                  ),
                  if (searchQuery.isNotEmpty)
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          searchQuery = '';
                        });
                      },
                      child: Container(
                        padding: EdgeInsets.all(4.r),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.close,
                          size: 14.sp,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            SizedBox(height: 12.h),

            GestureDetector(
              onTap: () {
                _showEmployeeSelectionSheet(context, vm, filteredEmployees, selectedEmployee, onChanged);
              },
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(14.r),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  children: [
                    if (selectedEmployee != null)
                      Container(
                        width: 32.r,
                        height: 32.r,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.blue.shade400,
                              Colors.blue.shade700,
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                        child: Center(
                          child: Text(
                            (selectedEmployee.employeeName?.isNotEmpty == true
                                ? selectedEmployee.employeeName![0].toUpperCase()
                                : 'U'),
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    if (selectedEmployee != null) SizedBox(width: 12.w),
                    Expanded(
                      child: Text(
                        selectedEmployee?.employeeName ?? "Select team member *",
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: selectedEmployee != null ? Colors.grey.shade800 : Colors.grey.shade500,
                          fontWeight: selectedEmployee != null ? FontWeight.w500 : FontWeight.normal,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.arrow_drop_down,
                      color: Colors.blue.shade600,
                      size: 28.sp,
                    ),
                  ],
                ),
              ),
            ),
            if (validator(selectedEmployee) != null)
              Padding(
                padding: EdgeInsets.only(top: 8.h, left: 12.w),
                child: Text(
                  validator(selectedEmployee)!,
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: Colors.red.shade600,
                  ),
                ),
              ),

            if (filteredEmployees.isEmpty && searchQuery.isNotEmpty)
              Padding(
                padding: EdgeInsets.only(top: 8.h),
                child: Container(
                  padding: EdgeInsets.all(12.r),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 16.sp,
                        color: Colors.orange.shade700,
                      ),
                      SizedBox(width: 8.w),
                      Expanded(
                        child: Text(
                          "No employees found matching '$searchQuery'",
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: Colors.orange.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  void _showEmployeeSelectionSheet(
      BuildContext context,
      MeatingActionPointViewModel vm,
      List<Data> employees,
      Data? selectedEmployee,
      void Function(Data?) onChanged,
      ) {
    String searchQuery = '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            List<Data> filteredList = employees;

            if (searchQuery.isNotEmpty) {
              filteredList = employees.where((emp) {
                final name = (emp.employeeName ?? "").toLowerCase();
                final query = searchQuery.toLowerCase();
                return name.contains(query);
              }).toList();
            }

            return Container(
              height: MediaQuery.of(context).size.height * 0.7,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24.r),
                  topRight: Radius.circular(24.r),
                ),
              ),
              child: Column(
                children: [
                  Container(
                    margin: EdgeInsets.only(top: 12.h),
                    width: 40.w,
                    height: 4.h,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2.r),
                    ),
                  ),

                  Container(
                    padding: EdgeInsets.all(20.r),
                    child: Column(
                      children: [
                        Text(
                          "Select Team Member",
                          style: TextStyle(
                            fontSize: 20.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade800,
                          ),
                        ),
                        SizedBox(height: 16.h),

                        Container(
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(14.r),
                            border: Border.all(color: Colors.grey.shade200),
                          ),
                          child: TextField(
                            autofocus: false,
                            onChanged: (value) {
                              setState(() {
                                searchQuery = value;
                              });
                            },
                            decoration: InputDecoration(
                              hintText: "Search by name...",
                              hintStyle: TextStyle(color: Colors.grey.shade500),
                              prefixIcon: Icon(Icons.search, color: Colors.blue.shade600),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 16.w,
                                vertical: 14.h,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  Expanded(
                    child: filteredList.isEmpty
                        ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.person_off,
                            size: 48.sp,
                            color: Colors.grey.shade400,
                          ),
                          SizedBox(height: 12.h),
                          Text(
                            "No employees found",
                            style: TextStyle(
                              fontSize: 16.sp,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    )
                        : ListView.builder(
                      padding: EdgeInsets.symmetric(horizontal: 16.w),
                      itemCount: filteredList.length,
                      itemBuilder: (context, index) {
                        final employee = filteredList[index];
                        final isSelected = selectedEmployee?.id == employee.id;

                        return GestureDetector(
                          onTap: () {
                            onChanged(employee);
                            Navigator.pop(context);
                          },
                          child: Container(
                            margin: EdgeInsets.only(bottom: 8.h),
                            padding: EdgeInsets.all(12.r),
                            decoration: BoxDecoration(
                              color: isSelected ? Colors.blue.shade50 : Colors.white,
                              borderRadius: BorderRadius.circular(14.r),
                              border: Border.all(
                                color: isSelected ? Colors.blue.shade300 : Colors.grey.shade200,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 48.r,
                                  height: 48.r,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.blue.shade400,
                                        Colors.blue.shade700,
                                      ],
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                    ),
                                    borderRadius: BorderRadius.circular(14.r),
                                  ),
                                  child: Center(
                                    child: Text(
                                      (employee.employeeName?.isNotEmpty == true
                                          ? employee.employeeName![0].toUpperCase()
                                          : 'U'),
                                      style: TextStyle(
                                        fontSize: 18.sp,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(width: 12.w),

                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        employee.employeeName ?? "Unknown",
                                        style: TextStyle(
                                          fontSize: 16.sp,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.grey.shade800,
                                        ),
                                      ),
                                      if (employee.employeeName != null && employee.employeeName!.isNotEmpty)
                                        Text(
                                          employee.employeeName ?? "",
                                          style: TextStyle(
                                            fontSize: 12.sp,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),

                                if (isSelected)
                                  Icon(
                                    Icons.check_circle,
                                    color: Colors.green.shade600,
                                    size: 24.sp,
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showCustomSnackBar(BuildContext context, String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              color == Colors.green ? Icons.check_circle : Icons.warning,
              color: Colors.white,
              size: 20,
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Text(
                message,
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
        margin: EdgeInsets.all(16.r),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  Widget _buildProjectDropdown(MeatingActionPointViewModel vm) {
    final uniqueProjects = <GetActiveProjectData>[];
    final seenIds = <String>{};

    for (var project in vm.projects) {
      final id = project.id;
      if (id != null && !seenIds.contains(id)) {
        seenIds.add(id);
        uniqueProjects.add(project);
      }
    }

    GetActiveProjectData? validSelectedProject;
    if (vm.selectedProject != null && vm.selectedProject!.id != null) {
      validSelectedProject = uniqueProjects.firstWhere(
            (project) => project.id == vm.selectedProject!.id,
        orElse: () => uniqueProjects.isNotEmpty ? uniqueProjects.first : null as GetActiveProjectData,
      );
    }

    if (uniqueProjects.isEmpty) {
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
        child: Container(
          padding: EdgeInsets.all(16.r),
          decoration: BoxDecoration(
            color: Colors.orange.shade50,
            borderRadius: BorderRadius.circular(14.r),
            border: Border.all(color: Colors.orange.shade200),
          ),
          child: Row(
            children: [
              Icon(Icons.warning, color: Colors.orange.shade700, size: 20.sp),
              SizedBox(width: 12.w),
              Expanded(
                child: Text(
                  "No projects available",
                  style: TextStyle(fontSize: 14.sp, color: Colors.orange.shade700),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          border: Border.all(color: Colors.grey.shade200),
          borderRadius: BorderRadius.circular(14.r),
        ),
        child: DropdownButtonFormField<GetActiveProjectData>(
          value: validSelectedProject,
          hint: Padding(
            padding: EdgeInsets.only(left: 12.w),
            child: Text(
              "Select project *",
              style: TextStyle(color: Colors.grey.shade500, fontSize: 14.sp),
            ),
          ),
          isExpanded: true,
          validator: (value) {
            if (vm.isProjectMeetingSelected && value == null) {
              return "Please select a project";
            }
            return null;
          },
          items: uniqueProjects.map((project) {
            return DropdownMenuItem<GetActiveProjectData>(
              value: project,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 12.w),
                child: Text(
                  project.name ?? "",
                  style: TextStyle(fontSize: 14.sp),
                ),
              ),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              vm.setSelectedProject(value);
            }
          },
          decoration: const InputDecoration(
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
          icon: Icon(Icons.arrow_drop_down, color: Colors.blue.shade700),
          dropdownColor: Colors.white,
          borderRadius: BorderRadius.circular(14.r),
        ),
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      leading: Padding(
        padding: EdgeInsets.only(left: 18.w),
        child: GestureDetector(
            onTap: () {
              context.read<MeatingActionPointViewModel>().clearForm();
              Navigator.pop(context);
            },
            child: Icon(Icons.arrow_back_ios, color: Colors.white)),
      ),
      title: Text(
        "Action Points",
        style: TextStyle(
          fontSize: 24.sp,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue.shade800, Colors.blue.shade600, Colors.blue.shade400],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: const BorderRadius.vertical(
            bottom: Radius.circular(25),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderSection() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w),
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade700, Colors.blue.shade500, Colors.blue.shade400],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.shade200,
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(12.r),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(15.r),
            ),
            child: Icon(
              Icons.auto_awesome,
              color: Colors.white,
              size: 28.sp,
            ),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "AI Action Generator",
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  "Transform meeting notes into actionable tasks",
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernLabel(String text, IconData icon) {
    return Padding(
      padding: EdgeInsets.only(left: 20.w, right: 20.w, bottom: 8.h),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(4.r),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Icon(icon, size: 16.sp, color: Colors.blue.shade700),
          ),
          SizedBox(width: 8.w),
          Text(
            text,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade800,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernDropdownMeeting(MeatingActionPointViewModel vm) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          border: Border.all(color: Colors.grey.shade200),
          borderRadius: BorderRadius.circular(14.r),
        ),
        child: DropdownButtonFormField<MeetingType>(
          value: vm.meetingTypes.contains(vm.selectedMeetingType)
              ? vm.selectedMeetingType
              : null,
          hint: Padding(
            padding: EdgeInsets.only(left: 12.w),
            child: Text(
              "Choose meeting type *",
              style: TextStyle(color: Colors.grey.shade500, fontSize: 14.sp),
            ),
          ),
          isExpanded: true,
          validator: (value) {
            if (value == null) {
              return "Please select a meeting type";
            }
            return null;
          },
          items: vm.meetingTypes.map((type) {
            return DropdownMenuItem(
              value: type,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 12.w),
                child: Text(
                  type.name ?? "",
                  style: TextStyle(fontSize: 14.sp),
                ),
              ),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              vm.setSelectedMeetingType(value);
            }
          },
          decoration: InputDecoration(
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
          ),
          icon: Icon(Icons.arrow_drop_down, color: Colors.blue.shade700),
          dropdownColor: Colors.white,
          borderRadius: BorderRadius.circular(14.r),
        ),
      ),
    );
  }

  Widget _buildModernDateField(TextEditingController controller,
      Function(String apiDate)? onDateSelected) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
      child: TextFormField(
        controller: controller,
        readOnly: true,
        validator: (value) {
          if (value == null || value.isEmpty) {
            return "Please select meeting date";
          }
          return null;
        },
        // onTap: () async {
        //   final DateTime? pickedDate = await showDatePicker(
        //     context: context,
        //     firstDate: DateTime.now(),
        //     lastDate: DateTime(2030),
        //     builder: (context, child) {
        //       return Theme(
        //         data: Theme.of(context).copyWith(
        //           colorScheme: ColorScheme.light(
        //             primary: Colors.blue.shade700,
        //             onPrimary: Colors.white,
        //           ),
        //         ),
        //         child: child!,
        //       );
        //     },
        //   );
        //
        //   if (pickedDate != null) {
        //     String uiDate = "${pickedDate.day.toString().padLeft(2, '0')}/"
        //         "${pickedDate.month.toString().padLeft(2, '0')}/"
        //         "${pickedDate.year}";
        //
        //     String apiDate = "${pickedDate.year}-"
        //         "${pickedDate.month.toString().padLeft(2, '0')}-"
        //         "${pickedDate.day.toString().padLeft(2, '0')}";
        //
        //     controller.text = uiDate;
        //
        //     if (onDateSelected != null) {
        //       onDateSelected(apiDate);
        //     }
        //   }
        // },
        onTap: () async {
          final DateTime now = DateTime.now();

          final DateTime? pickedDate = await showDatePicker(
            context: context,
            initialDate: now,
            firstDate: DateTime(2000), // allow past from 2000 (change if needed)
            lastDate: now,
            builder: (context, child) {
              return Theme(
                data: Theme.of(context).copyWith(
                  colorScheme: ColorScheme.light(
                    primary: Colors.blue.shade700,
                    onPrimary: Colors.white,
                  ),
                ),
                child: child!,
              );
            },
          );

          if (pickedDate != null) {
            String uiDate = "${pickedDate.day.toString().padLeft(2, '0')}/"
                "${pickedDate.month.toString().padLeft(2, '0')}/"
                "${pickedDate.year}";

            String apiDate = "${pickedDate.year}-"
                "${pickedDate.month.toString().padLeft(2, '0')}-"
                "${pickedDate.day.toString().padLeft(2, '0')}";

            controller.text = uiDate;

            if (onDateSelected != null) {
              onDateSelected(apiDate);
            }
          }
        },
        decoration: InputDecoration(
          hintText: "Select date *",
          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14.sp),
          prefixIcon: Icon(Icons.calendar_today, color: Colors.blue.shade700, size: 20.sp),
          filled: true,
          fillColor: Colors.grey.shade50,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14.r),
            borderSide: BorderSide.none,
          ),
          contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
        ),
      ),
    );
  }
  Widget _buildUserDropdown(MeatingActionPointViewModel vm) {
    return GestureDetector(
        onTap: () async {
          final selected = await _showUserSelectionSheet(context, vm);

          if (selected != null) {
            vm.setSelectedUsers(selected); // 🔥 THIS IS THE MISSING LINE
          }
        },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          border: Border.all(color: Colors.grey.shade200),
          borderRadius: BorderRadius.circular(14.r),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Label
            Row(
              children: [
                Icon(Icons.alternate_email, color: Colors.blue, size: 18.sp),
                SizedBox(width: 8.w),
                Text(
                  "Select CC Mail IDs",
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),

            SizedBox(height: 8.h),

            // Selected users or placeholder
            GestureDetector(
              onTap: () async {
                final selected = await _showUserSelectionSheet(context, vm);
                if (selected != null) {
                  vm.setSelectedUsers(selected);
                }
              },
              child: vm.selectedUsers.isEmpty
                  ? Container(
                padding: EdgeInsets.symmetric(vertical: 8.h),
                child: Row(
                  children: [
                    Icon(Icons.add_circle_outline,
                        color: Colors.blue.shade400,
                        size: 18.sp),
                    SizedBox(width: 8.w),
                    Text(
                      "Add CC recipients",
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: Colors.blue.shade400,
                      ),
                    ),
                  ],
                ),
              )
                  : Wrap(
                spacing: 8.w,
                runSpacing: 8.h,
                children: vm.selectedUsers.map((user) {
                  return Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 12.w,
                      vertical: 6.h,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20.r),
                      border: Border.all(
                        color: Colors.blue.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.email,
                          size: 14.sp,
                          color: Colors.blue.shade700,
                        ),
                        SizedBox(width: 6.w),
                        ConstrainedBox(
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.5,
                          ),
                          child: Text(
                            user.email ?? "",
                            style: TextStyle(
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w500,
                              color: Colors.blue.shade700,
                            ),
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                          ),
                        ),
                        SizedBox(width: 6.w),
                        InkWell(
                          onTap: () {
                            final updated = List<UserListData>.from(vm.selectedUsers)
                              ..remove(user);
                            vm.setSelectedUsers(updated);
                          },
                          child: Container(
                            padding: EdgeInsets.all(2.r),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.close,
                              size: 12.sp,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),

            // Optional: Show selected count
            if (vm.selectedUsers.isNotEmpty)
              Padding(
                padding: EdgeInsets.only(top: 8.h),
                child: Text(
                  "${vm.selectedUsers.length} recipient${vm.selectedUsers.length > 1 ? 's' : ''} selected",
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: Colors.grey.shade500,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
  Future<List<UserListData>?> _showUserSelectionSheet(
      BuildContext context,
      MeatingActionPointViewModel vm,
      ) {
    String searchQuery = '';
    List<UserListData> selectedUsers = List.from(vm.selectedUsers); // Initialize with existing selected users

    return showModalBottomSheet<List<UserListData>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            List<UserListData> filtered = vm.userDataList;

            if (searchQuery.isNotEmpty) {
              filtered = vm.userDataList.where((user) {
                final name = (user.name ?? "").toLowerCase();
                final email = (user.email ?? "").toLowerCase();
                final query = searchQuery.toLowerCase();

                return name.contains(query) || email.contains(query);
              }).toList();
            }

            return Container(
              height: MediaQuery.of(context).size.height * 0.8,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28.r)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: Offset(0, -2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Drag handle
                  Container(
                    margin: EdgeInsets.only(top: 12.h),
                    width: 40.w,
                    height: 4.h,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2.r),
                    ),
                  ),

                  SizedBox(height: 16.h),

                  // Header with close button
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20.w),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Select CC Recipients",
                          style: TextStyle(
                            fontSize: 20.sp,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[800],
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.close, color: Colors.grey[600]),
                          onPressed: () => Navigator.pop(context),
                          padding: EdgeInsets.zero,
                          constraints: BoxConstraints(),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(height: 16.h),

                  // Search field with chip design
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20.w),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(16.r),
                        border: Border.all(color: Colors.grey[200]!),
                      ),
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: "Search by name or email",
                          hintStyle: TextStyle(
                            fontSize: 14.sp,
                            color: Colors.grey[400],
                          ),
                          prefixIcon: Icon(Icons.search, color: Colors.grey[500], size: 20.sp),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16.w,
                            vertical: 14.h,
                          ),
                        ),
                        onChanged: (value) {
                          setState(() {
                            searchQuery = value;
                          });
                        },
                      ),
                    ),
                  ),

                  SizedBox(height: 20.h),

                  // Selected count indicator with clear all button
                  if (selectedUsers.isNotEmpty)
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20.w),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
                            decoration: BoxDecoration(
                              color: Colors.blue[50],
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.check_circle, color: Colors.blue[600], size: 18.sp),
                                SizedBox(width: 8.w),
                                Text(
                                  "${selectedUsers.length} selected",
                                  style: TextStyle(
                                    fontSize: 13.sp,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.blue[700],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              setState(() {
                                selectedUsers.clear();
                              });
                            },
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.symmetric(horizontal: 8.w),
                              minimumSize: Size(0, 0),
                            ),
                            child: Text(
                              "Clear All",
                              style: TextStyle(
                                fontSize: 12.sp,
                                color: Colors.red.shade400,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  SizedBox(height: 12.h),

                  // User list
                  Expanded(
                    child: filtered.isEmpty
                        ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.people_outline, size: 64.sp, color: Colors.grey[300]),
                          SizedBox(height: 12.h),
                          Text(
                            "No users found",
                            style: TextStyle(
                              fontSize: 16.sp,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    )
                        : ListView.builder(
                      padding: EdgeInsets.symmetric(horizontal: 8.w),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final user = filtered[index];
                        final isSelected = selectedUsers.any((selected) => selected.id == user.id); // Use ID for comparison

                        return Card(
                          margin: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r),
                            side: BorderSide(
                              color: isSelected ? Colors.blue : Colors.grey[200]!,
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: ListTile(
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 16.w,
                              vertical: 4.h,
                            ),
                            leading: CircleAvatar(
                              backgroundColor: isSelected ? Colors.blue[50] : Colors.grey[100],
                              child: Text(
                                (user.name?.isNotEmpty == true
                                    ? user.name![0].toUpperCase()
                                    : (user.email?.isNotEmpty == true ? user.email![0].toUpperCase() : '?')),
                                style: TextStyle(
                                  color: isSelected ? Colors.blue[600] : Colors.grey[600],
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            title: Text(
                              user.name ?? "No Name",
                              style: TextStyle(
                                fontSize: 15.sp,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey[800],
                              ),
                            ),
                            subtitle: Text(
                              user.email ?? "",
                              style: TextStyle(
                                fontSize: 13.sp,
                                color: Colors.grey[600],
                              ),
                            ),
                            trailing: Container(
                              width: 24.w,
                              height: 24.w,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isSelected ? Colors.blue : Colors.transparent,
                                border: Border.all(
                                  color: isSelected ? Colors.blue : Colors.grey[400]!,
                                  width: 2,
                                ),
                              ),
                              child: isSelected
                                  ? Icon(Icons.check, size: 16.sp, color: Colors.white)
                                  : null,
                            ),
                            onTap: () {
                              setState(() {
                                if (isSelected) {
                                  selectedUsers.removeWhere((selected) => selected.id == user.id);
                                } else {
                                  selectedUsers.add(user);
                                }
                              });
                            },
                          ),
                        );
                      },
                    ),
                  ),

                  // Action buttons
                  Container(
                    padding: EdgeInsets.all(20.w),
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(color: Colors.grey[100]!, width: 1),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              padding: EdgeInsets.symmetric(vertical: 14.h),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14.r),
                              ),
                              side: BorderSide(color: Colors.grey[300]!),
                            ),
                            child: Text(
                              "Cancel",
                              style: TextStyle(
                                fontSize: 15.sp,
                                color: Colors.grey[700],
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context, selectedUsers);
                            },
                            style: ElevatedButton.styleFrom(
                              padding: EdgeInsets.symmetric(vertical: 14.h),
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14.r),
                              ),
                              elevation: 0,
                            ),
                            child: Text(
                              "Done ${selectedUsers.isNotEmpty ? "(${selectedUsers.length})" : ""}",
                              style: TextStyle(
                                fontSize: 15.sp,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
  Widget _buildModernTextField(
      TextEditingController controller,
      String hint, {
        IconData? prefixIcon,
        bool readOnly = false,
        String? Function(String?)? validator,
      }) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
      child: TextFormField(
        controller: controller,
        readOnly: readOnly,
        validator: validator,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14.sp),
          prefixIcon: prefixIcon != null
              ? Icon(prefixIcon, color: Colors.blue.shade700, size: 20.sp)
              : null,
          filled: true,
          fillColor: readOnly ? Colors.grey.shade100 : Colors.grey.shade50,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14.r),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14.r),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14.r),
            borderSide: BorderSide(
              color: readOnly ? Colors.grey : Colors.blue.shade700,
              width: 2,
            ),
          ),
          contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
        ),
      ),
    );
  }

  Widget _buildModernVoiceTextField(TextEditingController controller, String hint) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            decoration: BoxDecoration(
              color: _isListening ? Colors.blue.shade50 : Colors.grey.shade50,
              border: Border.all(
                color: _isListening ? Colors.blue.shade400 : Colors.grey.shade200,
                width: _isListening ? 2 : 1,
              ),
              borderRadius: BorderRadius.circular(16.r),
              boxShadow: _isListening
                  ? [
                BoxShadow(
                  color: Colors.blue.shade200,
                  blurRadius: 15,
                  spreadRadius: 2,
                ),
              ]
                  : [],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_isListening) ...[
                  Padding(
                    padding: EdgeInsets.only(top: 12.h, left: 16.w, right: 16.w),
                    child: _buildSoundWaveVisualization(),
                  ),
                  SizedBox(height: 8.h),
                  Container(
                    margin: EdgeInsets.symmetric(horizontal: 16.w),
                    height: 1,
                    color: Colors.blue.shade200,
                  ),
                ],
                Stack(
                  children: [
                    TextFormField(
                      controller: controller,
                      maxLines: 5,
                      minLines: 3,
                      style: TextStyle(fontSize: 14.sp),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return "Please enter meeting notes";
                        }
                        if (value.trim().length < 10) {
                          return "Meeting notes should be at least 10 characters";
                        }
                        return null;
                      },
                      decoration: InputDecoration(
                        hintText: "$hint *",
                        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14.sp),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.only(
                          right: 60.w,
                          left: 16.w,
                          top: 14.h,
                          bottom: 14.h,
                        ),
                      ),
                    ),
                    Positioned(
                      right: 8,
                      bottom: 8,
                      child: GestureDetector(
                        onTap: () {
                          if (_isListening) {
                            _stopListening();
                          } else {
                            _startListening(controller);
                          }
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: EdgeInsets.all(12.r),
                          decoration: BoxDecoration(
                            gradient: _isListening
                                ? LinearGradient(
                              colors: [Colors.red.shade500, Colors.red.shade700],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                                : LinearGradient(
                              colors: [Colors.blue.shade500, Colors.blue.shade700],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: (_isListening ? Colors.red : Colors.blue).withOpacity(0.4),
                                blurRadius: 12,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: Icon(
                            _isListening ? Icons.mic : Icons.mic_none,
                            color: Colors.white,
                            size: 22.sp,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                if (_isListening) ...[
                  Padding(
                    padding: EdgeInsets.only(left: 16.w, right: 16.w, bottom: 12.h),
                    child: Row(
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 500),
                          width: 8.w,
                          height: 8.h,
                          decoration: BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                        ),
                        SizedBox(width: 8.w),
                        Text(
                          "Recording...",
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: Colors.red.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          "Tap mic to stop",
                          style: TextStyle(
                            fontSize: 11.sp,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSoundWaveVisualization() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(20, (index) {
        // 🎯 create continuous animation even if soundLevel = 0
        final time = DateTime.now().millisecondsSinceEpoch / 200;
        final wave = (index + time) % 10;

        double height;

        if (_isListening) {
          // combine sound + animation
          height = 12 +
              (_soundLevel * 2) +   // real mic input
              (wave * 2);           // animation movement
        } else {
          height = 10;
        }

        return AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          margin: EdgeInsets.symmetric(horizontal: 2.w),
          width: 3.w,
          height: height.clamp(10, 50),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.blue.shade400,
                Colors.blue.shade700,
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(3.r),
          ),
        );
      }),
    );
  }

  Widget _buildGenerateButton(MeatingActionPointViewModel vm) {
    final busy = vm.isAiLoading;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Opacity(
        opacity: busy ? 0.55 : 1,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue.shade600, Colors.blue.shade800],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(14.r),
            boxShadow: [
              BoxShadow(
                color: Colors.blue.shade300,
                blurRadius: 15,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ElevatedButton(
            onPressed: busy
                ? null
                : () async {

              // ================= VALIDATIONS =================

              // 🔥 1. Meeting Type
              if (vm.selectedMeetingType == null) {
                _showCustomSnackBar(
                  context,
                  "Please select meeting type",
                  Colors.orange,
                );
                return;
              }

              // 🔥 2. Meeting Notes
              final notes = vm.notesController.text.trim();

              if (notes.isEmpty) {
                _showCustomSnackBar(
                  context,
                  "Please enter meeting notes",
                  Colors.orange,
                );
                return;
              }

              if (notes.length < 5) {
                _showCustomSnackBar(
                  context,
                  "Meeting notes should be at least 5 characters",
                  Colors.orange,
                );
                return;
              }
              if (vm.dateController.text.trim().isEmpty) {
                _showCustomSnackBar(
                  context,
                  "Please select meeting date",
                  Colors.orange,
                );
                return;
              }
              await vm.generateActionPoints(
                meetingNotes: notes,
                meetingDate: vm.dateController.text,
                projectId: vm.selectedProject?.id ?? "1",
              );
              vm.notesController.clear();
            },

            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              padding: EdgeInsets.symmetric(vertical: 14.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14.r),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.auto_awesome, size: 22.sp, color: Colors.white),
                SizedBox(width: 10.w),
                Text(
                  'Generate Action Points',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionPointsHeader(MeatingActionPointViewModel vm) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(6.r),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Icon(Icons.checklist, color: Colors.green.shade700, size: 18.sp),
          ),
          SizedBox(width: 10.w),
          Text(
            "Action Points",
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade800,
              letterSpacing: 0.3,
            ),
          ),
          const Spacer(),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Text(
              "${vm.actionPoints.length} items",
              style: TextStyle(
                fontSize: 12.sp,
                color: Colors.blue.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernActionPointsList(MeatingActionPointViewModel vm) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: vm.actionPoints.length,
        separatorBuilder: (context, index) => SizedBox(height: 12.h),
        itemBuilder: (context, index) {
          final point = vm.actionPoints[index];
          final isDuplicate = vm.hasDuplicates();

          return TweenAnimationBuilder(
            duration: Duration(milliseconds: 300 + (index * 50)),
            tween: Tween<double>(begin: 0, end: 1),
            builder: (context, value, child) {
              return Opacity(
                opacity: value,
                child: Transform.translate(
                  offset: Offset(0, 20 * (1 - value)),
                  child: child,
                ),
              );
            },
            child: Container(
              padding: EdgeInsets.all(16.r),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDuplicate
                      ? [Colors.red.shade50, Colors.red.shade100]
                      : [Colors.white, Colors.grey.shade50],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14.r),
                border: Border.all(
                  color: isDuplicate ? Colors.red.shade300 : Colors.grey.shade200,
                  width: isDuplicate ? 2 : 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.shade100,
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: EdgeInsets.all(8.r),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              point.isManual == true ? Colors.green.shade400 : Colors.blue.shade400,
                              point.isManual == true ? Colors.green.shade700 : Colors.blue.shade700,
                            ],
                          ),
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                        child: Text(
                          "${index + 1}",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontSize: 12.sp,
                          ),
                        ),
                      ),
                      // manasilayo ?
                      SizedBox(width: 12.w),
                      Expanded(
                        child: TextFormField(
                          initialValue: point.description ?? "",
                          maxLines: null,
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade800,
                            height: 1.3,
                          ),
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            isDense: true,
                            hintText: "Enter action description...",
                            hintStyle: TextStyle(color: Colors.grey.shade400),
                            errorStyle: TextStyle(fontSize: 10.sp),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return "Required";
                            }
                            return null;
                          },
                          onChanged: (value) {
                            vm.updateActionPointDescription(index, value);
                          },
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          if (point.isManual == true) {
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: Text("Remove Action Point"),
                                content: Text("Are you sure you want to remove this action point?"),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: Text("Cancel"),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      vm.removeActionPoint(index);
                                      Navigator.pop(context);
                                    },
                                    child: Text("Remove", style: TextStyle(color: Colors.red)),
                                  ),
                                ],
                              ),
                            );
                          } else {
                            vm.removeActionPoint(index);
                          }
                        },
                        child: Container(
                          padding: EdgeInsets.all(6.r),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                          child: Icon(Icons.delete_outline, color: Colors.red.shade400, size: 18.sp),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 14.h),
                  Divider(
                    height: 1,
                    thickness: 1,
                    color: Colors.grey.shade200,
                  ),
                  SizedBox(height: 12.h),
                  _buildActionPointFieldLabel("Assign to employee *", Icons.person_outline),
                  _buildCompactActionPointEmployeeField(vm, index, point),
                  SizedBox(height: 12.h),
                  _buildActionPointFieldLabel("Target date", Icons.event_outlined),
                  _buildCompactActionPointDateTextField(vm, index, point),

                  if (isDuplicate) ...[
                    SizedBox(height: 8.h),
                    Container(
                      padding: EdgeInsets.all(8.r),
                      decoration: BoxDecoration(
                        color: Colors.red.shade100,
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.warning, color: Colors.red.shade700, size: 16.sp),
                          SizedBox(width: 8.w),
                          Expanded(
                            child: Text(
                              "Duplicate action point - please modify description or assignee",
                              style: TextStyle(
                                fontSize: 12.sp,
                                color: Colors.red.shade700,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  if (point.isManual == true) ...[
                    SizedBox(height: 8.h),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.add_circle, size: 10.sp, color: Colors.green.shade700),
                            SizedBox(width: 4.w),
                            Text(
                              "Manual",
                              style: TextStyle(
                                fontSize: 10.sp,
                                color: Colors.green.shade700,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildActionPointFieldLabel(String text, IconData icon) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8.h),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(4.r),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Icon(icon, size: 16.sp, color: Colors.blue.shade700),
          ),
          SizedBox(width: 8.w),
          Text(
            text,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade800,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactActionPointEmployeeField(
      MeatingActionPointViewModel vm,
      int index,
      ActionPoints point,
      ) {
    final ids = vm.employees.map((e) => e.id).toSet();
    String? value = point.assignedToId;

    // ✅ AUTO MATCH FROM DESCRIPTION
    if (value == null || value.isEmpty) {
      final noteText = (point.description ?? "").toLowerCase().trim();

      if (noteText.isNotEmpty && vm.employees.isNotEmpty) {
        for (var emp in vm.employees) {
          final empName = (emp.employeeName ?? "").toLowerCase().trim();

          if (noteText.contains(empName)) {
            value = emp.id;

            WidgetsBinding.instance.addPostFrameCallback((_) {
              vm.updateActionPointAssignee(index, value);
            });

            break;
          }
        }
      }
    }

    if (value != null && !ids.contains(value)) {
      value = null;
    }

    final isEmpty = vm.employees.isEmpty;

    if (isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.blue,
                  ),
                ),
                SizedBox(width: 12),
                Text(
                  "Loading employees...",
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
          SizedBox(height: 6),
          Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue, size: 14),
              SizedBox(width: 6),
              Expanded(
                child: Text(
                  "Please select meeting type & project",
                  style: TextStyle(color: Colors.blue),
                ),
              ),
            ],
          ),
        ],
      );
    }

    return GestureDetector(
      onTap: () async {
        final selectedId = await _showEmployeeSelectionBottomSheet(
          context,
          vm,
          value,
        );
        if (selectedId != null) {
          vm.updateActionPointAssignee(index, selectedId);
        }
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            Icon(Icons.person_outline, color: Colors.blue),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                _getEmployeeName(vm, value),
                style: TextStyle(
                  color: value != null ? Colors.black : Colors.grey,
                ),
              ),
            ),
            Icon(Icons.arrow_drop_down, color: Colors.blue),
          ],
        ),
      ),
    );
  }

  Future<String?> _showEmployeeSelectionBottomSheet(
      BuildContext context,
      MeatingActionPointViewModel vm,
      String? currentSelectedId,
      ) async {
    String? tempSelectedId = currentSelectedId;
    final TextEditingController searchController = TextEditingController();

    return showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            final query = searchController.text.toLowerCase();

            final filteredEmployees = vm.employees.where((emp) {
              final name = (emp.employeeName ?? "").toLowerCase();
              final id = (emp.id ?? "").toLowerCase();
              return name.contains(query) || id.contains(query);
            }).toList();

            return Container(
              height: MediaQuery.of(context).size.height * 0.85,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 12, bottom: 8),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),

                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Select Employee',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[800],
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () => Navigator.pop(context),
                          color: Colors.grey[600],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[200]!),
                    ),
                    child: TextField(
                      controller: searchController,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        hintText: "Search by name or ID",
                        hintStyle: TextStyle(color: Colors.grey[400]),
                        prefixIcon: Icon(Icons.search, color: Colors.grey[500]),
                        suffixIcon: searchController.text.isNotEmpty
                            ? IconButton(
                          icon: Icon(Icons.clear, color: Colors.grey[500]),
                          onPressed: () {
                            searchController.clear();
                            setState(() {});
                          },
                        )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                  Expanded(
                    child: filteredEmployees.isEmpty
                        ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.search_off,
                            size: 64,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No employees found',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[500],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Try a different search term',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[400],
                            ),
                          ),
                        ],
                      ),
                    )
                        : ListView.builder(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      itemCount: filteredEmployees.length,
                      itemBuilder: (context, index) {
                        final emp = filteredEmployees[index];
                        final isSelected = tempSelectedId == emp.id;

                        return InkWell(
                          onTap: () {
                            setState(() {
                              tempSelectedId = emp.id;
                            });
                          },
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: isSelected ? Colors.blue[50] : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                              leading: Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: isSelected ? Colors.blue[100] : Colors.grey[200],
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    _getInitials(emp.employeeName ?? ''),
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: isSelected ? Colors.blue[700] : Colors.grey[700],
                                    ),
                                  ),
                                ),
                              ),
                              title: Text(
                                emp.employeeName ?? 'Unnamed',
                                style: TextStyle(
                                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                                  fontSize: 16,
                                ),
                              ),
                              subtitle: Text(
                                'ID: ${emp.id ?? 'N/A'}',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey[600],
                                ),
                              ),
                              trailing: isSelected
                                  ? Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.blue,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.check,
                                  color: Colors.white,
                                  size: 18,
                                ),
                              )
                                  : null,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border(
                        top: BorderSide(color: Colors.grey[200]!, width: 1),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              side: BorderSide(color: Colors.grey[300]!),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              'Cancel',
                              style: TextStyle(color: Colors.grey[700]),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context, tempSelectedId);
                            },
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            child: const Text(
                              'Select',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  String _getInitials(String name) {
    if (name.isEmpty) return '?';
    final parts = name.trim().split(' ');
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return (parts[0][0] + parts[parts.length - 1][0]).toUpperCase();
  }

  String _getEmployeeName(
      MeatingActionPointViewModel vm, String? employeeId) {
    if (employeeId == null) return "Select employee *";

    final employee = vm.employees.firstWhere(
          (e) => e.id == employeeId,
      orElse: () => Data(),
    );

    return employee.employeeName ?? "Select employee *";
  }
  Widget _buildCompactActionPointDateTextField(
      MeatingActionPointViewModel vm,
      int index,
      ActionPoints point,
      ) {
    String getDisplayDate(String? apiDate) {
      if (apiDate == null || apiDate.isEmpty) return '';
      if (apiDate.contains('-') && apiDate.length == 10) {
        final parts = apiDate.split('-');
        if (parts.length == 3) {
          return '${parts[2]}/${parts[1]}/${parts[0]}';
        }
      }
      return apiDate;
    }

    DateTime? getInitialDate(String? apiDate) {
      if (apiDate == null || apiDate.isEmpty) return null;
      final parts = apiDate.split('-');
      if (parts.length == 3) {
        final year = int.tryParse(parts[0]);
        final month = int.tryParse(parts[1]);
        final day = int.tryParse(parts[2]);
        if (year != null && month != null && day != null) {
          return DateTime(year, month, day);
        }
      }
      return null;
    }

    final controller =
    TextEditingController(text: getDisplayDate(point.targetDate));

    DateTime now = DateTime.now();
    DateTime? initialDate = getInitialDate(point.targetDate);

    return TextFormField(
      controller: controller,
      readOnly: true,
      maxLines: 1,
      style: TextStyle(fontSize: 14.sp, color: Colors.grey.shade800),
      onTap: () async {
        DateTime now = DateTime.now();

        // ✅ Create a safe non-null initial date
        DateTime safeInitialDate;
        if (initialDate != null && !initialDate!.isAfter(now)) {
          safeInitialDate = initialDate!;
        } else {
          safeInitialDate = now;
        }

        final picked = await showDatePicker(
          context: context,
          initialDate: safeInitialDate,
          firstDate: DateTime(2000), // ✅ allow past
          lastDate: now,             // ❗ block future
          builder: (context, child) {
            return Theme(
              data: Theme.of(context).copyWith(
                colorScheme: ColorScheme.light(
                  primary: Colors.blue.shade700,
                  onPrimary: Colors.white,
                ),
              ),
              child: child!,
            );
          },
        );

        if (picked != null && mounted) {
          final apiDate = "${picked.year}-"
              "${picked.month.toString().padLeft(2, '0')}-"
              "${picked.day.toString().padLeft(2, '0')}";

          final displayDate = "${picked.day.toString().padLeft(2, '0')}/"
              "${picked.month.toString().padLeft(2, '0')}/"
              "${picked.year}";

          controller.text = displayDate;
          initialDate = picked;

          vm.updateActionPointTargetDate(index, apiDate);
        }
      },
      decoration: InputDecoration(
        hintText: "Select date (optional)",
        hintStyle: TextStyle(
          color: Colors.grey.shade400,
          fontSize: 14.sp,
        ),
        prefixIcon: Icon(
          Icons.calendar_today,
          color: Colors.blue.shade700,
          size: 20.sp,
        ),
        suffixIcon: Icon(
          Icons.arrow_drop_down,
          color: Colors.grey.shade400,
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14.r),
          borderSide: BorderSide.none,
        ),
        contentPadding: EdgeInsets.symmetric(
          horizontal: 16.w,
          vertical: 14.h,
        ),
      ),
    );
  }
  // Widget _buildCompactActionPointDateTextField(
  //     MeatingActionPointViewModel vm,
  //     int index,
  //     ActionPoints point,
  //     ) {
  //   String getDisplayDate(String? apiDate) {
  //     if (apiDate == null || apiDate.isEmpty) return '';
  //     if (apiDate.contains('-') && apiDate.length == 10) {
  //       final parts = apiDate.split('-');
  //       if (parts.length == 3) {
  //         return '${parts[2]}/${parts[1]}/${parts[0]}';
  //       }
  //     }
  //     return apiDate;
  //   }
  //
  //   DateTime? getInitialDate(String? apiDate) {
  //     if (apiDate == null || apiDate.isEmpty) return null;
  //     final parts = apiDate.split('-');
  //     if (parts.length == 3) {
  //       final year = int.tryParse(parts[0]);
  //       final month = int.tryParse(parts[1]);
  //       final day = int.tryParse(parts[2]);
  //       if (year != null && month != null && day != null) {
  //         return DateTime(year, month, day);
  //       }
  //     }
  //     return null;
  //   }
  //
  //   final controller = TextEditingController(text: getDisplayDate(point.targetDate));
  //   DateTime? initialDate = getInitialDate(point.targetDate);
  //
  //   return TextFormField(
  //     controller: controller,
  //     readOnly: true,
  //     maxLines: 1,
  //     style: TextStyle(fontSize: 14.sp, color: Colors.grey.shade800),
  //     onTap: () async {
  //       final picked = await showDatePicker(
  //         context: context,
  //         initialDate: initialDate ?? DateTime.now(),
  //         firstDate: DateTime.now(),
  //         lastDate: DateTime(2035),
  //         builder: (context, child) {
  //           return Theme(
  //             data: Theme.of(context).copyWith(
  //               colorScheme: ColorScheme.light(
  //                 primary: Colors.blue.shade700,
  //                 onPrimary: Colors.white,
  //               ),
  //             ),
  //             child: child!,
  //           );
  //         },
  //       );
  //
  //       if (picked != null && mounted) {
  //         final apiDate = "${picked.year}-"
  //             "${picked.month.toString().padLeft(2, '0')}-"
  //             "${picked.day.toString().padLeft(2, '0')}";
  //
  //         final displayDate = "${picked.day.toString().padLeft(2, '0')}/"
  //             "${picked.month.toString().padLeft(2, '0')}/"
  //             "${picked.year}";
  //
  //         controller.text = displayDate;
  //         initialDate = picked;
  //         vm.updateActionPointTargetDate(index, apiDate);
  //       }
  //     },
  //     decoration: InputDecoration(
  //       hintText: "Select date (optional)",
  //       hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14.sp),
  //       prefixIcon: Icon(Icons.calendar_today, color: Colors.blue.shade700, size: 20.sp),
  //       suffixIcon: Icon(Icons.arrow_drop_down, color: Colors.grey.shade400),
  //       filled: true,
  //       fillColor: Colors.grey.shade50,
  //       border: OutlineInputBorder(
  //         borderRadius: BorderRadius.circular(14.r),
  //         borderSide: BorderSide.none,
  //       ),
  //       contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
  //     ),
  //   );
  // }

  Widget _buildAttachmentsSection(MeatingActionPointViewModel vm) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildDivider(),
        _buildModernLabel("Attachments (optional)", Icons.attach_file),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "pdf, doc, docx, xls, xlsx, jpg, jpeg, png — max 3 MB per file",
                style: TextStyle(fontSize: 12.sp, color: Colors.grey.shade600),
              ),
              SizedBox(height: 10.h),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _pickAttachments(vm),
                  icon: Icon(Icons.upload_file, color: Colors.blue.shade700, size: 22.sp),
                  label: Text(
                    "Add files",
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.blue.shade700,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 16.w),
                    side: BorderSide(color: Colors.blue.shade200),
                    backgroundColor: Colors.blue.shade50,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14.r),
                    ),
                  ),
                ),
              ),
              if (vm.attachmentPaths.isNotEmpty) ...[
                SizedBox(height: 12.h),
                ...List.generate(vm.attachmentPaths.length, (i) {
                  final p = vm.attachmentPaths[i];
                  return Padding(
                    padding: EdgeInsets.only(bottom: 8.h),
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.insert_drive_file, color: Colors.blue.shade700, size: 22.sp),
                          SizedBox(width: 10.w),
                          Expanded(
                            child: Text(
                              _basename(p),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 13.sp),
                            ),
                          ),
                          IconButton(
                            tooltip: "Remove",
                            onPressed: () => vm.removeAttachmentAt(i),
                            icon: Icon(Icons.close, size: 22.sp, color: Colors.grey.shade700),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ],
          ),
        ),
      ],
    );
  }

  String _basename(String path) {
    final normalized = path.replaceAll("\\", "/");
    final i = normalized.lastIndexOf("/");
    return i >= 0 ? normalized.substring(i + 1) : path;
  }

  Future<void> _pickAttachments(MeatingActionPointViewModel vm) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const [
        "pdf",
        "doc",
        "docx",
        "xls",
        "xlsx",
        "jpg",
        "jpeg",
        "png",
      ],
      allowMultiple: true,
    );
    if (result == null || !mounted) return;
    for (final f in result.files) {
      final path = f.path;
      if (path == null) continue;
      final err = vm.addAttachmentPath(path);
      if (err != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(err)),
        );
      }
    }
  }

  Widget _buildSaveButton(MeatingActionPointViewModel vm) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.green.shade600, Colors.green.shade800],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(14.r),
          boxShadow: [
            BoxShadow(
              color: Colors.green.shade300,
              blurRadius: 15,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: vm.isCreateLoading
              ? null
              : () async {
            await _validateAndSubmit(vm);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            padding: EdgeInsets.symmetric(vertical: 14.h),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14.r),
            ),
          ),
          child: vm.isCreateLoading
              ? Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 20.w,
                height: 20.h,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              ),
              SizedBox(width: 10.w),
              Text(
                'Saving...',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          )
              : Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.save_alt, size: 20.sp, color: Colors.white),
              SizedBox(width: 10.w),
              Text(
                'Save Action Points',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(20.r),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(25.r),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.shade200,
                  blurRadius: 20,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade700),
              strokeWidth: 3,
            ),
          ),
          SizedBox(height: 24.h),
          Text(
            "Loading...",
            style: TextStyle(
              fontSize: 16.sp,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Container(
        margin: EdgeInsets.all(24.w),
        padding: EdgeInsets.all(24.r),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24.r),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.shade200,
              blurRadius: 15,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(16.r),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.error_outline, size: 48.sp, color: Colors.red.shade400),
            ),
            SizedBox(height: 20.h),
            Text(
              "Oops! Something went wrong",
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
            SizedBox(height: 12.h),
            Text(
              error,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14.sp, color: Colors.grey.shade600),
            ),
            SizedBox(height: 24.h),
            ElevatedButton(
              onPressed: () {
                context.read<MeatingActionPointViewModel>().fetchMeetingTypes();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade700,
                padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
              child: const Text("Try Again"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAiLoadingIndicator() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade50, Colors.blue.shade100],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: Colors.blue.shade300),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 22.w,
            height: 22.h,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade700),
            ),
          ),
          SizedBox(width: 14.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "AI Processing",
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade700,
                  ),
                ),
                Text(
                  "Generating intelligent action points...",
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: Colors.blue.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAiError(String error) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
      padding: EdgeInsets.all(16.r),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red.shade400, size: 22.sp),
          SizedBox(width: 14.w),
          Expanded(
            child: Text(
              error,
              style: TextStyle(
                fontSize: 13.sp,
                color: Colors.red.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 24.h,
      thickness: 1,
      color: Colors.grey.shade100,
      indent: 20.w,
      endIndent: 20.w,
    );
  }
  Widget _buildSearchableUserDropdown({
    required MeatingActionPointViewModel vm,
    required UserListData? selectedUser,
    required void Function(UserListData?) onChanged,
  }) {
    String searchQuery = '';

    return StatefulBuilder(
      builder: (context, setState) {
        List<UserListData> filteredUsers = vm.userDataList;

        if (searchQuery.isNotEmpty) {
          filteredUsers = vm.userDataList.where((user) {
            final name = (user.name ?? "").toLowerCase();
            final query = searchQuery.toLowerCase();
            return name.contains(query);
          }).toList();
        }

        return Column(
          children: [
            // 🔍 SEARCH
            TextField(
              decoration: InputDecoration(
                hintText: "Search user...",
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  searchQuery = value;
                });
              },
            ),

            SizedBox(height: 10),
            Container(
              height: 200,
              child: filteredUsers.isEmpty
                  ? Center(child: Text("No users found"))
                  : ListView.builder(
                itemCount: filteredUsers.length,
                itemBuilder: (context, index) {
                  final user = filteredUsers[index];

                  return ListTile(
                    title: Text(user.name ?? ""),
                    subtitle: Text(user.email ?? ""),
                    onTap: () {
                      onChanged(user);
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}