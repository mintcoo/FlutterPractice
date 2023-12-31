import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:webtoonapp/models/webtoon_detail_model.dart';
import 'package:webtoonapp/models/webtoon_episode_model.dart';

import 'package:webtoonapp/models/webtoon_model.dart';
import 'package:webtoonapp/services/api_service.dart';
import 'package:webtoonapp/widgets/episode_widget.dart';

class DetailWebtoon extends StatefulWidget {
  final WebtoonModel webtoon;

  const DetailWebtoon({
    super.key,
    required this.webtoon,
  });

  @override
  State<DetailWebtoon> createState() => _DetailWebtoonState();
}

class _DetailWebtoonState extends State<DetailWebtoon> {
  late Future<WebtoonDetailModel> webtoonDetail;
  late Future<List<WebtoonEpisodeModel>> webtoonEpisodes;
  late SharedPreferences prefs;
  // 폰에 관리할 좋아요 목록
  bool isLiked = false;

  bool isExpanded = false;

  void onClick() {
    setState(() {
      isExpanded = !isExpanded;
    });
  }

  Future initPref() async {
    prefs = await SharedPreferences.getInstance();
    final likedToons = prefs.getStringList('likedToons');
    if (likedToons != null) {
      if (likedToons.contains(widget.webtoon.id) == true) {
        setState(() {
          // UI를 refresh 해줘야함
          isLiked = true;
        });
      }
    } else {
      await prefs.setStringList("likedToons", []);
      // 사용자가 처음 앱 실행시 만들어줌
    }
  }

  onHeartTap() async {
    final likedToons = prefs.getStringList('likedToons');
    if (likedToons != null) {
      if (isLiked) {
        likedToons.remove(widget.webtoon.id);
      } else {
        likedToons.add(widget.webtoon.id);
      }
      await prefs.setStringList('likedToons', likedToons);
      // 수정된 리스트를 폰에 다시 저장
      setState(() {
        isLiked = !isLiked;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    webtoonDetail = ApiService.getToonById(widget.webtoon.id);
    webtoonEpisodes = ApiService.getEpisodesById(widget.webtoon.id);
    initPref();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        centerTitle: true,
        elevation: 2,
        backgroundColor: Colors.white,
        foregroundColor: Colors.green,
        actions: [
          IconButton(
            onPressed: onHeartTap,
            icon: isLiked
                ? const Icon(Icons.favorite)
                : const Icon(Icons.favorite_outline_outlined),
          ),
        ],
        title: Text(
          widget.webtoon.title,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w400,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 50,
            vertical: 50,
          ),
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
                              blurRadius: 10,
                              offset: const Offset(7, 7),
                              color: Colors.black.withOpacity(0.5),
                            )
                          ]),
                      child: Image.network(
                        widget.webtoon.thumb,
                        headers: const {
                          "User-Agent":
                              "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/110.0.0.0 Safari/537.36",
                        },
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(
                height: 20,
              ),
              FutureBuilder(
                future: webtoonDetail,
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        GestureDetector(
                          onTap: onClick,
                          child: Text(
                            maxLines: isExpanded ? null : 7,
                            overflow: isExpanded ? null : TextOverflow.ellipsis,
                            snapshot.data!.about,
                            style: const TextStyle(
                              fontSize: 14,
                            ),
                          ),
                        ),
                        const SizedBox(
                          height: 20,
                        ),
                        Text(
                          "${snapshot.data!.genre} / ${snapshot.data!.age}",
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    );
                  }
                  return const Center(
                    heightFactor: 3,
                    child: CircularProgressIndicator(),
                    // 로딩할때 가운데 뜨는 프로그래스바
                  );
                },
              ),
              const SizedBox(
                height: 20,
              ),
              FutureBuilder(
                future: webtoonEpisodes,
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    // ListView를 안쓰는 이유는 오히려 신경쓸게 많기도 하고 10개정도의 가벼운 작업은 그냥 column이 낫다
                    // 최적화가 필요하거나 리스트가 길거나하면 리스트뷰가 필수
                    return Column(
                      children: [
                        for (var episode in snapshot.data!)
                          Episode(
                            episode: episode,
                            webtoonId: widget.webtoon.id,
                          )
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
