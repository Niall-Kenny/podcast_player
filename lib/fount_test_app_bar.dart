import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

final KPodcastData = {
  "show": {
    "title": "Podcasting 2.0",
    "publisher": "Podcast Index LLC",
    "image": "https://api.podcastindex.org/images/pci_avatar.jpg",
    "description":
        "The Podcast Index presents Podcasting 2.0 - Upgrading Podcasting",
    "link": "https://podcastindex.org",
    "following": false,
  }
};

class PodcastShow {
  final Map _data;
  const PodcastShow(Map<String, dynamic> show) : _data = show;

  title() {
    return _getProperty("title");
  }

  image() {
    return _getProperty("image");
  }

  publisher() {
    return _getProperty("publisher");
  }

  link() {
    return _getProperty("link");
  }

  description() {
    return _getProperty("description");
  }

  _getProperty(String property) {
    return _data["show"][property];
  }
}

/// text scale factor clamped from 1 - 1.5
class HomePage extends StatefulWidget {
  final PodcastShow show;
  const HomePage({required this.show, Key? key}) : super(key: key);

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _following = false;

  @override
  Widget build(BuildContext context) {
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(
        textScaleFactor: createTextScaleFactor(context),
      ),
      child: Scaffold(
        appBar: AppBar(
          elevation: 0,
          title: const Center(
            child: Text(
              "PODCAST",
              style: TextStyle(fontSize: 14, fontStyle: FontStyle.italic),
            ),
          ),
          bottom: PreferredSize(
            child: podcastHeader(),
            preferredSize: const Size.fromHeight(140.0),
          ),
        ),
        body: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const <Widget>[],
          ),
        ),
      ),
    );
  }

  Widget podcastHeader() {
    return SizedBox(
      width: double.infinity,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Column(
              children: [
                Image.network(
                  "https://api.podcastindex.org/images/pci_avatar.jpg",
                  height: 100,
                  width: 100,
                ),
                SizedBox(
                  width: 100,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      primary: Colors.black,
                    ),
                    child: Text(
                      _following ? "Following" : "Follow",
                      style: const TextStyle(color: Colors.white),
                      textAlign: TextAlign.center,
                      textScaleFactor: MediaQuery.of(context)
                          .textScaleFactor
                          .clamp(1.0, 1.15),
                    ),
                    onPressed: () {
                      setState(() {
                        _following = !_following;
                      });
                    },
                  ),
                )
              ],
            ),
          ),
          Flexible(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.show.title(),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  widget.show.publisher(),
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
                InkWell(
                    onTap: () async {
                      await launchUrl(widget.show.link());
                    },
                    child: Text(
                      widget.show.link(),
                      style: const TextStyle(color: Colors.blue),
                    )),
                Text(widget.show.description())
              ],
            ),
          )
        ],
      ),
    );
  }

  Future<void> launchUrl(String url) async {
    if (await canLaunch(url)) {
      await launch(
        url,
        forceSafariVC: false,
      );
    }
  }
}

double createTextScaleFactor(BuildContext context) {
  return MediaQuery.of(context).textScaleFactor.clamp(1.0, 1.5);
}
