import 'package:flutter/material.dart';
import 'package:fountain_tech_test/domain/account.dart';
import 'package:intl/intl.dart' as DF;

class AccountPage extends StatelessWidget {
  final Account account;
  const AccountPage({required this.account, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 15.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 30, bottom: 25),
            child: Text(
              "Your account",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
            ),
          ),
          const SizedBox(height: 20),
          accountInfoTile(title: "Name", value: account.name),
          const SizedBox(height: 15),
          accountInfoTile(
            title: "Date joined",
            value: DF.DateFormat("MMMMd").format(
              account.createdOn,
            ),
          ),
        ],
      ),
    );
  }

  Column accountInfoTile({
    required String title,
    required String value,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: TextStyle(fontSize: 16)),
        const SizedBox(height: 5),
        Text(
          value,
          style: TextStyle(color: Colors.grey),
        )
      ],
    );
  }
}
