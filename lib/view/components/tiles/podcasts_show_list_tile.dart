import 'package:flutter/material.dart';
import 'package:fountain_tech_test/data/podcast_index_dot_org.dart';
import 'package:fountain_tech_test/domain/account.dart';
import 'package:fountain_tech_test/domain/audio_player.dart';
import 'package:fountain_tech_test/main.dart';
import 'package:fountain_tech_test/view/podcast_show_page.dart';

class PodcastShowListTile extends StatelessWidget {
  const PodcastShowListTile({
    Key? key,
    required this.show,
    required this.account,
    required AudioPlayer audioPlayer,
  })  : _audioPlayer = audioPlayer,
        super(key: key);

  final PodcastShow show;
  final Account account;
  final AudioPlayer _audioPlayer;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: () async {
        await Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute<void>(
            builder: (BuildContext context) => PodcastShowPage(
              account: account,
              show: show,
              audioPlayer: _audioPlayer,
            ),
          ),
          ModalRoute.withName('/'),
        );
      },
      leading: Hero(
        tag: "podcast_image" + show.id(),
        child: Image.network(
          show.image(),
          height: 50,
          width: 50,
          errorBuilder: (_, __, ___) => const SizedBox.shrink(),
        ),
      ),
      title: Text(
        show.title(),
        maxLines: 2,
      ),
      subtitle: Text(
        show.desc(),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
