import 'dart:io';
import 'dart:math';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:pms/screens/dashbord/view/dashbord_view.dart';
import 'package:pms/screens/main_screen/view/main_screen_view.dart';
import '../../get_action_point_view_screen/model/get_all_status_model.dart';
import '../../get_action_point_view_screen/repository/get_all_status_repo.dart';
import '../../meating_screen/model/meating_model.dart';
import '../../meating_screen/repositoty/meating_repository.dart';
import '../model/create_meating_action_point_res_model.dart';
import '../model/generate_action_point_ai_model.dart';
import '../model/get_active_project_model.dart';
import '../model/get_user_list_model.dart';
import '../model/meating_action_point_model.dart';
import '../repository/create_action_point_repo.dart';
import '../repository/generate_action_point_ai_repo.dart';
import '../repository/get_active_project_repo.dart';
import '../repository/get_project_manager_repo.dart';
import '../repository/get_user_list_repo.dart';
import '../repository/meating_action_point_repo.dart';

class MeatingActionPointViewModel extends ChangeNotifier {
  final GetMeetingTypeRepository _meetingRepo = GetMeetingTypeRepository();
  final SelectEmployeeRepository _employeeRepo = SelectEmployeeRepository();

  final TextEditingController dateController = TextEditingController();
  final TextEditingController notesController = TextEditingController();
  final TextEditingController ccController = TextEditingController();
  final TextEditingController projectNameController = TextEditingController();
  final TextEditingController projectManagerNameController = TextEditingController();
  final TextEditingController projectManagerEmailController = TextEditingController();
  final CreateMeetingActionRepository _createRepo = CreateMeetingActionRepository();
  final GetAllStatusRepository _statusRepo = GetAllStatusRepository();

  List<MeetingType> _meetingTypes = [];
  MeetingType? _selectedMeetingType;

  void setSelectedProject(GetActiveProjectData project) {
    if (_selectedProject?.id == project.id) return;

    _selectedProject = project;
    projectNameController.text = project.name ?? '';

    if (project.id != null && project.id!.isNotEmpty) {
      print("✅ Correct Project ID: ${project.id}");
      fetchProjectManager(project.id!);
    } else {
      projectManagerNameController.clear();
      projectManagerEmailController.clear();
    }

    notifyListeners();
  }

  bool _isCreateLoading = false;
  String? _createError;
  String? _createSuccess;
  bool _isPmLoading = false;
  bool get isPmLoading => _isPmLoading;

  bool get isCreateLoading => _isCreateLoading;
  String? get createError => _createError;
  String? get createSuccess => _createSuccess;

  List<MeetingType> get meetingTypes => _meetingTypes;
  MeetingType? get selectedMeetingType => _selectedMeetingType;

  /// True when the selected meeting type is "Project Meeting" (API name, case-insensitive).
  bool get isProjectMeetingSelected {
    final name = _selectedMeetingType?.name?.toLowerCase().trim() ?? '';
    return name == 'project meeting' || name.contains('project meeting');
  }

  final ProjectRepository _projectRepo = ProjectRepository();

  String formatToApiDate(String input) {
    try {
      final parts = input.split('/');
      if (parts.length == 3) {
        final day = parts[0].padLeft(2, '0');
        final month = parts[1].padLeft(2, '0');
        final year = parts[2];
        return "$year-$month-$day";
      }
    } catch (e) {
      print("Date format error: $e");
    }
    return "";
  }

  List<GetActiveProjectData> _projects = [];
  GetActiveProjectData? _selectedProject;

  List<GetActiveProjectData> get projects => _projects;
  GetActiveProjectData? get selectedProject => _selectedProject;
  List<Data> _employees = [];
  String? _selectedEmployeeId;
  Data? get selectedEmployee => _employees.firstWhere(
        (e) => e.id == _selectedEmployeeId,
    orElse: () => Data(),
  );

  // ================= AI ACTION POINT =================
  final GenerateActionPointAiRepository _aiRepo = GenerateActionPointAiRepository();

  List<ActionPoints> _actionPoints = [];
  int _actionPointsBatchId = 0;
  bool _isAiLoading = false;
  String? _aiError;

  List<ActionPoints> get actionPoints => _actionPoints;
  int get actionPointsBatchId => _actionPointsBatchId;
  bool get isAiLoading => _isAiLoading;
  String? get aiError => _aiError;
  List<Data> get employees => _employees;

