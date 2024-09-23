import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:webtoon_naver/models/webtoon_detail_model.dart';
import 'package:webtoon_naver/models/webtoon_episode_model.dart';
import 'package:webtoon_naver/models/webtoon_model.dart';
import 'package:webtoon_naver/services/api_service.dart';
import 'package:webtoon_naver/widgets/episode_widget.dart';

class DetailScreen extends StatefulWidget {
  final WebtoonModel webtoon;
  const DetailScreen({super.key, required this.webtoon});

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  late Future<WebtoonDetailModel> webtoonDetail;
  late Future<List<WebtoonEpisodeModel>> episodes;
  late SharedPreferences prefs;
  static const LikedToons = 'likedToons';
  bool isLiked = false;

  Future initPrefs() async {
    prefs = await SharedPreferences.getInstance();
    final likedToons = prefs.getStringList(LikedToons);
    if (likedToons != null) {
      if (likedToons.contains(widget.webtoon.id) == true) {
        setState(() {
          isLiked = true;
        });
      }
    } else {
      prefs.setStringList(LikedToons, []);
    }
  }

  @override
  void initState() {
    super.initState();
    webtoonDetail = ApiService.getToonById(widget.webtoon.id);
    episodes = ApiService.getLatestEpisodesById(widget.webtoon.id);
    initPrefs();
  }

  onHeartTap() async {
    final likedToons = prefs.getStringList(LikedToons);
    if (likedToons != null) {
      if (isLiked) {
        likedToons.remove(widget.webtoon.id);
      } else {
        likedToons.add(widget.webtoon.id);
      }
      await prefs.setStringList(LikedToons, likedToons);
      setState(() {
        isLiked = !isLiked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        elevation: 2,
        surfaceTintColor: Colors.white,
        shadowColor: Colors.black,
        foregroundColor: Colors.green,
        backgroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: onHeartTap,
            icon: Icon(isLiked
                ? Icons.favorite_outlined
                : Icons.favorite_outline_outlined),
          ),
        ],
        title: Text(
          widget.webtoon.title,
          style: const TextStyle(
            fontSize: 24,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(50),
        child: SingleChildScrollView(
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Hero(
                    tag: widget.webtoon.id,
                    child: Container(
                      width: 250,
                      clipBehavior: Clip.hardEdge,
                      decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(15),
                          boxShadow: [
                            BoxShadow(
                              blurRadius: 15,
                              offset: const Offset(10, 10),
                              color: Colors.black.withOpacity(0.4),
                            )
                          ]),
                      child: Image.network(
                        widget.webtoon.thumb,
                        headers: const {'Referer': 'https://comic.naver.com'},
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(
                height: 25,
              ),
              FutureBuilder(
                future: webtoonDetail,
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          snapshot.data!.about,
                          style: const TextStyle(
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(
                          height: 15,
                        ),
                        Text(
                          '${snapshot.data!.genre} / ${snapshot.data!.age}',
                          style: const TextStyle(
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(
                          height: 25,
                        ),
                      ],
                    );
                  }
                  return const CircularProgressIndicator.adaptive();
                },
              ),
              FutureBuilder(
                future: episodes,
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    return Column(
                      children: [
                        for (var episode in snapshot.data!)
                          Episodes(
                              episode: episode, webtoonId: widget.webtoon.id)
                      ],
                    );
                  }
                  return Container();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
