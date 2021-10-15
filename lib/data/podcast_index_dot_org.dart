import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:convert/convert.dart';

const kPodcastIndexDotOrgKey = "YUJ4EZWCM4YTE8WBH4XC";
const kPodcastIndexDotOrgSecret = "uAUWEXa2gKgm5Hmv^2U9fBTnLSbH3ZfZdvXFGPF9";

class PodcastIndexDotOrgRepo {
  Future<List<PodcastShow>> search(String query) async {
    var res = await http.get(
      Uri.parse(
        "https://api.podcastindex.org/api/1.0/search/byterm?q=${query.toLowerCase()}",
      ),
      headers: _defaultHeaders(),
    );
    final decoded = const JsonDecoder().convert(res.body);

    return res.statusCode == 200
        ? (decoded["feeds"] as List)
            .map((feed) => JsonPodcastShow(feed))
            .toList()
        : [];
  }

  Future<List<PodcastEpisode>> episodes({required String fromId}) async {
    var res = await http.get(
      Uri.parse(
        "https://api.podcastindex.org/api/1.0/episodes/byfeedid?id=$fromId",
      ),
      headers: _defaultHeaders(),
    );
    final decoded = const JsonDecoder().convert(res.body);

    return res.statusCode == 200
        ? (decoded["items"] as List)
            .map((episode) => JSONPodcastEpisode(episode))
            .toList()
        : [];
  }

  Future<List<PodcastShow>> newShows() async {
    var res = await http.get(
      Uri.parse(
        "https://api.podcastindex.org/api/1.0/podcasts/trending?pretty&lang=en",
      ),
      headers: _defaultHeaders(),
    );
    if (res.statusCode != 200) {
      return [];
    }
    final decoded = const JsonDecoder().convert(res.body);
    final List<dynamic> feeds = decoded["feeds"];
    try {
      final shows = await Future.wait(
        feeds.map(
          (feed) => getShowbyId(feed["id"].toString()),
        ),
      );
      return shows;
    } catch (e) {
      print(e);
      return [];
    }
  }

  Future<PodcastShow> getShowbyId(String id) async {
    var res = await http.get(
      Uri.parse(
        "https://api.podcastindex.org/api/1.0/podcasts/byfeedid?id=$id",
      ),
      headers: _defaultHeaders(),
    );
    if (res.statusCode != 200) {
      throw Error();
    }
    var res2 = const JsonDecoder().convert(res.body);
    return JsonPodcastShow(res2["feed"]);
  }

  Map<String, String> _defaultHeaders() {
    var unixTime = (DateTime.now().millisecondsSinceEpoch / 1000).round();
    String newUnixTime = unixTime.toString();

    var apiKey = kPodcastIndexDotOrgKey;
    var apiSecret = kPodcastIndexDotOrgSecret;

    var firstChunk = utf8.encode(apiKey);
    var secondChunk = utf8.encode(apiSecret);
    var thirdChunk = utf8.encode(newUnixTime);

    var output = AccumulatorSink<Digest>();
    final input = sha1.startChunkedConversion(output);
    input.add(firstChunk);
    input.add(secondChunk);
    input.add(thirdChunk);
    input.close();
    var digest = output.events.single;

    return {
      "X-Auth-Date": newUnixTime,
      "X-Auth-Key": apiKey,
      "Authorization": digest.toString(),
      "User-Agent": "fountain_tech_test/0.0.1"
    };
  }
}

class JsonPodcastShow implements PodcastShow {
  final Map<String, dynamic> _feed;
  JsonPodcastShow(feed) : _feed = feed;

  id() {
    return _feed["id"].toString();
  }

  title() {
    return _feed["title"] ?? '';
  }

  ownerName() {
    return _feed["ownerName"] ?? '';
  }

  image() {
    return _feed["image"] ?? '';
  }

  String desc() {
    return _feed["description"] ?? '';
  }

  bool isTheSameAs(PodcastShow show) {
    return show.id() == id();
  }
}

abstract class PodcastShow {
  String id();
  String title();
  String ownerName();
  String image();
  String desc();
  bool isTheSameAs(PodcastShow show);
}

abstract class PodcastEpisode {
  String id();
  String title();
  String enclosureUrl();
  String image();
  String desc();
  int? episodeNum();
  num? duration();
  String datePublished();
}

class JSONPodcastEpisode implements PodcastEpisode {
  final Map<String, dynamic> _episode;

  JSONPodcastEpisode(episode) : _episode = episode;

  id() {
    return _episode["id"].toString();
  }

  title() {
    return _episode["title"];
  }

  enclosureUrl() {
    return _episode["enclosureUrl"];
  }

  image() {
    return _episode["image"];
  }

  String desc() {
    return _episode["description"];
  }

  int? episodeNum() {
    return _episode["episode"];
  }

  num? duration() {
    return _episode["duration"];
  }

  String datePublished() {
    return _episode["datePublishedPretty"];
  }
}
