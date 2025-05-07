import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/emergency_provider.dart';
import 'package:url_launcher/url_launcher.dart';

class EmergencyContactsScreen extends StatelessWidget {
  const EmergencyContactsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1C2F41),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1C2F41),
        elevation: 0,
        title: const Text(
          'Emergency Contacts',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Consumer<EmergencyProvider>(
        builder: (context, provider, child) {
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: provider.emergencyContacts.length,
            itemBuilder: (context, index) {
              final contact = provider.emergencyContacts[index];
              return Card(
                color: const Color(0xFF181B2C),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Colors.blueGrey,
                    child: Icon(Icons.phone, color: Colors.white),
                  ),
                  title: Text(contact.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  subtitle: Text(contact.category, style: const TextStyle(color: Colors.white70)),
                  trailing: ElevatedButton.icon(
                    onPressed: () async {
                      final Uri phoneUri = Uri(scheme: 'tel', path: contact.phoneNumber);
                      if (await canLaunchUrl(phoneUri)) {
                        await launchUrl(phoneUri);
                      }
                    },
                    icon: const Icon(Icons.call),
                    label: Text(contact.phoneNumber),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}