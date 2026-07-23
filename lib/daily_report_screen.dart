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

  String getSelectedDateString() {
    return "${selectedDate.year}-"
        "${selectedDate.month.toString().padLeft(2, '0')}-"
        "${selectedDate.day.toString().padLeft(2, '0')}";
  }

  Future<double> getTotalExtraCharges() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('extra_charges')
        .where('date', isEqualTo: getSelectedDateString())
        .get();

    double total = 0;

    for (var doc in snapshot.docs) {
      total += (doc['amount'] ?? 0).toDouble();
    }

    return total;
  }

  Future<double> getTotalExpenses() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('expenses')
        .where('date', isEqualTo: getSelectedDateString())
        .get();

    double total = 0;

    for (var doc in snapshot.docs) {
      total += (doc['amount'] ?? 0).toDouble();
    }

    return total;
  }

  void _showLargeImage(String imageUrl) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        child: InteractiveViewer(
          child: Image.network(
            imageUrl,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }

  void _showChargesOrExpensesPopup({
    required String title,
    required String collection,
  }) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: SizedBox(
            width: double.maxFinite,
            height: 400.h,
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection(collection)
                  .where('date', isEqualTo: getSelectedDateString())
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data!.docs;

                if (docs.isEmpty) {
                  return const Center(child: Text("No data found"));
                }

                // ✅ CALCULATE TOTAL PROPERLY
                double total = docs.fold(0.0, (sum, doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return sum + (data['amount'] ?? 0).toDouble();
                });

                return Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        itemCount: docs.length,
                        itemBuilder: (context, index) {
                          final data =
                              docs[index].data() as Map<String, dynamic>;

                          return Card(
                            child: ListTile(
                              title:
                                  Text(data['description'] ?? 'No Description'),
                              subtitle: Text(data['time'] ?? ''),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    "Rs. ${(data['amount'] ?? 0).toString()}",
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete,
                                      color: Colors.red,
                                    ),
                                    onPressed: () async {
                                      final confirm = await showDialog<bool>(
                                        context: context,
                                        builder: (_) => AlertDialog(
                                          title: const Text("Delete"),
                                          content: const Text(
                                            "Are you sure you want to delete this item?",
                                          ),
                                          actions: [
                                            TextButton(
                                              onPressed: () =>
                                                  Navigator.pop(context, false),
                                              child: const Text("Cancel"),
                                            ),
                                            ElevatedButton(
                                              onPressed: () =>
                                                  Navigator.pop(context, true),
                                              child: const Text("Delete"),
                                            ),
                                          ],
                                        ),
                                      );

                                      if (confirm == true) {
                                        await docs[index].reference.delete();

                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                                "Item deleted successfully"),
                                          ),
                                        );
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    SizedBox(height: 10.h),

                    // ✅ CORRECT TOTAL
                    Container(
                      padding: EdgeInsets.all(10.w),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        "Total: Rs. ${total.toStringAsFixed(0)}",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Close"),
            )
          ],
        );
      },
    );
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
        title: const Center(
            child: Text('Daily Report',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold))),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month_rounded),
            onPressed: () => _selectDate(context),
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(16.w),
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

                  // Sort guests by card_no numerically if possible, else alphabetically
                  guests.sort((a, b) {
                    final aCard = a['card_no']?.toString() ?? '';
                    final bCard = b['card_no']?.toString() ?? '';
                    final aNum = int.tryParse(aCard);
                    final bNum = int.tryParse(bCard);
                    if (aNum != null && bNum != null) {
                      return aNum.compareTo(bNum); // Numeric sort
                    } else {
                      return aCard.compareTo(bCard); // Alphabetical fallback
                    }
                  });

                  // Calculate grand total
                  int grandTotal = guests.fold(0, (sum, doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final rent = int.tryParse(data['room_rent'] ?? '0') ?? 0;
                    final extra =
                        int.tryParse(data['extra_charge'] ?? '0') ?? 0;
                    return sum + rent + extra;
                  });

                  return Column(
                    children: [
                      Expanded(
                        child: ListView.builder(
                          itemCount: guests.length,
                          itemBuilder: (context, index) {
                            final guest =
                                guests[index].data() as Map<String, dynamic>;

                            return Card(
                              elevation: 4,
                              margin: EdgeInsets.only(bottom: 12.h),
                              child: Padding(
                                padding: EdgeInsets.all(12.w),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text("Card No: ${guest['card_no'] ?? ''}",
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16.sp)),
                                    SizedBox(height: 8.h),
                                    Text("Room No: ${guest['room_no'] ?? ''}"),
                                    // Text(
                                    //     "Vehicle No: ${guest['vehicle_no'] ?? ''}"),
                                    Text(
                                        "Room Rent: ${guest['room_rent'] ?? ''}"),
                                    Text(
                                        "Extra Charge: ${guest['extra_charge'] ?? ''}"),
                                    Text("Time: ${guest['time'] ?? ''}"),
                                    Text("Total: Rs.${_calculateTotal(guest)}"),
                                    SizedBox(height: 8.h),
                                    Row(
                                      children: [
                                        // Male Front
                                        if (guest['id_front_url_male'] !=
                                                null ||
                                            guest['id_front_url'] != null)
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                const Text('Male ID Front:',
                                                    style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.w600)),
                                                SizedBox(height: 4.h),
                                                GestureDetector(
                                                  onTap: () => _showLargeImage(
                                                    guest['id_front_url_male'] ??
                                                        guest['id_front_url'],
                                                  ),
                                                  child: Image.network(
                                                    guest['id_front_url_male'] ??
                                                        guest['id_front_url'],
                                                    height: 100.h,
                                                    width: double.infinity,
                                                    fit: BoxFit.cover,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        SizedBox(width: 10.w),
                                        // Male Back
                                        if (guest['id_back_url_male'] != null ||
                                            guest['id_back_url'] != null)
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                const Text('Male ID Back:',
                                                    style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.w600)),
                                                SizedBox(height: 4.h),
                                                GestureDetector(
                                                  onTap: () => _showLargeImage(
                                                    guest['id_back_url_male'] ??
                                                        guest['id_back_url'],
                                                  ),
                                                  child: Image.network(
                                                    guest['id_back_url_male'] ??
                                                        guest['id_back_url'],
                                                    height: 100.h,
                                                    width: double.infinity,
                                                    fit: BoxFit.cover,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                      ],
                                    ),
                                    SizedBox(height: 8.h),
                                    Row(
                                      children: [
                                        //Female
                                        if (guest['id_front_url_female'] !=
                                            null)
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                const Text('Female ID Front:',
                                                    style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.w600)),
                                                SizedBox(height: 4.h),
                                                GestureDetector(
                                                  onTap: () => _showLargeImage(
                                                      guest[
                                                          'id_front_url_female']),
                                                  child: Image.network(
                                                    guest[
                                                        'id_front_url_female'],
                                                    height: 100.h,
                                                    width: double.infinity,
                                                    fit: BoxFit.cover,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        SizedBox(width: 10.w),
                                        if (guest['id_back_url_female'] != null)
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                const Text('Female ID Back:',
                                                    style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.w600)),
                                                SizedBox(height: 4.h),
                                                GestureDetector(
                                                  onTap: () => _showLargeImage(
                                                      guest[
                                                          'id_back_url_female']),
                                                  child: Image.network(
                                                    guest['id_back_url_female'],
                                                    height: 100.h,
                                                    width: double.infinity,
                                                    fit: BoxFit.cover,
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
                            );
                          },
                        ),
                      ),
                      SizedBox(height: 12.h),
                      FutureBuilder(
                        future: Future.wait([
                          getTotalExtraCharges(),
                          getTotalExpenses(),
                        ]),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) {
                            return const CircularProgressIndicator();
                          }

                          double extraTotal = snapshot.data![0];
                          double expenseTotal = snapshot.data![1];

                          return Column(
                            children: [
                              Card(
                                color: Colors.blue.shade50,
                                child: ListTile(
                                  leading: const Icon(
                                    Icons.add_circle,
                                    color: Colors.blue,
                                  ),
                                  title: const Text(
                                    "Total Extra Charges",
                                  ),
                                  trailing: Text(
                                    "Rs. ${extraTotal.toStringAsFixed(0)}",
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  onTap: () {
                                    _showChargesOrExpensesPopup(
                                      title: "Extra Charges List",
                                      collection: "extra_charges",
                                    );
                                  },
                                ),
                              ),
                              SizedBox(height: 10.h),
                              Card(
                                color: Colors.red.shade50,
                                child: ListTile(
                                  leading: const Icon(
                                    Icons.money_off,
                                    color: Colors.red,
                                  ),
                                  title: const Text(
                                    "Total Expenses",
                                  ),
                                  trailing: Text(
                                    "Rs. ${expenseTotal.toStringAsFixed(0)}",
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  onTap: () {
                                    _showChargesOrExpensesPopup(
                                      title: "Expenses List",
                                      collection: "expenses",
                                    );
                                  },
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                      SizedBox(height: 12.h),
                      Text(
                        'Grand Total: Rs. $grandTotal',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18.sp,
                          color: Colors.green[800],
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

String _calculateTotal(Map<String, dynamic> guest) {
  final rent = int.tryParse(guest['room_rent'] ?? '0') ?? 0;
  final extra = int.tryParse(guest['extra_charge'] ?? '0') ?? 0;
  return (rent + extra).toString();
}
