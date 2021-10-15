import 'dart:async';
import 'dart:math';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:fountain_tech_test/domain/playlist.dart';
import 'package:fountain_tech_test/view/episode_page.dart';
import 'package:fountain_tech_test/view/playlists_page.dart';
import 'package:intl/intl.dart' as DF;
import 'package:palette_generator/palette_generator.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fountain_tech_test/data/podcast_index_dot_org.dart';
import 'package:fountain_tech_test/fount_test_app_bar.dart';
import 'package:just_audio/just_audio.dart' as JA;
import 'package:rxdart/rxdart.dart';
import 'package:rxdart/subjects.dart';
import 'package:rxdart/transformers.dart';
import 'dart:ui' as ui;

class PlatformBrightness {
  static isLightMode(BuildContext context) {
    return MediaQuery.of(context).platformBrightness == Brightness.light;
  }
}

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      // theme: ThemeData.dark(),
      // home: HomePage(
      //   show: PodcastShow(KPodcastData),
      // ),
      theme: ThemeData(
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
      ),
      home: LandingPage(
        audioPlayer: AudioPlayer(
          audioPlayer: JA.AudioPlayer(),
        ),
      ),
    );
  }
}

class Account {
  final String _name;
  final DateTime _createdOn;
  final BehaviorSubject<List<PodcastShow>> _latestShowFollowing =
      BehaviorSubject.seeded([]);

  final BehaviorSubject<List<Playlist>> _latestPlaylists =
      BehaviorSubject.seeded([]);
  Account(String name)
      : _name = name,
        _createdOn = DateTime.now();

  String get name => _name;
  DateTime get createdOn => _createdOn;

  List<PodcastShow> get following => [..._latestShowFollowing.value];

  Stream<List<PodcastShow>> get latestShowFollowing {
    return _latestShowFollowing;
  }

  bool isFollowing(PodcastShow show) {
    return following.any((s) => s.isTheSameAs(show));
  }

  void follow(PodcastShow show) {
    _latestShowFollowing.add([..._latestShowFollowing.value, show]);
  }

  void unfollow(PodcastShow show) {
    _latestShowFollowing
        .add(following.where((s) => !s.isTheSameAs(show)).toList());
  }

  /// stream of latest playlist collection
  Stream<List<Playlist>> get latestPlaylists {
    return _latestPlaylists;
  }

  createPlaylist({required String title}) {
    _latestPlaylists.add([..._latestPlaylists.value, Playlist(title: title)]);
  }
}

enum NavigatedBy { swipe, navBar }

