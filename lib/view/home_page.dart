import 'package:flutter/material.dart';
import 'package:fountain_tech_test/data/podcast_index_dot_org.dart';
import 'package:fountain_tech_test/domain/account.dart';
import 'package:fountain_tech_test/main.dart';
import 'package:fountain_tech_test/view/episode_page.dart';
import 'package:fountain_tech_test/view/podcast_show_page.dart';
import 'package:fountain_tech_test/view/utils/tiles/podcasts_show_list_tile.dart';

class HomePage extends StatelessWidget {
  final Account account;
  final AudioPlayer audioPlayer;
  final BottomNavigationState bottomNavigationState;
  const HomePage({
    required this.account,
    required this.audioPlayer,
    required this.bottomNavigationState,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.only(left: 15.0, top: 30, bottom: 25),
          child: Text(
            "Hey ${account.name[0].toUpperCase() + account.name.substring(1)}!",
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
          ),
        ),
        const Padding(
          padding: EdgeInsets.only(left: 15.0),
          child: Text(
            "Recommended shows for you this week",
            style: TextStyle(color: Colors.grey),
          ),
        ),
        const SizedBox(height: 15),
        FutureBuilder<List<PodcastShow>>(
            future: PodcastIndexDotOrgRepo().newShows(),
            initialData: const [],
            builder: (context, snapshot) {
              final shows = snapshot.data ?? [];
              final _showsToDisplay = shows
                  .where((s) => s.title().isNotEmpty && s.image().isNotEmpty)
                  .toList();
              return SizedBox(
                height: 180,
                child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _showsToDisplay.length,
                    itemBuilder: (context, index) {
                      final show = _showsToDisplay[index];
                      return InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute<void>(
                              builder: (BuildContext context) =>
                                  PodcastShowPage(
                                account: account,
                                show: show,
                                audioPlayer: audioPlayer,
                              ),
                            ),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.only(left: 15.0),
                          child: SizedBox(
                            width: 120,
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Hero(
                                  tag: "podcast_image" + show.id(),
                                  child: Image.network(
                                    show.image(),
                                    width: 120,
                                    height: 120,
                                    errorBuilder: (_, __, ___) => Container(
                                      width: 120,
                                      height: 120,
                                      decoration: BoxDecoration(
                                          color: Colors.grey[900]),
                                    ),
                                  ),
                                ),
                                const SizedBox(
                                  height: 10,
                                ),
                                Text(
                                  show.title(),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                )
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
              );
            }),
        const SizedBox(height: 20),
        StreamBuilder(
          stream: audioPlayer.playHistroyStream(),
          builder: (context, snapshot) {
            final listeningHistory = audioPlayer.playHistroy();
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                seeAllRowTitle(
                    title: "Recently played",
                    shouldDisplaySeeAll: listeningHistory.isNotEmpty,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (BuildContext context) => SeeAll(
                            title: "Recently played",
                            itemCount: listeningHistory.length,
                            itemBuilder: (context, index) =>
                                PodcastEpisodeListItemTile(
                              episode:
                                  listeningHistory.reversed.toList()[index],
                              audioPlayer: audioPlayer,
                              account: account,
                            ),
                          ),
                        ),
                      );
                    }),
                if (listeningHistory.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 40.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        OutlinedButton(
                          onPressed: () {
                            _navigateToDiscoverPage();
                          },
                          child: const Text("Find podcasts now"),
                        )
                      ],
                    ),
                  ),
                ListView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  itemCount:
                      listeningHistory.length < 5 ? listeningHistory.length : 5,
                  itemBuilder: (context, indexInHistoryList) {
                    final episode = listeningHistory[indexInHistoryList];
                    return ListTile(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute<void>(
                            builder: (BuildContext context) => EpisodePage(
                              episode: episode,
                              audioPlayer: audioPlayer,
                              account: account,
                            ),
                          ),
                        );
                      },
                      leading: Image.network(
                        episode.image(),
                        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                      ),
                      title: Text(
                        episode.title(),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  },
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 40),
        StreamBuilder<List<PodcastShow>>(
            stream: account.latestShowFollowing,
            builder: (context, snapshot) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  seeAllRowTitle(
                      title: "Following",
                      shouldDisplaySeeAll: account.following.isNotEmpty,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute<void>(
                            builder: (BuildContext context) => SeeAll(
                              title: "Following",
                              itemCount: account.following.length,
                              itemBuilder: (context, index) =>
                                  PodcastShowListTile(
                                account: account,
                                show:
                                    account.following.reversed.toList()[index],
                                audioPlayer: audioPlayer,
                              ),
                            ),
                          ),
                        );
                      }),
                  if (account.following.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 40.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          OutlinedButton(
                            onPressed: () {
                              _navigateToDiscoverPage();
                            },
                            child: const Text("Find shows to follow"),
                          )
                        ],
                      ),
                    ),
                  ListView.separated(
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    itemCount: account.following.length,
                    separatorBuilder: (context, index) => const Divider(),
                    itemBuilder: (context, indexInPodcastList) {
                      final podcast = account.following.reversed
                          .toList()[indexInPodcastList];
                      return ListTile(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute<void>(
                              builder: (BuildContext context) =>
                                  PodcastShowPage(
                                account: account,
                                show: account.following.reversed
                                    .toList()[indexInPodcastList],
                                audioPlayer: audioPlayer,
                                heroTag: "podcast_image" +
                                    podcast.id() +
                                    indexInPodcastList.toString(),
                              ),
                            ),
                          );
                        },
                        leading: Hero(
                          tag: "podcast_image" +
                              podcast.id() +
                              indexInPodcastList.toString(),
                          child: Image.network(
                            podcast.image(),
                            errorBuilder: (_, __, ___) =>
                                const SizedBox.shrink(),
                          ),
                        ),
                        title: Text(podcast.title()),
                      );
                    },
                  ),
                  const SizedBox(
                    height: 100,
                  )
                ],
              );
            })
      ]),
    );
  }

  _navigateToDiscoverPage() {
    bottomNavigationState.updateTo(1);
  }

  seeAllRowTitle({
    required String title,
    void Function()? onTap,
    shouldDisplaySeeAll = true,
  }) {
    return Padding(
      padding: const EdgeInsets.only(left: 15.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          if (shouldDisplaySeeAll)
            TextButton(onPressed: onTap ?? () {}, child: const Text("See All"))
        ],
      ),
    );
  }
}
