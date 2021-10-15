import 'dart:async';
import 'dart:math';
import 'package:flutter/gestures.dart';
import 'package:flutter/rendering.dart';
import 'package:fountain_tech_test/domain/account.dart';
import 'package:fountain_tech_test/domain/audio_player.dart';
import 'package:fountain_tech_test/view/account_page.dart';
import 'package:fountain_tech_test/view/components/play_and_pause_button.dart';
import 'package:fountain_tech_test/view/discover_page.dart';
import 'package:fountain_tech_test/view/home_page.dart';
import 'package:fountain_tech_test/view/episode_page.dart';
import 'package:fountain_tech_test/view/playlists_page.dart';
import 'package:fountain_tech_test/view/components/playlist_bottom_sheet.dart';
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
          HomePage(
            account: account!,
            audioPlayer: widget.audioPlayer,
            bottomNavigationState: bottomNavigationState,
          ),
          DiscoverPage(
            audioPlayer: widget.audioPlayer,
            account: account!,
          ),
          PlaylistsPage(
            account: account!,
            audioPlayer: widget.audioPlayer,
          ),
          AccountPage(
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
