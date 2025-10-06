import 'package:flutter/material.dart';
import 'package:webinar/app/widgets/drop_down_custom_textfailed.dart';
import 'package:webinar/common/common.dart';
import 'package:webinar/common/components.dart';
import 'package:webinar/config/colors.dart';

class BandChangePage extends StatefulWidget {
  static const String pageName = '/band-change';
  const BandChangePage({super.key});

  @override
  State<BandChangePage> createState() => _BandChangePageState();
}

class _BandChangePageState extends State<BandChangePage> {
  // Band levels
  String? selectedBand;

  // Available band levels
  final List<String> bandLevels = ['أولى', 'ثانية', 'ثالثة', 'رابعة', 'متخرج'];

  @override
  Widget build(BuildContext context) {
    return directionality(
      child: Scaffold(
        appBar: appbar(title: 'تغيير الفرقة'),
        body: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: padding(vertical: 20, horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'اختر الفرقة:',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 20),

              // Band Level Dropdown
              DropDownCustomTextfailed(
                prefixIcon: const Icon(Icons.arrow_drop_down),
                hintText: 'اختر الفرقة',
                dropdownItems: bandLevels,
                onDropdownChanged: (value) {
                  setState(() {
                    selectedBand = value;
                  });
                },
              ),

              const SizedBox(height: 30),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _canSubmit() ? _submitBandChange : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: mainColor(),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'تأكيد تغيير الفرقة',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  bool _canSubmit() {
    return selectedBand != null;
  }

  void _submitBandChange() {
    // Handle band change submission
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('تم تأكيد تغيير الفرقة'),
          content: Text(
            'تم تأكيد طلب تغيير الفرقة بنجاح.\n\n'
            'الفرقة المختارة: ${selectedBand ?? 'غير محدد'}',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('موافق'),
            ),
          ],
        );
      },
    );
  }
}
