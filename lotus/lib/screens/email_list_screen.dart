import 'package:flutter/material.dart';
import 'package:googleapis/gmail/v1.dart' as gmail;
import 'package:intl/intl.dart'; // For formatting date
import 'package:lotus/constants.dart';
import 'email_detail_screen.dart';

class EmailListScreen extends StatefulWidget {
  final String title;
  final List<gmail.Message> emails;
  final bool isSelectionMode;

  const EmailListScreen({
    super.key,
    required this.title,
    required this.emails,
    this.isSelectionMode = false,
  });

  @override
  State<EmailListScreen> createState() => _EmailListScreenState();
}

class _EmailListScreenState extends State<EmailListScreen> {
  int? selectedIndex; // Changed from Set<int> to a single index

  String _getHeaderValue(gmail.Message message, String name) {
    return message.payload?.headers
            ?.firstWhere(
              (h) => (h.name?.toLowerCase() ?? '') == name.toLowerCase(),
              orElse: () => gmail.MessagePartHeader(name: '', value: ''),
            )
            .value ??
        '';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: white,
      appBar: AppBar(
        backgroundColor: magnolia,
        title: Text(widget.title),
        actions: widget.isSelectionMode
            ? [
                TextButton(
                  onPressed: selectedIndex != null
                      ? () {
                          final selectedEmail = widget.emails[selectedIndex!];
                          Navigator.pop(context, [selectedEmail]);
                        }
                      : null,
                  child: const Text('Done', style: emailTxttStyle1),
                ),
              ]
            : null,
      ),
      body: ListView.builder(
        itemCount: widget.emails.length,
        itemBuilder: (context, index) {
          final email = widget.emails[index];
          final subject = _getHeaderValue(email, 'Subject').isNotEmpty
              ? _getHeaderValue(email, 'Subject')
              : 'No Subject';

          final dateHeader = _getHeaderValue(email, 'Date');
          DateTime? parsedDate;
          try {
            parsedDate = DateFormat(
              "EEE, dd MMM yyyy HH:mm:ss zzz",
              'en_US',
            ).parse(dateHeader);
          } catch (_) {}

          final formattedDate = parsedDate != null
              ? DateFormat.MMMd().add_jm().format(parsedDate)
              : 'No Date';

          final isSelected = selectedIndex == index;

          return ListTile(
            leading: widget.isSelectionMode
                ? Radio<int>(
                    value: index,
                    groupValue: selectedIndex,
                    onChanged: (int? selected) {
                      setState(() {
                        selectedIndex = selected;
                      });
                    },
                  )
                : const Icon(Icons.email),
            title: Text(subject, style: emailTxttStyle2),
            subtitle: Text(formattedDate),
            onTap: () {
              // Always show email detail screen
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => EmailDetailScreen(email: email),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
