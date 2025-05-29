import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:sysadmin/core/utils/color_extension.dart';
import 'package:sysadmin/core/utils/util.dart';
import 'package:sysadmin/core/widgets/ios_scaffold.dart';
import 'package:url_launcher/url_launcher.dart';

class Upi extends StatefulWidget {
  const Upi({super.key});

  @override
  State<Upi> createState() => _UpiState();
}

class _UpiState extends State<Upi> {
  late final TextEditingController amountController;
  final _myUpiId = "pkhade2865@okaxis";

  // UPI Payment Options
  final List<Map<String, dynamic>> _upiOptions = [
    {
      "asset": "assets/about/upi.svg",
      "title": "UPI"
    },
    {
      "asset": "assets/about/google-pay.svg",
      "title": "Google Pay"
    },
    {
      "asset": "assets/about/phonepe.svg",
      "title": "PhonePe"
    },
    {
      "asset": "assets/about/paytm.svg",
      "title": "Paytm"
    },
  ];

  @override
  void initState() {
    super.initState();
    amountController = TextEditingController();
  }

  @override
  void dispose() {
    amountController.dispose();
    super.dispose();
  }

  String? _validateAmount(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter an amount';
    }

    final amount = double.tryParse(value.trim());
    if (amount == null) {
      return 'Please enter a valid amount';
    }

    if (amount <= 0) {
      return 'Amount must be greater than 0';
    }

    if (amount > 100000) {
      return 'Amount cannot exceed ₹1,00,000';
    }