  bool _isLoading = false;
  String? _error;

  bool get isLoading => _isLoading;
  String? get error => _error;

  final List<String> _attachmentPaths = [];
  List<String> get attachmentPaths => List.unmodifiable(_attachmentPaths);

  /// Returns null on success, or an error message.
  String? addAttachmentPath(String path) {
    final trimmed = path.trim();
    if (trimmed.isEmpty) return 'Invalid file';
    final ext = trimmed.contains('.')
        ? trimmed.split('.').last.toLowerCase()
        : '';
    if (!_attachmentAllowedExt.contains(ext)) {
      return 'Allowed types: pdf, doc, docx, xls, xlsx, jpg, jpeg, png';
    }
    final file = File(trimmed);
    if (!file.existsSync()) return 'File not found';
    if (file.lengthSync() > _attachmentMaxBytes) {
      return 'Each file must be 3 MB or smaller';
    }
    if (_attachmentPaths.contains(trimmed)) return 'File already added';
    _attachmentPaths.add(trimmed);
    notifyListeners();
    return null;
  }

  void removeAttachmentAt(int index) {
    if (index < 0 || index >= _attachmentPaths.length) return;
    _attachmentPaths.removeAt(index);
    notifyListeners();
  }

  void clearAttachments() {
    _attachmentPaths.clear();
    notifyListeners();
  }

  final GetProjectManagerRepository _pmRepo = GetProjectManagerRepository();

  String? _projectManagerName;
  String? _projectManagerEmail;
  String? _apiDate;

  void setApiDate(String date) {
    _apiDate = date;
  }

  String? get projectManagerName => _projectManagerName;
  String? get projectManagerEmail => _projectManagerEmail;

  Future<void> fetchProjectManager(String projectId) async {
    _isPmLoading = true;
    notifyListeners();

    projectManagerNameController.text = "Loading...";
    projectManagerEmailController.text = "Loading...";

    try {
      print("🚀 Calling Project Manager API with ID: $projectId");

      final res = await _pmRepo.getProjectManager(projectId: projectId);

      print("📦 FULL RESPONSE: $res");
      print("👤 PM Name: ${res?.projectManagerData?.name}");

      if (res != null &&
          res.status == true &&
          res.projectManagerData != null) {

        _projectManagerName = res.projectManagerData!.name;
        _projectManagerEmail = res.projectManagerData!.email;

        projectManagerNameController.text = _projectManagerName ?? 'No Manager Found';
        projectManagerEmailController.text = _projectManagerEmail ?? 'No Manager Found';

        print("✅ Manager Set: $_projectManagerName");

      } else {
        print("⚠️ PM API returned empty or invalid");

        _projectManagerName = null;
        _projectManagerEmail = null;

        projectManagerNameController.text = "No Manager Found";
        projectManagerEmailController.text = "Email Not Found";
      }

    } catch (e) {
      print("PM API Error: $e");

      _projectManagerName = null;
      _projectManagerEmail = null;
      projectManagerNameController.text = "Error loading manager";
      projectManagerEmailController.text = "Error loading manager";

    } finally {
      _isPmLoading = false;
      notifyListeners();
    }
  }

  String? selectedStatus;

  void setSelectedStatus(String value) {
    selectedStatus = value;
    notifyListeners();
  }

  List<StatusList> _statusList = [];
  List<StatusList> get statusList => _statusList;

  bool _isStatusLoading = false;
  bool get isStatusLoading => _isStatusLoading;
  // ================= USER LIST =================

  final UserRepository _userRepo = UserRepository();
  List<UserListData> _selectedUsers = [];

  List<UserListData> get selectedUsers => _selectedUsers;

  void setSelectedUsers(List<UserListData> users) {
    _selectedUsers = users;
    notifyListeners();
  }
  void toggleUserSelection(UserListData user) {
    final exists = _selectedUsers.any((u) => u.id == user.id);

    if (exists) {
      _selectedUsers.removeWhere((u) => u.id == user.id);
    } else {
      _selectedUsers.add(user);
    }

    notifyListeners();
  }
  void clearCCRecipients() {
    _selectedUsers = [];
    ccController.clear();
    notifyListeners();
  }
  List<UserListData> _userDataList = [];
  List<UserListData> get userDataList => _userDataList;

