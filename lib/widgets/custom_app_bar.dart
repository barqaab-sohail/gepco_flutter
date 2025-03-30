import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String? pictureUrl;
  final VoidCallback onLogout;

  const CustomAppBar({
    super.key,
    required this.title,
    this.pictureUrl,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.blue,
      elevation: 0,
      title: Text(title, style: TextStyle(color: Colors.white)),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 10),
          child: PopupMenuButton<String>(
            onSelected: (value) {
              if (value == "logout") {
                onLogout();
                print("User logged out");
              }
            },
            itemBuilder:
                (context) => [
                  PopupMenuItem(
                    value: "logout",
                    child: Row(
                      children: [
                        Icon(Icons.logout, color: Colors.red),
                        SizedBox(width: 10),
                        Text("Logout", style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
            child: CircleAvatar(
              backgroundImage:
                  pictureUrl != null && pictureUrl!.isNotEmpty
                      ? NetworkImage(pictureUrl!)
                      : AssetImage("images/default.png") as ImageProvider,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(kToolbarHeight);
}
