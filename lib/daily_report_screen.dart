import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class DailyReportScreen extends StatefulWidget {
  const DailyReportScreen({super.key});

  @override
  State<DailyReportScreen> createState() => _DailyReportScreenState();
}

class _DailyReportScreenState extends State<DailyReportScreen> {
  DateTime selectedDate = DateTime.now();

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.light().copyWith(
            primaryColor: Colors.blue,
            hintColor: Colors.blue,
            buttonTheme:
                const ButtonThemeData(textTheme: ButtonTextTheme.primary),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null && pickedDate != selectedDate) {
      setState(() {
        selectedDate = pickedDate;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final DateTime startOfDay =
        DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
    final DateTime endOfDay = DateTime(
        selectedDate.year, selectedDate.month, selectedDate.day, 23, 59, 59);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blueAccent,
        title: const Text('Daily Report'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month_rounded),
            onPressed: () => _selectDate(context),
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(16.w), // Responsive padding
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Selected Date: ${selectedDate.toLocal().toString().split(' ')[0]}',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.blueGrey[800],
                    fontSize: 18.sp, // Responsive font size
                  ),
            ),
            SizedBox(height: 16.h), // Responsive height
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('guests')
                    .where('date', isGreaterThanOrEqualTo: startOfDay)
                    .where('date', isLessThanOrEqualTo: endOfDay)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final guests = snapshot.data!.docs;

                  // Sort guests by numeric value of card_no
                  guests.sort((a, b) {
                    int cardNoA = int.tryParse(a['card_no']) ?? 0;
                    int cardNoB = int.tryParse(b['card_no']) ?? 0;
                    return cardNoA.compareTo(cardNoB);
                  });

                  double totalAmount = guests.fold(0, (sum, guest) {
                    final roomRent = double.tryParse(guest['room_rent']) ?? 0.0;
                    final extraCharge =
                        double.tryParse(guest['extra_charge']) ?? 0.0;
                    return sum + roomRent + extraCharge;
                  });

                  return Column(
                    children: [
                      Expanded(
                        child: ListView.builder(
                          itemCount: guests.length,
                          itemBuilder: (context, index) {
                            final guest = guests[index];
                            final cardNo = guest['card_no'];
                            final vehicleNo = guest['vehicle_no'];
                            final idNo = guest['id_no'];
                            final roomNo = guest['room_no'];
                            final roomRent =
                                double.tryParse(guest['room_rent']) ?? 0.0;
                            final extraCharge =
                                double.tryParse(guest['extra_charge']) ?? 0.0;

                            // Calculate total for this guest
                            final totalPrice = roomRent + extraCharge;

                            return Card(
                              margin: EdgeInsets.symmetric(vertical: 4.h),
                              elevation: 3.0,
                              child: ListTile(
                                contentPadding: EdgeInsets.all(16.w),
                                title: Text(
                                  'Card No: $cardNo',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16.sp,
                                      ),
                                ),
                                subtitle: Text(
                                  'Vehicle No: $vehicleNo\n'
                                  'ID No: $idNo\n'
                                  'Room No: $roomNo\n'
                                  'Room Rent: LKR${roomRent.toStringAsFixed(2)}\n'
                                  'Extra Charge: LKR${extraCharge.toStringAsFixed(2)}\n'
                                  'Total: LKR${totalPrice.toStringAsFixed(2)}',
                                  style: TextStyle(fontSize: 14.sp),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      SizedBox(height: 8.h), // Responsive height
                      const Divider(thickness: 2.0),
                      Padding(
                        padding: EdgeInsets.all(16.w), // Responsive padding
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Total:',
                              style: TextStyle(
                                fontSize: 20.sp, // Responsive font size
                                fontWeight: FontWeight.bold,
                                color: Colors.blueGrey,
                              ),
                            ),
                            Text(
                              'LKR${totalAmount.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontSize: 20.sp, // Responsive font size
                                fontWeight: FontWeight.bold,
                                color: Colors.teal,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