  bool _isUserLoading = false;
  bool get isUserLoading => _isUserLoading;

  String? _userError;
  String? get userError => _userError;

  String? _selectedUserId;

// ✅ GET SELECTED USER
  UserListData? get selectedUser {
    try {
      return _userDataList.firstWhere((u) => u.id == _selectedUserId);
    } catch (_) {
      return null;
    }
  }

// ✅ SET USER
  void setSelectedUser(UserListData user) {
    _selectedUserId = user.id;
    notifyListeners();
  }

// ✅ FETCH USERS
  Future<void> fetchUserList() async {
    _isUserLoading = true;
    notifyListeners();

    try {
      final res = await _userRepo.getUserList();

      if (res != null && res.status == true && res.userListData != null) {
        _userDataList = res.userListData!;
        _userError = null;
      } else {
        _userDataList = [];
        _userError = "Failed to load users";
      }
    } catch (e) {
      _userDataList = [];
      _userError = "Error loading users";
      print("❌ USER LIST ERROR: $e");
    } finally {
      _isUserLoading = false;
      notifyListeners();
    }
  }

  /// =========================================================
  /// 🔥 FETCH ALL STATUS LIST
  /// =========================================================
  Future<void> fetchAllStatus() async {
    _isStatusLoading = true;
    notifyListeners();

    try {
      final response = await _statusRepo.getAllStatus();

      if (response.success == true && response.statusList != null) {
        _statusList = response.statusList!
            .where((status) => status.label != "All Status")
            .toList();
      } else {
        _statusList = [];
      }
    } catch (e) {
      print("❌ STATUS FETCH ERROR: $e");
      _statusList = [];
    }

    _isStatusLoading = false;
    notifyListeners();
  }

