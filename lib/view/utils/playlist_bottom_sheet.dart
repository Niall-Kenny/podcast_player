import 'package:flutter/material.dart';

class AddPlaylistBottomSheet extends StatelessWidget {
  AddPlaylistBottomSheet({
    required this.textController,
    Key? key,
  }) : super(key: key);

  final _key = GlobalKey<FormState>();
  final TextEditingController textController;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height,
      decoration: BoxDecoration(
          gradient: LinearGradient(
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
        stops: const [
          0.1,
          0.6,
        ],
        colors: [
          Colors.grey[700]!,
          Colors.grey,
        ],
      )),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const SizedBox(height: 20),
          const Text(
            "Give your playlist a name.",
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 40),
          SizedBox(
            width: MediaQuery.of(context).size.width * .8,
            child: Form(
              child: TextFormField(
                style: const TextStyle(
                  fontSize: 26,
                  color: Colors.white,
                ),
                onChanged: (str) {},
                validator: (str) {},
                controller: textController,
                keyboardType: TextInputType.text,
                decoration: InputDecoration(
                  enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(
                      color: Colors.grey[400]!,
                      width: 2,
                    ),
                  ),
                  hintText: "#Tim Ferriss Top 10",
                  hintStyle: const TextStyle(color: Colors.white),
                ),
              ),
            ),
          ),
          const SizedBox(height: 30),
          ElevatedButton(
            style: ElevatedButton.styleFrom(primary: Colors.white),
            child: const Text(
              'Create',
              style: TextStyle(
                fontSize: 18,
                color: Colors.black,
              ),
            ),
            onPressed: () {
              if (textController.text.isNotEmpty) {
                Navigator.pop(
                  context,
                  textController.text,
                );
              }
              textController.clear();
            },
          ),
        ],
      ),
    );
  }
}
