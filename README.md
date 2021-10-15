## Getting Started

run `flutter run` 

## App Bar

Screen sizes with different text scale factor (TCF):

| iphone 13 with TCF at 1.0x | iphone 18 with TCF at 1.0x |
| ----------- | ----------- |
|<img width="513" alt="Screenshot 2021-10-15 at 18 47 56" src="https://user-images.githubusercontent.com/45692434/137531442-ad6418e5-939f-40c4-9ec6-6b8f5620ad97.png">|<img width="513" alt="Screenshot 2021-10-15 at 18 55 03" src="https://user-images.githubusercontent.com/45692434/137531644-41b28401-49fd-4d16-adc7-d72b0dbddcd3.png">|
|1.5x TCF| 1.5x TCF|
|<img width="513" alt="Screenshot 2021-10-15 at 18 55 59" src="https://user-images.githubusercontent.com/45692434/137531804-03d6692e-16b4-4743-9911-a9ac0998de8b.png">|<img width="513" alt="Screenshot 2021-10-15 at 18 56 12" src="https://user-images.githubusercontent.com/45692434/137531817-4948f63e-2e9d-4fb2-873c-c9ca8a65dc95.png">|

The source code for the app bar can be found in the file: `lib/fount_test_app_bar.dart`
The app handles different text scale factors by clamping the range between 1.0 and 1.5:

```dart
double createTextScaleFactor(BuildContext context) {
  return MediaQuery.of(context).textScaleFactor.clamp(1.0, 1.5);
}
```
Generally I've found that many apps don't account for TCF, if they do, I've found they either:
- Don't react at all - stay at 1.0x despite mobile settings
- Clamp between a range. It's clear once the text becomes over a certain size, you need to redesign most of the app to account for the TCF increase. Clamping prevents the text becoming too large to justify the redesign.


## Podcast App

**To Run:** comment lines 36-39 in and uncomment lines 40-50 in `lib/main.dart` then run `flutter run`

The podcast app is an **in memory** audio application that provides the basic features such as:
- search
- audio streaming
- audio controls e.g. fast forward 30secs
- playlist creation
- ...more

The podcast app integrates with [Podcast Index](https://podcastindex.org/) to provide search, trending, and audio files to be consumed within the app.
The following enpoints are used in the app:
- [GET /search/byterm](https://podcastindex-org.github.io/docs-api/#get-/search/byterm)
- [GET /episodes/byfeedid](https://podcastindex-org.github.io/docs-api/#get-/episodes/byfeedid)
- [GET /podcasts/trending](https://podcastindex-org.github.io/docs-api/#get-/podcasts/trending)
- [GET /podcasts/byfeedid](https://podcastindex-org.github.io/docs-api/#get-/podcasts/byfeedid)

You can find the implementation details for the above endpoints in `lib/data/podcast_index_dot_org.dart`


The app supports both light and dark mode with a TCF range of 1.0x - 1.5x:

| iphone 12 light mode | iphone 12 dark mode |
| ----------- | ----------- |
|<img width="472" alt="Screenshot 2021-10-15 at 19 11 04" src="https://user-images.githubusercontent.com/45692434/137534248-0ee83897-e3c0-4f99-82df-b44c26812f86.png">|<img width="516" alt="Screenshot 2021-10-15 at 19 19 16" src="https://user-images.githubusercontent.com/45692434/137534314-9350dc39-57ca-4151-b8a5-04f5aae00f93.png">|


#### Images
||||
| ----------- | ----------- | ----------- |
|<img width="516" alt="Screenshot 2021-10-15 at 19 28 32" src="https://user-images.githubusercontent.com/45692434/137535612-68f128ee-0abf-4daa-a6f3-0c024902d1e9.png">|<img width="516" alt="Screenshot 2021-10-15 at 19 27 07" src="https://user-images.githubusercontent.com/45692434/137535625-9581c4e4-86ce-4c1c-bb2a-dc1d32b209a7.png">|<img width="472" alt="Screenshot 2021-10-15 at 19 24 38" src="https://user-images.githubusercontent.com/45692434/137535643-b46385a0-9c81-43cf-a9e4-a20af4bba1c3.png">|<img width="472" alt="Screenshot 2021-10-15 at 19 24 38" src="https://user-images.githubusercontent.com/45692434/137535643-b46385a0-9c81-43cf-a9e4-a20af4bba1c3.png">|<img width="516" alt="Screenshot 2021-10-15 at 19 25 41" src="https://user-images.githubusercontent.com/45692434/137535682-b47399bf-dba7-4149-903d-1da6bfbe4e0a.png">|<img width="516" alt="Screenshot 2021-10-15 at 19 26 33" src="https://user-images.githubusercontent.com/45692434/137535705-3a35c298-d360-4007-9e53-7b20f41a53d1.png">|
<img width="516" alt="Screenshot 2021-10-15 at 19 28 13" src="https://user-images.githubusercontent.com/45692434/137535716-8b8cc202-db3f-4270-afff-e5e30d4d9a1a.png">|<img width="516" alt="Screenshot 2021-10-15 at 19 35 21" src="https://user-images.githubusercontent.com/45692434/137536205-2fc0d433-690b-4399-8c95-4e319f667536.png">|<img width="516" alt="Screenshot 2021-10-15 at 19 35 37" src="https://user-images.githubusercontent.com/45692434/137536242-07480a44-8db8-4748-8a79-8142dd5d42fe.png">|