  Future<void> fetchActiveProjects() async {
    _isLoading = true;
    notifyListeners();

    try {
      final res = await _projectRepo.getActiveProjects();

      if (res != null && res.status == true && res.getActiveProjectdata != null) {
        _projects = res.getActiveProjectdata!;
      } else {
        _projects = [];
        _error = res?.message ?? "Failed to load projects";
      }
    } catch (e) {
      _projects = [];
      _error = "Error loading projects";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchMeetingTypes() async {
    _isLoading = true;
    notifyListeners();

    try {
      final res = await _meetingRepo.getMeetingTypes();

      if (res.success == true && res.meetingType != null) {
        _meetingTypes = res.meetingType!;
      } else {
        _meetingTypes = [];
        _error = "Failed to load meeting types";
      }
    } catch (e) {
      _meetingTypes = [];
      _error = "Error loading meeting types";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ================= SELECT MEETING =================
  void setSelectedMeetingType(MeetingType type) {
    _selectedMeetingType = type;
    _selectedEmployeeId = null;
    fetchEmployees(
      meetingTypeId: type.id.toString(),
      projectId: "1",
    );
    notifyListeners();
  }

  Future<void> fetchEmployees({
    required String meetingTypeId,
    required String projectId,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final res = await _employeeRepo.getEmployees(
        SelectEmployeeReqModel(
          meatingTypeId: meetingTypeId,
          projectId: projectId,
        ),
      );

      if (res.status == true && res.data != null) {
        _employees = res.data!;
        if (_selectedEmployeeId != null &&
            !_employees.any((emp) => emp.id == _selectedEmployeeId)) {
          _selectedEmployeeId = null;
        }
      } else {
        _employees = [];
        _selectedEmployeeId = null;
        _error = res.message ?? "Failed to load employees";
      }
    } catch (e) {
      _employees = [];
      _selectedEmployeeId = null;
      _error = "Error loading employees";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ================= NORMALIZE TEXT =================
  String _normalize(String text) {
    return text
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s]'), '') // 🔥 remove punctuation
        .replaceAll(RegExp(r'\b(the|a|an)\b'), '') // 🔥 remove common words (optional but powerful)
        .replaceAll(RegExp(r'\s+'), ' ') // normalize spaces
        .trim();
  }

  bool _isDuplicateActionPoint(String description, String? assignedToId) {
    final newDesc = _normalize(description);
    final newAssignee = assignedToId ?? '';

    return _actionPoints.any((point) {
      final existingDesc = _normalize(point.description ?? "");
      final existingAssignee = point.assignedToId ?? '';
      return existingDesc == newDesc && existingAssignee == newAssignee;
    });
  }

  // ================= ADD MANUAL ACTION POINT (WITH DUPLICATE CHECK) =================
  bool addManualActionPoint({
    required String description,
    String? assignedToId,
    String? targetDate,
  }) {
    final normalizedDesc = _normalize(description);

    // 🚫 DUPLICATE CHECK (normalized)
    if (_isDuplicateActionPoint(normalizedDesc, assignedToId)) {
      print("⚠️ Duplicate action point skipped");
      _aiError = "Duplicate action point already exists for this employee";
      notifyListeners();
      return false;
    }

    String? assigneeName;

    // ✅ Get employee name
    if (assignedToId != null && assignedToId.isNotEmpty) {
      final employee = _employees.firstWhere(
            (e) => e.id == assignedToId,
        orElse: () => Data(),
      );

      if (employee.employeeName != null &&
          employee.employeeName!.isNotEmpty) {
        assigneeName = employee.employeeName;
      }
    }

    final newPoint = ActionPoints(
      description: description,
      assignedToId: assignedToId,
      assigneeName: assigneeName,
      targetDate: targetDate,
      isManual: true,
    );

    _actionPoints.add(newPoint);

    // Clear previous error if any
    _aiError = null;

    print("✅ Manual action point added: $description");

    notifyListeners();
    return true;
  }

  void removeActionPoint(int index) {
    if (index < 0 || index >= _actionPoints.length) return;
    final removed = _actionPoints[index];
    _actionPoints.removeAt(index);
    print("🗑️ Action point removed: ${removed.description}");
    notifyListeners();
  }

  bool updateActionPointDescription(int index, String newDescription) {
    if (index < 0 || index >= _actionPoints.length) return false;

    final currentPoint = _actionPoints[index];
    final normalizedNew = _normalize(newDescription);
    final currentAssignee = currentPoint.assignedToId ?? '';

    // 🚫 DUPLICATE CHECK (exclude current index)
    bool isDuplicate = _actionPoints.asMap().entries.any((entry) {
      final i = entry.key;
      final point = entry.value;

      if (i == index) return false;

      final existingDesc = _normalize(point.description ?? "");
      final existingAssignee = point.assignedToId ?? '';
      return existingDesc == normalizedNew && existingAssignee == currentAssignee;
    });

    if (isDuplicate) {
      print("⚠️ Duplicate detected - update blocked");
      _aiError = "Duplicate action point already exists for this employee";
      notifyListeners();
      return false;
    }

    // ✅ UPDATE
    _actionPoints[index] = ActionPoints(
      description: newDescription,
      targetDate: currentPoint.targetDate,
      assigneeName: currentPoint.assigneeName,
      assignedToId: currentPoint.assignedToId,
      isManual: currentPoint.isManual,
    );

    // Clear error if any
    _aiError = null;

    notifyListeners();
    return true;
  }

  void clearFormErrors() {
    // _selectedUsers = [];
    // ccController.clear();
    _createError = null;
    _aiError = null;
    notifyListeners();
  }

  Future<void> createActionPoint({
    required String projectId,
    required BuildContext context,
  }) async {
    if (_selectedMeetingType == null) {
      _createError = "Please select meeting type";
      notifyListeners();
      return;
    }

    if (dateController.text.isEmpty) {
      _createError = "Please select meeting date";
      notifyListeners();
      return;
    }

    if (_actionPoints.isEmpty) {
      _createError = "Generate or add at least one action point";
      notifyListeners();
      return;
    }
    final duplicates = _checkForDuplicates();
    if (duplicates.isNotEmpty) {
      _createError =
      "Duplicate action points found: ${duplicates.take(3).join(", ")}${duplicates.length > 3 ? "..." : ""}";
      notifyListeners();
      return;
    }
    for (int i = 0; i < _actionPoints.length; i++) {
      final assignedId =
          _actionPoints[i].assignedToId ?? _selectedEmployeeId;

      if (assignedId == null || assignedId.isEmpty) {
        _createError =
        "Assign an employee to each action point (expand row ${i + 1})";
        notifyListeners();
        return;
      }
    }

    _isCreateLoading = true;
    _createError = null;
    _createSuccess = null;
    notifyListeners();

    try {
      final model = CreateMeatingActionReqModel(
        meatingDate: formatToApiDate(dateController.text),
        projectId: projectId,
        meatingTypeId: _selectedMeetingType!.id.toString(),
      );

      final Map<String, dynamic> body = model.toJson();

      // ❌ REMOVE THIS BLOCK (repo handles CC now)
      /*
    for (int i = 0; i < _selectedUsers.length; i++) {
      final email = _selectedUsers[i].email ?? "";
      if (email.isNotEmpty) {
        body["cc_mailid[$i]"] = email;
      }
    }
    */

      for (int i = 0; i < _actionPoints.length; i++) {
        final point = _actionPoints[i];
        final assignedId =
            point.assignedToId ?? _selectedEmployeeId;

        body["action_points[$i][description]"] =
            point.description ?? "";

        String targetDate = point.targetDate ?? "";
        if (targetDate.contains('/')) {
          targetDate = formatToApiDate(targetDate);
        }

        body["action_points[$i][target_date]"] = targetDate;
        body["action_points[$i][assigned_to]"] = assignedId!;
      }

      print("========= FINAL BODY =========");
      print(body);
      final res = await _createRepo.createActionPoint(
        body,
        attachmentPaths: List<String>.from(_attachmentPaths),
        selectedUsers: _selectedUsers,
      );

      if (res.status == true) {
        _createSuccess = res.message ?? "Created successfully";
        print("SELECTED USERS AT API: ${_selectedUsers.map((e) => e.email).toList()}");
        print("SELECTED USERS AT API: ${_selectedUsers.map((e) => e.email).toList()}");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_createSuccess!)),
        );

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => MainScreenView()),
              (route) => false,
        );

        await clearForm();
        clearCCRecipients();
      } else {
        _createError = res.message ?? "Failed to create action point";
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_createError!),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      _createError = "Something went wrong: $e";
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_createError!),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      _isCreateLoading = false;
      notifyListeners();
    }
  }

  List<String> _checkForDuplicates() {
    final seen = <String>{};
    final duplicates = <String>[];

    for (var point in _actionPoints) {
      final key = '${_normalize(point.description ?? "")}_${point.assignedToId ?? ""}';
      if (seen.contains(key)) {
        duplicates.add(point.description ?? "Unknown");
      }
      seen.add(key);
    }
    return duplicates;
  }

  Future<void> generateActionPoints({
    required String meetingNotes,
    required String meetingDate,
    required String projectId,
  }) async {

// ================= VALIDATIONS =================

// 1. Meeting type
    if (_selectedMeetingType == null) {
      _aiError = "Please select meeting type";
      notifyListeners();
      return;
    }

// 2. Meeting notes
    if (meetingNotes.trim().isEmpty) {
      _aiError = "Please enter meeting notes";
      notifyListeners();
      return;
    }

    if (meetingNotes.trim().length < 5) {
      _aiError = "Meeting notes should be at least 5 characters";
      notifyListeners();
      return;
    }

// 3. Optional: Meeting date
    if (meetingDate.trim().isEmpty) {
      _aiError = "Please select meeting date";
      notifyListeners();
      return;
    }

    _isAiLoading = true;
    _aiError = null;
    notifyListeners();

    try {
      // Ensure employees loaded
      if (_employees.isEmpty) {
        await fetchEmployees(
          meetingTypeId: _selectedMeetingType!.id.toString(),
          projectId: projectId,
        );
      }

      final res = await _aiRepo.generateActionPoints(
        GenerateActionPointAiReqModel(
          meatingDate: meetingDate,
          meatingNotes: meetingNotes,
          meatingTypeId: _selectedMeetingType!.id.toString(),
          projectId: projectId,
        ),
      );

      if (res.success == true && res.actionPoints != null) {
        final newAiPoints = <ActionPoints>[];
        final Set<String> tempSet = {};

        int duplicateCount = 0;
        int matchedCount = 0;
        int unmatchedCount = 0;

        for (var aiPoint in res.actionPoints!) {
          String? matchedId;
          String? matchedName;

          // 👉 Get assignee name
          String? effectiveAssigneeName = aiPoint.assigneeName;

          if (effectiveAssigneeName == null &&
              aiPoint.description != null) {
            effectiveAssigneeName =
                _extractAssigneeFromDescription(aiPoint.description!);
          }

          // ================= EMPLOYEE MATCHING =================
          if (effectiveAssigneeName != null &&
              effectiveAssigneeName.isNotEmpty) {
            final searchName = effectiveAssigneeName.toLowerCase().trim();

            // Exact match
            for (var emp in _employees) {
              final empName =
              (emp.employeeName ?? "").toLowerCase().trim();

              if (empName == searchName) {
                matchedId = emp.id;
                matchedName = emp.employeeName;
                matchedCount++;
                break;
              }
            }

            // Contains match
            if (matchedId == null) {
              for (var emp in _employees) {
                final empName =
                (emp.employeeName ?? "").toLowerCase().trim();

                if (empName.contains(searchName) ||
                    searchName.contains(empName)) {
                  matchedId = emp.id;
                  matchedName = emp.employeeName;
                  matchedCount++;
                  break;
                }
              }
            }

            // First name match
            if (matchedId == null && searchName.contains(' ')) {
              final firstName = searchName.split(' ')[0];

              for (var emp in _employees) {
                final empName =
                (emp.employeeName ?? "").toLowerCase().trim();

                if (empName.startsWith(firstName) ||
                    empName.contains(firstName)) {
                  matchedId = emp.id;
                  matchedName = emp.employeeName;
                  matchedCount++;
                  break;
                }
              }
            }

            if (matchedId == null) unmatchedCount++;
          } else {
            unmatchedCount++;
          }

          final newPoint = ActionPoints(
            description: aiPoint.description,
            targetDate: aiPoint.targetDate,
            assigneeName: matchedName ?? effectiveAssigneeName,
            assignedToId: matchedId,
            isManual: false,
          );

          // ================= DUPLICATE CHECK =================
          final desc = newPoint.description ?? "";
          final normalizedDesc = _normalize(desc);
          final key = "${normalizedDesc}_${newPoint.assignedToId ?? ""}";

          bool isDuplicate =
              _actionPoints.any((p) =>
              _normalize(p.description ?? "") == normalizedDesc) ||
                  tempSet.contains(normalizedDesc);

          if (isDuplicate) {
            duplicateCount++;
            continue;
          }

          tempSet.add(normalizedDesc);
          newAiPoints.add(newPoint);
        }

        // ✅ Add only unique points
        _actionPoints.addAll(newAiPoints);
        _actionPointsBatchId++;

        // ================= MESSAGES =================
        if (duplicateCount > 0 && unmatchedCount > 0) {
          _aiError =
          "⚠️ $duplicateCount duplicate(s) skipped. ⚠️ $unmatchedCount need assignment.";
        } else if (duplicateCount > 0) {
          _aiError =
          "⚠️ $duplicateCount duplicate action point(s) skipped";
        } else if (unmatchedCount > 0) {
          _aiError =
          "⚠️ $unmatchedCount action point(s) need employee assignment";
        } else {
          _aiError = null;
        }

        notesController.clear();
        notifyListeners();

      } else {
        _aiError = "Failed to generate action points";
      }
    } catch (e) {
      _aiError = "Error generating action points: $e";
    } finally {
      _isAiLoading = false;
      notifyListeners();
    }
  }

  String? _extractAssigneeFromDescription(String description) {
    final patterns = [
      RegExp(r'^([A-Z][a-z]+)\s+will\s+', caseSensitive: false),
      RegExp(r'^([A-Z][a-z]+)\s+to\s+', caseSensitive: false),
      RegExp(r'([A-Z][a-z]+)\s+will\s+', caseSensitive: false),
      RegExp(r'([A-Z][a-z]+)\s+to\s+', caseSensitive: false),
    ];

    for (var pattern in patterns) {
      final match = pattern.firstMatch(description);
      if (match != null && match.groupCount >= 1) {
        final name = match.group(1);
        if (name != null && name.isNotEmpty) {
          return name;
        }
      }
    }
    return null;
  }

  // Helper method to extract date from description
  String? _extractDateFromDescription(String description) {
    final patterns = [
      RegExp(r'by\s+(\d{1,2})(?:st|nd|rd|th)?\s+(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)', caseSensitive: false),
      RegExp(r'by\s+(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)\s+(\d{1,2})(?:st|nd|rd|th)?', caseSensitive: false),
      RegExp(r'on\s+(\d{1,2})(?:st|nd|rd|th)?\s+(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)', caseSensitive: false),
      RegExp(r'on\s+(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)\s+(\d{1,2})(?:st|nd|rd|th)?', caseSensitive: false),
    ];

    final months = {
      'Jan': '01', 'Feb': '02', 'Mar': '03', 'Apr': '04',
      'May': '05', 'Jun': '06', 'Jul': '07', 'Aug': '08',
      'Sep': '09', 'Oct': '10', 'Nov': '11', 'Dec': '12'
    };

    final currentYear = DateTime.now().year;

    for (var pattern in patterns) {
      final match = pattern.firstMatch(description);
      if (match != null) {
        String? day, month;

        if (match.groupCount >= 2) {
          if (months.containsKey(match.group(1))) {
            month = months[match.group(1)!];
            day = match.group(2)!.padLeft(2, '0');
          } else if (months.containsKey(match.group(2))) {
            month = months[match.group(2)!];
            day = match.group(1)!.padLeft(2, '0');
          }

          if (day != null && month != null) {
            return "$currentYear-$month-$day";
          }
        }
      }
    }
    return null;
  }

  void _showCustomSnackBar(BuildContext context, String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // Add this method in MeatingActionPointViewModel class
  void clearSelectedMeetingType() {
    _selectedMeetingType = null;
    notifyListeners();
  }

  Future<void> clearForm() async {
    dateController.clear();
    notesController.clear();
    ccController.clear();
    projectNameController.clear();
    projectManagerNameController.clear();
    projectManagerEmailController.clear();
    clearAttachments();
    _actionPoints = [];
    _actionPointsBatchId++;
    _selectedEmployeeId = null;
    _selectedMeetingType = null;
    _createSuccess = null;
    _createError = null;
    _aiError = null;
    notifyListeners();
  }

  // ================= CLEAR ACTION POINTS =================
  void clearActionPoints() {
    _actionPoints = [];
    _actionPointsBatchId++;
    notifyListeners();
  }
  bool updateActionPointAssignee(int index, String? employeeId) {
    if (index < 0 || index >= _actionPoints.length) return false;

    final current = _actionPoints[index];

    // ✅ NO DUPLICATE CHECK HERE

    String? name;
    if (employeeId != null && employeeId.isNotEmpty) {
      for (final e in _employees) {
        if (e.id == employeeId) {
          name = e.employeeName;
          break;
        }
      }
    }

    _actionPoints[index] = ActionPoints(
      description: current.description,
      targetDate: current.targetDate,
      assigneeName: name,
      assignedToId: employeeId,
      isManual: current.isManual,
    );

    _aiError = null;
    notifyListeners();
    return true;
  }

  void updateActionPointTargetDate(int index, String date) {
    if (index < 0 || index >= _actionPoints.length) return;
    String apiDate = date;
    if (date.contains('/')) {
      apiDate = formatToApiDate(date);
    }

    final p = _actionPoints[index];
    _actionPoints[index] = ActionPoints(
      description: p.description,
      targetDate: apiDate,
      assigneeName: p.assigneeName,
      assignedToId: p.assignedToId,
      isManual: p.isManual,
    );
    notifyListeners();
  }

  void setSelectedEmployee(Data emp) {
    _selectedEmployeeId = emp.id;
    notifyListeners();
  }

  // ================= GET SELECTED EMPLOYEE ID =================
  String? getSelectedEmployeeId() => _selectedEmployeeId;

  // ================= CHECK FOR DUPLICATES IN CURRENT LIST =================
  bool hasDuplicates() {
    return _checkForDuplicates().isNotEmpty;
  }

  List<String> getDuplicateDescriptions() {
    return _checkForDuplicates();
  }

  // ================= DISPOSE =================
  @override
  void dispose() {
    dateController.dispose();
    notesController.dispose();
    ccController.dispose();
    projectNameController.dispose();
    projectManagerNameController.dispose();
    projectManagerEmailController.dispose();
    super.dispose();
  }
}

const _attachmentMaxBytes = 3 * 1024 * 1024;
const _attachmentAllowedExt = {
  'pdf',
  'doc',
  'docx',
  'xls',
  'xlsx',
  'jpg',
  'jpeg',
  'png',
};