    return null;
  }

  Future<void> _launchUpiApp(String appTitle) async {
    final amountText = amountController.text.trim();
    final validation = _validateAmount(amountText);

    if (validation != null) {
      Util.showMsg(context: context, msg: validation, isError: true);
      return;
    }

    final amount = double.parse(amountText);
    final formattedAmount = amount.toStringAsFixed(2);

    // UPI Credentials
    const payeeName = "Prathamesh Khade";
    const transactionNote = "Donation for SysAdmin App";

    String upiUrl = switch(appTitle.toLowerCase()) {
      'google pay' => "tez://upi/pay?pa=$_myUpiId&pn=${Uri.encodeComponent(payeeName)}&am=$formattedAmount&tn=${Uri.encodeComponent(transactionNote)}&cu=INR",
      'phonepe' => "phonepe://pay?pa=$_myUpiId&pn=${Uri.encodeComponent(payeeName)}&am=$formattedAmount&tn=${Uri.encodeComponent(transactionNote)}&cu=INR",
      'paytm' => "paytmmp://pay?pa=$_myUpiId&pn=${Uri.encodeComponent(payeeName)}&am=$formattedAmount&tn=${Uri.encodeComponent(transactionNote)}&cu=INR",
      _ => "upi://pay?pa=$_myUpiId&pn=${Uri.encodeComponent(payeeName)}&am=$formattedAmount&tn=${Uri.encodeComponent(transactionNote)}&cu=INR",
    };

    try {
      final Uri uri = Uri.parse(upiUrl);
      bool launched = await launchUrl(uri, mode: LaunchMode.externalApplication);

      if (!launched) {
        // Try alternative PhonePe URL format for PhonePe specifically
        if (appTitle.toLowerCase() == 'phonepe') {
          final altPhonePeUrl = "phonepe://pay?pa=$_myUpiId&pn=${Uri.encodeComponent(payeeName)}&am=$formattedAmount&tn=${Uri.encodeComponent(transactionNote)}&cu=INR";
          final Uri altUri = Uri.parse(altPhonePeUrl);
          launched = await launchUrl(altUri, mode: LaunchMode.externalApplication);
        }

        if (!launched) {
          // Final fallback to generic UPI URL
          final genericUpiUrl = "upi://pay?pa=$_myUpiId&pn=${Uri.encodeComponent(payeeName)}&am=$formattedAmount&tn=${Uri.encodeComponent(transactionNote)}&cu=INR";
          final Uri genericUri = Uri.parse(genericUpiUrl);
          launched = await launchUrl(genericUri, mode: LaunchMode.externalApplication);

          if (!launched && mounted) {
            Util.showMsg(
                context: context,
                msg: 'Unable to open $appTitle. Please ensure the app is installed and try again.',
                isError: true
            );
          }
        }
      }
    }
    catch (e) {
      if (mounted) {
        Util.showMsg(
            context: context,
            msg: 'Failed to process payment. Please try again.',
            isError: true
        );
      }
    }
  }

  Widget _buildUpiOptions(String asset, String title) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.only(bottom: 5.0),
      decoration: BoxDecoration(
          border: Border(
              bottom: BorderSide(
                color: Theme.of(context).colorScheme.inverseSurface.useOpacity(0.2),
                width: 0.9,
              )
          )
      ),
      child: ListTile(
          contentPadding: const EdgeInsets.only(left: 8.0, right: 4.0),
          titleAlignment: ListTileTitleAlignment.titleHeight,
          titleTextStyle: theme.textTheme.labelLarge?.copyWith(fontSize: 17),
          leading: SizedBox(
              width: 45,
              child: SvgPicture.asset(asset, width: 30, height: 30)
          ),
          title: Text(title),
          trailing: Icon(Icons.chevron_right_sharp, color: theme.colorScheme.primary),
          onTap: () => _launchUpiApp(title)
      ),
    );
  }

  Future<void> _copyUpiId() async {
    await Clipboard.setData(ClipboardData(text: _myUpiId));

    if (mounted) {
      Util.showMsg(context: context, msg: 'UPI ID copied to clipboard', bgColour: Colors.green);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const commonStyle = TextStyle(
      fontSize: 26,
      fontWeight: FontWeight.w700,
      letterSpacing: 0.01,
    );
    final commonTitleColor = theme.colorScheme.inverseSurface.useOpacity(0.9);

    return IosScaffold(
        title: 'Donate via UPI',
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget> [
                // Title
                Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                  child: Text('Support SysAdmin Development', style: theme.textTheme.titleMedium),
                ),
                const SizedBox(height: 40),

                // Amount with TextInput
                Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                  child: Text("Amount", style: theme.textTheme.titleSmall?.copyWith(fontSize: 14, color: commonTitleColor)),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 2.5),
                  margin: const EdgeInsets.only(left: 8.0),
                  decoration: BoxDecoration(
                      border: Border.all(color: commonTitleColor.useOpacity(0.2), width: 1),
                      borderRadius: BorderRadius.circular(8)
                  ),

                  child: TextFormField(
                    controller: amountController,
                    autofocus: true,
                    cursorHeight: 40,
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      prefixIcon: const Padding(
                        padding: EdgeInsets.only(left: 4, top: 12, bottom: 12),
                        child: Icon(Icons.currency_rupee_sharp, size: 26, color: Colors.grey),
                      ),
                      hintText: "Enter amount",
                      hintStyle: commonStyle.copyWith(color: theme.colorScheme.surface),
                      errorText: null, // This will be handled by our validation method
                    ),
                    style: commonStyle,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
                    ],
                    textAlign: TextAlign.start,
                    textAlignVertical: TextAlignVertical.center,
                    onChanged: (value) => setState(() {
                      // Trigger validation on change
                      _validateAmount(value);
                    })
                  ),
                ),
                const SizedBox(height: 80),

                // Pay with
                Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                  child: Text("Pay with", style: theme.textTheme.titleSmall?.copyWith(
                      fontSize: 14,
                      color: commonTitleColor
                  )),
                ),
                Divider(color: theme.colorScheme.inverseSurface.useOpacity(0.25), thickness: 1.3, height: 20),

                // UPI apps
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _upiOptions.length,
                  itemBuilder: (context, index) => _buildUpiOptions(
                    "${_upiOptions[index]["asset"]}",
                    "${_upiOptions[index]["title"]}"
                  ),
                ),
                const SizedBox(height: 20),

                // UPI ID Copy Section
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface.useOpacity(0.5),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: theme.colorScheme.primary.useOpacity(0.2),
                        width: 1
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.account_balance_wallet, color: theme.colorScheme.primary, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('UPI ID', style: theme.textTheme.labelSmall?.copyWith(fontSize: 12)),
                            const SizedBox(height: 2),
                            Text(_myUpiId, style: theme.textTheme.bodyMedium?.copyWith(fontSize: 14)),
                          ],
                        ),
                      ),
                      TextButton.icon(
                        onPressed: _copyUpiId,
                        icon: Icon(Icons.copy, size: 16, color: theme.colorScheme.primary),
                        label: Text('Copy', style: TextStyle(color: theme.colorScheme.primary)),
                        style: TextButton.styleFrom(
                          minimumSize: const Size(60, 32),
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        )
    );
  }
}
