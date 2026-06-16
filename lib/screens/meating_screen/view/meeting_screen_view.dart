// import 'package:flutter/material.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';
// import 'package:provider/provider.dart';
// import '../view_model/meating_view_model.dart';
// import '../model/meating_model.dart';
//
// class MeetingScreenView extends StatefulWidget {
//   const MeetingScreenView({super.key});
//
//   @override
//   State<MeetingScreenView> createState() => _MeetingScreenViewState();
// }
//
// class _MeetingScreenViewState extends State<MeetingScreenView> {
//
//   @override
//   void initState() {
//     super.initState();
//     Future.microtask(() {
//       context.read<MeetingViewModel>().fetchMeetingTypes();
//     });
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text("Meeting Types"),
//         backgroundColor: Colors.blue,
//       ),
//
//       body: Consumer<MeetingViewModel>(
//         builder: (context, vm, child) {
//
//           if (vm.isLoading) {
//             return const Center(child: CircularProgressIndicator());
//           }
//           if (vm.errorMessage != null) {
//             return Center(
//               child: Column(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   Text(vm.errorMessage!),
//                    SizedBox(height: 10.w),
//                   ElevatedButton(
//                     onPressed: () => vm.fetchMeetingTypes(),
//                     child:  Text("Retry"),
//                   )
//                 ],
//               ),
//             );
//           }
//           if (vm.meetingTypes.isEmpty) {
//             return const Center(child: Text("No Meeting Types Found"));
//           }
//           return RefreshIndicator(
//             onRefresh: vm.refreshMeetingTypes,
//             child: ListView.builder(
//               itemCount: vm.meetingTypes.length,
//               itemBuilder: (context, index) {
//                 final MeetingType item = vm.meetingTypes[index];
//                 return Card(
//                   margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
//                   child: ListTile(
//                     title: Text(item.name ?? ""),
//                     subtitle: Text("ID: ${item.id}"),
//                     trailing: const Icon(Icons.arrow_forward_ios, size: 16),
//
//                     onTap: () {
//                       _showDetails(context, item);
//                     },
//                   ),
//                 );
//               },
//             ),
//           );
//         },
//       ),
//     );
//   }
//   void _showDetails(BuildContext context, MeetingType item) {
//     showModalBottomSheet(
//       context: context,
//       builder: (_) {
//         return Padding(
//           padding: const EdgeInsets.all(20),
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               Text(
//                 item.name ?? "",
//                 style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
//               ),
//               const SizedBox(height: 10),
//               Text("ID: ${item.id}"),
//               const SizedBox(height: 20),
//               ElevatedButton(
//                 onPressed: () => Navigator.pop(context),
//                 child: const Text("Close"),
//               )
//             ],
//           ),
//         );
//       },
//     );
//   }
// }