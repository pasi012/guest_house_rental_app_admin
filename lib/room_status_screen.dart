import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class RoomStatusScreen extends StatefulWidget {
  const RoomStatusScreen({super.key});

  @override
  State<RoomStatusScreen> createState() => _RoomStatusScreenState();
}

class _RoomStatusScreenState extends State<RoomStatusScreen> {
  void _updateRoomStatus(String roomId, String currentStatus) {
    String newStatus = currentStatus == 'Occupied' ? 'Available' : 'Occupied';

    FirebaseFirestore.instance.collection('rooms').doc(roomId).update({
      'status': newStatus,
    }).then((_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Room status updated to $newStatus')),
      );
    }).catchError((error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update status: $error')),
      );
    });
  }

  void _showConfirmationDialog(String roomId, String currentStatus) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Room Status'),
        content: const Text('Do you want to change room availability?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close the dialog
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              _updateRoomStatus(roomId, currentStatus);
              Navigator.of(context).pop(); // Close the dialog
            },
            child: const Text('Yes'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Room Status',
          style: TextStyle(fontSize: 20.sp),
        ),
        backgroundColor: Colors.blueAccent,
      ),
      body: Padding(
        padding: EdgeInsets.all(16.w),
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance.collection('rooms').snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(
                child: Text(
                  'Something went wrong',
                  style: TextStyle(color: Colors.red, fontSize: 18.sp),
                ),
              );
            }

            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            List<DocumentSnapshot?> roomDocs = List<DocumentSnapshot?>.filled(12, null);

            for (var doc in snapshot.data!.docs) {
              int roomNo = int.parse(doc.id);
              if (roomNo >= 1 && roomNo <= 12) {
                roomDocs[roomNo - 1] = doc;
              }
            }

            return GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 12.w,
                mainAxisSpacing: 12.h,
                childAspectRatio: 1.1,
              ),
              itemCount: 12,
              itemBuilder: (context, index) {
                int roomNumber = index + 1;
                DocumentSnapshot? roomDoc = roomDocs[index];
                String status = roomDoc?.get('status') ?? 'Available';

                return GestureDetector(
                  onTap: () {
                    if (status == 'Occupied') {
                      _showConfirmationDialog(roomDoc!.id, status);
                    }
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: status == 'Occupied' ? Colors.redAccent : Colors.green,
                      borderRadius: BorderRadius.circular(12.r),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          spreadRadius: 2,
                          blurRadius: 4,
                          offset: const Offset(0, 2), // changes position of shadow
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        "Room $roomNumber\n${status == 'Occupied' ? 'Booked' : 'Available'}",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}