class BottomNavigationState {
  final PageController pageController;
  BottomNavigationState({required this.pageController});
  final BehaviorSubject<int> _stream = BehaviorSubject.seeded(0);
  int get current => _stream.value;
  Stream<int> get latest => _stream;
  updateTo(int index, {NavigatedBy navigatedBy = NavigatedBy.navBar}) {
    _stream.add(index);
    if (navigatedBy == NavigatedBy.navBar) {
      pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> dispose() async {
    await _stream.close();
  }
}

class LandingPage extends StatefulWidget {
  final AudioPlayer audioPlayer;
  const LandingPage({required this.audioPlayer, Key? key}) : super(key: key);

  @override
  LandingPageState createState() => LandingPageState();
}

class LandingPageState extends State<LandingPage> {
  final formKey = GlobalKey<FormState>();
  late final BottomNavigationState bottomNavigationState;
  late TextEditingController nameController;
  late Future<Duration?> duration;
  Account? account;
  late PageController pageController;
  bool isShowingPodcastPlayBar = false;
  late TextEditingController playlistNameController;

  @override
  void initState() {
    nameController = TextEditingController();
    playlistNameController = TextEditingController();
    pageController = PageController();
    bottomNavigationState =
        BottomNavigationState(pageController: pageController);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(
        textScaleFactor: createTextScaleFactor(context),
      ),
      child: Scaffold(
        floatingActionButton: StreamBuilder<int>(
            stream: bottomNavigationState.latest,
            initialData: 0,
            builder: (context, snapshot) {
              final pageIndex = snapshot.data!;
              final isPlaylistPage = pageIndex == 2;
              if (isPlaylistPage) {
                return Padding(
                  padding: EdgeInsets.only(
                      bottom: isShowingPodcastPlayBar ? 40.0 : 0),
                  child: FloatingActionButton(
                      backgroundColor: Colors.blue,
                      child: const Icon(Icons.add),
                      onPressed: () async {
                        final playlistName = await showModalBottomSheet<String>(
                          context: context,
                          builder: (BuildContext context) {
                            return AddPlaylistBottomSheet(
                              textController: playlistNameController,
                            );
                          },
                        );
                        if (playlistName != null) {
                          account!.createPlaylist(title: playlistName);
                        }
                      }),
                );
              }
              return const SizedBox.shrink();
            }),
        bottomSheet: audioPlayerBar(),
        bottomNavigationBar: accountHasBeenCreated()
            ? StreamBuilder<int>(
                stream: bottomNavigationState.latest,
                initialData: 0,
                builder: (context, snapshot) {
                  return BottomNavigationBar(
                    selectedItemColor: Colors.blue,
                    type: BottomNavigationBarType.fixed,
                    currentIndex: snapshot.data!,
                    onTap: onBottomNavBarTap,
                    items: const [
                      BottomNavigationBarItem(
                        label: "home",
                        icon: Icon(Icons.home_outlined),
                      ),
                      BottomNavigationBarItem(
                        label: "Discover",
                        icon: Icon(Icons.explore_outlined),
                      ),
                      BottomNavigationBarItem(
                        label: "Playlists",
                        icon: Icon(Icons.list),
                      ),
                      BottomNavigationBarItem(
                        label: "Account",
                        icon: Icon(Icons.person_outline),
                      )
                    ],
                  );
                })
            : null,
        body: accountHasBeenCreated() ? loggedInView() : welcomePage(),
      ),
    );
  }

  audioPlayerBar() {
    return StreamBuilder<PodcastEpisode?>(
      initialData: null,
      stream: widget.audioPlayer.currentEpisodeStreaming(),
      builder: (context, snapshot) {
        var episode = snapshot.data;
        isShowingPodcastPlayBar = episode != null;
        if (episode == null) {
          return const SizedBox.shrink();
        }

        return InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (BuildContext context) => EpisodePage(
                  account: account!,
                  audioPlayer: widget.audioPlayer,
                  episode: episode,
                  tag: "podcast_image" + episode.id(),
                ),
              ),
            );
          },
          child: Container(
            color: Colors.grey[900],
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Row(
                    children: [
                      const SizedBox(
                        width: 5,
                      ),
                      Hero(
                        tag: "podcast_image" + episode.id(),
                        child: Image.network(
                          episode.image(),
                          height: 40,
                          width: 40,
                          errorBuilder: (_, __, ___) => const SizedBox(
                            height: 40,
                          ),
                        ),
                      ),
                      const SizedBox(
                        width: 5,
                      ),
                      Flexible(
                        child: Text(episode.title(),
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                      ),
                    ],
                  ),
                ),
                PlayAndPauseButton(
                  audioPlayer: widget.audioPlayer,
                  episode: episode,
                ),
                const SizedBox(
                  width: 15,
                )
              ],
            ),
          ),
        );
      },
    );
  }

  void onBottomNavBarTap(int index) {
    bottomNavigationState.updateTo(index);
  }

  welcomePage() {
    return SingleChildScrollView(
      child: Stack(
        children: [
          Image.asset(
            "assets/images/landing_image_${PlatformBrightness.isLightMode(context) ? "light" : "dark"}.png",
            width: double.infinity,
          ),
          SizedBox(
            height: MediaQuery.of(context).size.height,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Spacer(
                  flex: 3,
                ),
                const Text(
                  "Well Crafted and Curated Podcasts",
                  style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const Padding(
                  padding: EdgeInsets.only(top: 16.0),
                  child: Text(
                    "A social podcast player that makes great audio content discoverable.",
                    textAlign: TextAlign.center,
                  ),
                ),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                  child: SizedBox(
                    child: Form(
                      key: formKey,
                      child: TextFormField(
                        onChanged: (str) => formKey.currentState?.validate(),
                        validator: (str) =>
                            nameIsValid(str) ? null : "Please input your name",
                        controller: nameController,
                        decoration: const InputDecoration(
                          border: UnderlineInputBorder(),
                          labelText: 'Enter your name',
                        ),
                      ),
                    ),
                  ),
                ),
                Center(
                  child: TextButton(
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.all(16.0),
                      primary: Colors.white,
                      textStyle: const TextStyle(fontSize: 20),
                    ),
                    onPressed: () {
                      final formIsValid = formKey.currentState!.validate();

                      if (formIsValid) {
                        createAccount(nameController.text);
                      }
                    },
                    child: Text(
                      "Get started",
                      style: TextStyle(
                        color: PlatformBrightness.isLightMode(context)
                            ? Colors.black
                            : Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(
                  height: 50,
                ),
                const Spacer(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  bool nameIsValid(String? name) {
    return name != null && name.isNotEmpty;
  }

  void createAccount(String name) {
    setState(() {
      account = Account(name);
    });
  }

  bool accountHasBeenCreated() {
    return account != null;
  }

  Widget loggedInView() {
    return SafeArea(
      child: PageView(
        onPageChanged: (value) {
          if (bottomNavigationState.current != value) {
            bottomNavigationState.updateTo(
              value,
              navigatedBy: NavigatedBy.swipe,
            );
          }
        },
        controller: pageController,
        children: [
          _HomePage(
            account: account!,
            audioPlayer: widget.audioPlayer,
            bottomNavigationState: bottomNavigationState,
          ),
          _DiscoverPage(
            audioPlayer: widget.audioPlayer,
            account: account!,
          ),
          PlaylistsPage(
            account: account!,
            audioPlayer: widget.audioPlayer,
          ),
          _AccountPage(
            account: account!,
          ),
        ],
      ),
    );
  }

  @override
  void reassemble() {
    super.reassemble();
    widget.audioPlayer.dispose();
  }

  @override
  void dispose() {
    super.dispose();
    nameController.dispose();
    pageController.dispose();
    widget.audioPlayer.dispose();
  }
}

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

class _HomePage extends StatelessWidget {
  final Account account;
  final AudioPlayer audioPlayer;
  final BottomNavigationState bottomNavigationState;
  const _HomePage({
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
                                PodcastListItemTile(
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

class _DiscoverPage extends StatelessWidget {
  final AudioPlayer audioPlayer;
  final Account account;
  const _DiscoverPage({
    required this.audioPlayer,
    required this.account,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 14.0),
            child: searchBar(context),
          ),
        ],
      ),
    );
  }

  Widget searchBar(BuildContext context) {
    return InkWell(
      onTap: () {
        showSearch(
            context: context,
            delegate:
                _SearchDelegate(audioPlayer: audioPlayer, account: account));
      },
      child: Container(
        width: double.infinity,
        height: 42,
        decoration: BoxDecoration(
          color: searchBarColor(context),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: const [
            SizedBox(width: 18),
            Icon(Icons.search),
            SizedBox(width: 8),
            Text(
              "Search",
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }

  Color searchBarColor(BuildContext context) {
    return PlatformBrightness.isLightMode(context)
        ? Colors.grey[300]!
        : Colors.grey[900]!;
  }
}

class _AccountPage extends StatelessWidget {
  final Account account;
  const _AccountPage({required this.account, Key? key}) : super(key: key);

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

class _SearchDelegate extends SearchDelegate {
  final Account _account;
  final AudioPlayer _audioPlayer;
  final StreamController<String> _queryController =
      StreamController.broadcast();
  late Widget _searchResults;

  _SearchDelegate({required AudioPlayer audioPlayer, required Account account})
      : _audioPlayer = audioPlayer,
        _account = account {
    _searchResults = _buildSearchList();
  }

  StreamBuilder<List<PodcastShow>> _buildSearchList() {
    final _repo = PodcastIndexDotOrgRepo();

    return StreamBuilder<List<PodcastShow>>(
      stream: _queryController.stream
          .debounceTime(const Duration(milliseconds: 500))
          .asyncMap(_repo.search),
      initialData: const [],
      builder: (context, snapshot) {
        var shows = snapshot.data!;
        return ListView.builder(
          itemCount: shows.length,
          itemBuilder: (context, index) {
            var show = shows[index];
            return PodcastShowListTile(
              show: show,
              audioPlayer: _audioPlayer,
              account: _account,
            );
          },
        );
      },
    );
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
        onPressed: () {
          close(context, null);
        },
        icon: const BackButtonIcon());
  }

  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      IconButton(
          onPressed: () {
            query = '';
          },
          icon: const Icon(Icons.clear))
    ];
  }

  @override
  Widget buildResults(BuildContext context) {
    return _searchResults;
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    _queryController.add(query);
    return _searchResults;
  }
}

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

class PodcastShowPage extends StatefulWidget {
  final PodcastShow show;
  final NetworkImage image;
  final AudioPlayer audioPlayer;
  final Account account;
  final String? heroTag;
  PodcastShowPage({
    required this.show,
    required this.audioPlayer,
    required this.account,
    this.heroTag,
    Key? key,
  })  : image = NetworkImage(show.image()),
        super(key: key);

  @override
  State<PodcastShowPage> createState() => _PodcastShowPageState();
}

class _PodcastShowPageState extends State<PodcastShowPage> {
  bool seeFullDescription = false;
  late Future<List<PodcastEpisode>> episodes;

  @override
  void initState() {
    episodes = PodcastIndexDotOrgRepo().episodes(fromId: widget.show.id());
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(
        textScaleFactor: createTextScaleFactor(context),
      ),
      child: Scaffold(
        body: SafeArea(
          child: FutureBuilder<Color>(
              future: getBackgroundColor(context),
              initialData: Theme.of(context).scaffoldBackgroundColor,
              builder: (context, snapshot) {
                return SingleChildScrollView(
                  child: Stack(
                    children: [
                      Container(
                        height: 130 + kToolbarHeight,
                        width: double.infinity,
                        color: snapshot.data,
                      ),
                      Column(
                        children: [
                          const SizedBox(
                            height: 80,
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Hero(
                                tag: widget.heroTag != null
                                    ? widget.heroTag!
                                    : "podcast_image" + widget.show.id(),
                                child: Image(
                                  image: NetworkImage(widget.show.image()),
                                  height: 180,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(
                            height: 20,
                          ),
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 24.0),
                            child: Text(
                              widget.show.title(),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          if (widget.show.ownerName().isNotEmpty)
                            const SizedBox(
                              height: 10,
                            ),
                          if (widget.show.ownerName().isNotEmpty)
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 24.0),
                              child: Text(
                                widget.show.ownerName(),
                                style: const TextStyle(
                                  fontSize: 14,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          const SizedBox(
                            height: 10,
                          ),
                          Row(
                            children: [
                              const Spacer(),
                              followUnfollowButton(),
                              const Spacer(),
                            ],
                          ),
                          const SizedBox(
                            height: 20,
                          ),
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 8.0),
                            child: description(context),
                          ),
                          const SizedBox(
                            height: 30,
                          ),
                          Row(
                            children: const [
                              SizedBox(
                                width: 8,
                              ),
                              Text(
                                "Episodes",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(
                            height: 8,
                          ),
                          FutureBuilder<List<PodcastEpisode>>(
                              future: episodes,
                              initialData: const [],
                              builder: (context, snapshot) {
                                return ListView.separated(
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    shrinkWrap: true,
                                    itemCount: snapshot.data!.length,
                                    separatorBuilder: (context, index) =>
                                        const Divider(),
                                    itemBuilder: (context, index) {
                                      final episode = snapshot.data![index];
                                      return PodcastListItemTile(
                                        episode: episode,
                                        audioPlayer: widget.audioPlayer,
                                        account: widget.account,
                                      );
                                    });
                              })
                        ],
                      ),
                    ],
                  ),
                );
              }),
        ),
      ),
    );
  }

  ElevatedButton followUnfollowButton() {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
          elevation: 0,
          primary: PlatformBrightness.isLightMode(context)
              ? Colors.black
              : Colors.white),
      onPressed: () {
        setState(() {
          followUnfollowButtonDisplay(
            isFollowingDisplay: () => widget.account.unfollow(widget.show),
            isNotFollowingDisplay: () => widget.account.follow(widget.show),
          )();
        });
      },
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(
          followUnfollowButtonDisplay(
            isFollowingDisplay: Icons.remove_circle_outline,
            isNotFollowingDisplay: Icons.add,
          ),
          color: PlatformBrightness.isLightMode(context)
              ? Colors.white
              : Colors.black,
        ),
        const SizedBox(width: 5),
        Text(
          followUnfollowButtonDisplay(
            isFollowingDisplay: "Unfollow show",
            isNotFollowingDisplay: "Follow show",
          ),
          style: TextStyle(
            color: PlatformBrightness.isLightMode(context)
                ? Colors.white
                : Colors.black,
            fontSize: 18,
          ),
        ),
      ]),
    );
  }

  T followUnfollowButtonDisplay<T>({
    required T isFollowingDisplay,
    required T isNotFollowingDisplay,
  }) {
    return widget.account.isFollowing(widget.show)
        ? isFollowingDisplay
        : isNotFollowingDisplay;
  }

  Widget description(BuildContext context) {
    return Container(
      child: seeFullDescription
          ? RichText(
              text: TextSpan(
                text: widget.show.desc(),
                style: TextStyle(
                  fontSize: MediaQuery.of(context).textScaleFactor * 14,
                  color: Theme.of(context).textTheme.bodyText1!.color,
                ),
                children: [
                  TextSpan(
                    text: " See Less",
                    recognizer: TapGestureRecognizer()
                      ..onTap = () {
                        setState(() {
                          seeFullDescription = false;
                        });
                      },
                    style: TextStyle(
                      color: Theme.of(context).buttonTheme.colorScheme!.primary,
                    ),
                  )
                ],
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.show.desc(),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                if (hasTextOverflowed(
                    text: widget.show.desc(),
                    style: const TextStyle(),
                    maxLines: 4,
                    maxWidth: MediaQuery.of(context).size.width - 16))
                  InkWell(
                    onTap: () {
                      setState(() {
                        seeFullDescription = true;
                      });
                    },
                    child: Text(
                      "See more",
                      style: TextStyle(
                        color:
                            Theme.of(context).buttonTheme.colorScheme!.primary,
                      ),
                    ),
                  ),
              ],
            ),
    );
  }

  Future<Color> getBackgroundColor(context) async {
    var d = await PaletteGenerator.fromImageProvider(
      widget.image,
      maximumColorCount: 20,
    );

    var color = PlatformBrightness.isLightMode(context)
        ? d.lightVibrantColor?.color
        : d.darkVibrantColor?.color;
    return color ?? Theme.of(context).scaffoldBackgroundColor;
  }

  bool hasTextOverflowed({
    required String text,
    required TextStyle style,
    required double maxWidth,
    required maxLines,
    double minWidth = 0,
  }) {
    final TextPainter textPainter = TextPainter(
      text: TextSpan(text: text, style: null),
      maxLines: maxLines,
      textDirection: TextDirection.ltr,
    )..layout(minWidth: minWidth, maxWidth: maxWidth);
    return textPainter.didExceedMaxLines;
  }
}

class PodcastListItemTile extends StatelessWidget {
  final PodcastEpisode episode;
  final AudioPlayer audioPlayer;
  final Account account;
  const PodcastListItemTile({
    required this.episode,
    required this.audioPlayer,
    required this.account,
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
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
      title: Text(
        episodeAndDate(episode),
        style: const TextStyle(
          fontSize: 12,
          color: Colors.grey,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 5),
          Text(
            episode.title(),
            style: TextStyle(
              color: PlatformBrightness.isLightMode(context)
                  ? Colors.black
                  : Colors.white,
              fontSize: 16,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(
            height: 5,
          ),
          Row(
            children: [
              PlayAndPauseButton(
                episode: episode,
                audioPlayer: audioPlayer,
              ),
              const SizedBox(width: 6),
              if (episode.duration() != null) Text(duration(episode)),
            ],
          ),
        ],
      ),
    );
  }

  String episodeAndDate(PodcastEpisode episode) {
    final hasEpNum = episode.episodeNum() != null;
    final date = episode.datePublished().toUpperCase().split(",")[0];
    return hasEpNum
        ? "Ep. " + episode.episodeNum().toString() + " · " + date
        : date;
  }

  String duration(PodcastEpisode episode) {
    final minutes = (episode.duration()! / 60);
    final shouldShowHourDisplay = minutes >= 60;
    return (shouldShowHourDisplay
        ? formatDurationAsHours(minutes)
        : formatDurationAsMinutes(minutes));
  }

  String formatDurationAsMinutes(num minutes) {
    final _minutes = minutes.round();
    return _minutes.toString() + " minute" + (_minutes > 1 ? "s" : "");
  }

  String formatDurationAsHours(num minutes) {
    final hours = (minutes / 60).floor();
    return hours.toString() +
        " hour" +
        (hours > 1 ? "s " : " ") +
        formatDurationAsMinutes(minutes - (hours * 60));
  }
}

class AudioPlayer {
  final JA.AudioPlayer _player;
  final BehaviorSubject<PodcastEpisode?> _currentEpisodeStream =
      BehaviorSubject.seeded(null);
  bool _playing = false;
  final BehaviorSubject<List<PodcastEpisode>> _history =
      BehaviorSubject.seeded([]);
  AudioPlayer({required JA.AudioPlayer audioPlayer}) : _player = audioPlayer;

  bool get isPlaying => _playing; // ignore native controls for now.

  bool isStreamingEpisode({required PodcastEpisode episode}) {
    return _currentEpisodeStream.value?.id() == episode.id();
  }

  Stream<PodcastEpisode?> currentEpisodeStreaming() {
    return _currentEpisodeStream;
  }

  Future<void> load({required PodcastEpisode episode}) async {
    await _player.setUrl(episode.enclosureUrl());
  }

  void play({required PodcastEpisode episode}) {
    if (!isStreamingEpisode(episode: episode)) {
      _history.add([..._history.value, episode]);
      _currentEpisodeStream.add(episode);
      load(episode: episode);
    }
    _playing = true;
    _player.play();
  }

  Future<void> pause() async {
    _playing = false;
    await _player.pause();
  }

  List<PodcastEpisode> playHistroy() {
    return [..._history.value];
  }

  /// live history updates
  Stream<List<PodcastEpisode>> playHistroyStream() {
    return _history;
  }

  /// live updates of audio positions & states.
  /// - episdode duration
  /// - buffer position (loaded ahead time)
  /// - posistion within current episode
  /// - loading state
  Stream<EpisodeAudioPosition> episodeAudioPosition() {
    return CombineLatestStream.combine4<Duration, Duration, Duration?,
            JA.PlayerState, EpisodeAudioPosition>(
        _player.positionStream,
        _player.bufferedPositionStream,
        _player.durationStream,
        _player.playerStateStream, (a, b, c, d) {
      return EpisodeAudioPosition(
        position: a,
        bufferPosition: b,
        episodeDuration: c ?? Duration.zero,
        playerState: d,
      );
    });
  }

  void skipForward({required Duration duration}) {
    _player.seek(
      Duration(seconds: _player.position.inSeconds + duration.inSeconds),
    );
  }

  void replay({required Duration duration}) {
    _player.seek(
      Duration(seconds: _player.position.inSeconds - duration.inSeconds),
    );
  }

  Future<void> dispose() async {
    await _currentEpisodeStream.close();
    await _player.stop();
    await _player.dispose();
  }
}

class EpisodeAudioPosition {
  final Duration position;
  final Duration bufferPosition;
  final Duration episodeDuration;
  final JA.PlayerState _playerState;
  EpisodeAudioPosition({
    required this.position,
    required this.bufferPosition,
    required this.episodeDuration,
    required JA.PlayerState playerState,
  }) : _playerState = playerState;

  isLoading() {
    final processingState = _playerState.processingState;
    return processingState == JA.ProcessingState.loading ||
        processingState == JA.ProcessingState.buffering;
  }

  factory EpisodeAudioPosition.initial() {
    return EpisodeAudioPosition(
      position: Duration.zero,
      bufferPosition: Duration.zero,
      episodeDuration: Duration.zero,
      playerState: JA.PlayerState(false, JA.ProcessingState.loading),
    );
  }
}

class PlayAndPauseButton extends StatefulWidget {
  final AudioPlayer audioPlayer;
  final PodcastEpisode episode;
  const PlayAndPauseButton({
    required this.audioPlayer,
    required this.episode,
    Key? key,
  }) : super(key: key);

  @override
  State<PlayAndPauseButton> createState() => _PlayAndPauseButtonState();
}

class _PlayAndPauseButtonState extends State<PlayAndPauseButton> {
  late final Stream<PodcastEpisode?> _currentEpisodePlaying;

  @override
  void initState() {
    _currentEpisodePlaying = widget.audioPlayer.currentEpisodeStreaming();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final ap = widget.audioPlayer;
    final episode = widget.episode;

    return StreamBuilder<PodcastEpisode?>(
        stream: _currentEpisodePlaying,
        builder: (context, snapshot) {
          return InkWell(
            onTap: () async {
              final episodeCurrentlyPaying = snapshot.data;
              final isStreamingEpisodeForThisButton =
                  episodeCurrentlyPaying != null &&
                      ap.isStreamingEpisode(episode: widget.episode);

              if (!isStreamingEpisodeForThisButton) {
                ap.play(episode: episode);
              }
              if (isStreamingEpisodeForThisButton && ap.isPlaying) {
                ap.pause();
              } else {
                ap.play(episode: episode);
              }
              setState(() {});
            },
            child: Container(
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
              ),
              child: Icon(
                buildIcon(ap, episode),
                color: Colors.black,
              ),
            ),
          );
        });
  }

  buildIcon(AudioPlayer ap, PodcastEpisode ep) {
    return ap.isStreamingEpisode(episode: ep)
        ? ap.isPlaying
            ? Icons.pause
            : Icons.play_arrow
        : Icons.play_arrow;
  }
}

class SeeAll extends StatelessWidget {
  /// [emptyState] will display when [itemCount] == 0
  final Widget emptyState;
  final Widget Function(BuildContext, int) itemBuilder;
  final String title;
  final int itemCount;
  const SeeAll({
    required this.title,
    required this.itemBuilder,
    required this.itemCount,
    this.emptyState = const SizedBox.shrink(),
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(
        textScaleFactor: createTextScaleFactor(context),
      ),
      child: Scaffold(
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(
                height: 22,
              ),
              Padding(
                padding: const EdgeInsets.only(left: 15.0),
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(
                height: 22,
              ),
              itemCount == 0
                  ? emptyState
                  : Expanded(
                      child: ListView.separated(
                        itemCount: itemCount,
                        separatorBuilder: (context, index) => const Divider(),
                        itemBuilder: itemBuilder,
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
