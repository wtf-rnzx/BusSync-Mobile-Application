import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/authService.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'Profile',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.lightBlue.shade600,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: Consumer<AuthService>(
        builder: (context, authService, child) {
          final userData = authService.userData;

          if (userData == null) {
            return const Center(
              child: Text(
                'No user data available',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                children: [
                  // Profile Header Section
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.lightBlue.shade100.withOpacity(0.3),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        // Profile Avatar
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: CircleAvatar(
                            radius: 55,
                            backgroundColor: Colors.lightBlue.shade50,
                            child: Text(
                              _getInitials(userData['fullName'] ?? 'User'),
                              style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                color: Colors.lightBlue.shade700,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // User Name
                        Text(
                          userData['fullName'] ?? 'User',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 6),

                        // User Email
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.lightBlue.shade50,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            userData['email'] ?? '',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.lightBlue.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // User Information Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.shade200,
                          blurRadius: 10,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.lightBlue.shade50,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                Icons.person_outline_rounded,
                                color: Colors.lightBlue.shade600,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'Personal Information',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        _buildInfoRow(
                          Icons.badge_outlined,
                          'Full Name',
                          userData['fullName'] ?? 'Not available',
                        ),
                        const SizedBox(height: 16),
                        _buildInfoRow(
                          Icons.email_outlined,
                          'Email Address',
                          userData['email'] ?? 'Not available',
                        ),
                        const SizedBox(height: 16),
                        _buildInfoRow(
                          Icons.phone_outlined,
                          'Phone Number',
                          userData['phone'] ?? 'Not available',
                        ),
                        const SizedBox(height: 16),
                        _buildInfoRow(
                          Icons.calendar_today_outlined,
                          'Member Since',
                          userData['createdAt'] != null
                              ? _formatDate(
                                  DateTime.parse(userData['createdAt']),
                                )
                              : 'Unknown',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Action Buttons
                  Column(
                    children: [
                      // Edit Profile Button
                      Container(
                        width: double.infinity,
                        height: 56,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          gradient: LinearGradient(
                            colors: [
                              Colors.lightBlue.shade600,
                              Colors.lightBlue.shade400,
                            ],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.lightBlue.shade300.withOpacity(0.4),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: () => _showEditProfileDialog(
                            context,
                            authService,
                            userData,
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.edit_outlined,
                                color: Colors.white,
                                size: 20,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Edit Profile',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Logout Button
                      Container(
                        width: double.infinity,
                        height: 56,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.red.shade300,
                            width: 1.5,
                          ),
                          color: const Color.fromARGB(255, 255, 255, 255),
                        ),
                        child: TextButton(
                          onPressed: () =>
                              _showLogoutDialog(context, authService),
                          style: TextButton.styleFrom(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.logout_rounded,
                                color: Colors.red.shade600,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Sign Out',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.red.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: Colors.grey.shade600),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getInitials(String name) {
    return name
        .split(' ')
        .map((word) => word.isNotEmpty ? word[0].toUpperCase() : '')
        .take(2)
        .join('');
  }

  String _formatDate(DateTime date) => '${date.day}/${date.month}/${date.year}';

  void _showEditProfileDialog(
    BuildContext context,
    AuthService authService,
    Map<String, dynamic> userData,
  ) {
    final nameController = TextEditingController(text: userData['fullName']);
    final phoneController = TextEditingController(text: userData['phone']);
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.lightBlue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.edit_outlined,
                color: Colors.lightBlue.shade600,
                size: 20,
              ),
            ),
            const SizedBox(width: 23),
            const Text('Edit Profile', style: TextStyle(fontSize: 19)),
            const SizedBox(height: 50),
          ],
        ),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'Full Name',
                  prefixIcon: const Icon(Icons.person_outline),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Colors.lightBlue.shade600,
                      width: 2,
                    ),
                  ),
                ),
                validator: (value) =>
                    value?.isEmpty == true ? 'Name is required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: phoneController,
                decoration: InputDecoration(
                  labelText: 'Phone Number',
                  prefixIcon: const Icon(Icons.phone_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: Colors.lightBlue.shade600,
                      width: 2,
                    ),
                  ),
                ),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value?.isEmpty == true) return 'Phone number is required';
                  if (!RegExp(r'^[0-9]{10,11}$').hasMatch(value!)) {
                    return 'Please enter a valid phone number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState!.validate()) {
                final error = await authService.updateProfile(
                  fullName: nameController.text.trim(),
                  phone: phoneController.text.trim(),
                );

                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          Icon(
                            error != null
                                ? Icons.error_outline
                                : Icons.check_circle_outline,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              error ?? 'Profile updated successfully!',
                            ),
                          ),
                        ],
                      ),
                      backgroundColor: error != null
                          ? Colors.red.shade600
                          : Colors.green.shade600,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.lightBlue.shade600,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Save Changes',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, AuthService authService) async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.white,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.logout_rounded,
                color: Colors.red.shade600,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Text('Sign Out'),
          ],
        ),
        content: const Text(
          'Are you sure you want to sign out? You will need to log in again to access your account.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: TextStyle(color: Colors.grey.shade600),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Sign Out',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );

    if (shouldLogout == true) await authService.signOut();
  }
}
