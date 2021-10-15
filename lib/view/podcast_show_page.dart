import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:fountain_tech_test/data/podcast_index_dot_org.dart';
import 'package:fountain_tech_test/domain/account.dart';
import 'package:fountain_tech_test/domain/audio_player.dart';
import 'package:fountain_tech_test/fount_test_app_bar.dart' as FTAB;
import 'package:fountain_tech_test/main.dart';
import 'package:fountain_tech_test/view/components/tiles/podcast_episode_list_tile.dart';
import 'package:palette_generator/palette_generator.dart';

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
        textScaleFactor: FTAB.createTextScaleFactor(context),
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
                                      return PodcastEpisodeListItemTile(
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
