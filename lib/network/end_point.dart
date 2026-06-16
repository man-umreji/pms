class Endpoint {
  Endpoint._();

  // Test URL
        static const String pmsBaseUrl = 'https://uatpms.sritindia.com:8443/';

  // Live URL
  //      static const String pmsBaseUrl = 'https://pms.sritindia.com/';


  // Testing URL
  // static const String employeeBaseUrl = 'https://eostest.sritindia.com:8443/';

  static const String employeeLogin = '${pmsBaseUrl}api/Pms_api/login';
  static const String employeeLoginFirstOtp ='${pmsBaseUrl}api/Pms_api/first_login_send_otp';
  static const String submitFirstLogin = '${pmsBaseUrl}api/Pms_api/submit_first_login';
  static const String getMeeting = '${pmsBaseUrl}api/Pms_api/get_meeting_types';
  static const String getMeetingEmployees = '${pmsBaseUrl}api/Pms_api/get_meeting_type_employees_api';
  static const String generateActionPointAi = '${pmsBaseUrl}api/Pms_api/generate_action_points_ai';
  static const String actionPointSummaryPoints = '${pmsBaseUrl}api/Pms_api/action_points_summary_detail';
  static const String getActionPoint = '${pmsBaseUrl}api/Pms_api/get_action_points';
  static const String createActionPoint = '${pmsBaseUrl}api/Pms_api/create_meeting_action';
  static const String getActionPointView = '${pmsBaseUrl}api/Pms_api/get_action_points_view';
  static const String updateActionPointView = '${pmsBaseUrl}api/Pms_api/update_meeting_action';
  static const String getAllStatus = '${pmsBaseUrl}api/Pms_api/get_action_status';
  static const String deleteActionPoint = '${pmsBaseUrl}api/Pms_api/delete_action_point';
  static const String getActiveProject = '${pmsBaseUrl}api/Pms_api/get_active_projects_api';
  static const String getProjectManagerName = '${pmsBaseUrl}api/Pms_api/get_project_manager_api';
  static const String deleteAttachments = '${pmsBaseUrl}api/Pms_api/delete_attachment';
  static const String getUserList = '${pmsBaseUrl}api/Pms_api/get_users_list';
}