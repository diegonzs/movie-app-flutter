import 'dart:async';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:movie_app_fluuter/helpers/debouncer.dart';
import 'package:movie_app_fluuter/models/models.dart';
import 'package:movie_app_fluuter/models/movie.dart';
import 'package:movie_app_fluuter/models/now_playing_response.dart';
import 'package:movie_app_fluuter/models/popular_response.dart';
import 'package:movie_app_fluuter/models/search_response.dart';

class MoviesProvider extends ChangeNotifier {
  String _baseUrl = 'api.themoviedb.org';
  String _apiKey = '1d6faafaeecc859d72c39187cb39f4b5';
  String _language = 'es-ES';

  List<Movie> onDisplayMovies = [];
  List<Movie> popularMovies = [];
  Map<int, List<Cast>> moviesCast = {};

  int _popularPage = 0;
  bool _fetchingData = false;

  final debouncer = Debouncer(duration: Duration(microseconds: 500));

  final StreamController<List<Movie>> _suggestionStreamController =
      new StreamController.broadcast();

  Stream<List<Movie>> get suggestionStream =>
      this._suggestionStreamController.stream;

  MoviesProvider() {
    this.getOnDisplayMovies();
    this.getPopularMovies();
  }

  Future<String> _getJsonData(String segment, [int page = 1]) async {
    final Uri url = Uri.https(
      _baseUrl,
      segment,
      {'api_key': _apiKey, 'language': _language, 'page': page.toString()},
    );
    final response = await http.get(url);
    return response.body;
  }

  getOnDisplayMovies() async {
    final jsonData = await _getJsonData('3/movie/now_playing');
    final nowPlayingResponse = NowPlayingResponse.fromJson(jsonData);
    onDisplayMovies = nowPlayingResponse.results;
    notifyListeners();
  }

  getPopularMovies() async {
    if (!_fetchingData) {
      _fetchingData = true;
      _popularPage++;
      final jsonData = await _getJsonData('3/movie/popular', _popularPage);
      final popularResponse = PopularResponse.fromJson(jsonData);
      popularMovies = [...popularMovies, ...popularResponse.results];
      print(popularMovies[0].id);
      _fetchingData = false;
      notifyListeners();
    }
  }

  Future<List<Cast>> getMovieCast(int movieId) async {
    if (moviesCast.containsKey(movieId)) return moviesCast[movieId]!;
    final jsonData = await _getJsonData('3/movie/$movieId/credits');
    final creditsResopnse = CreditsResponse.fromJson(jsonData);
    moviesCast[movieId] = creditsResopnse.cast;
    return creditsResopnse.cast;
  }

  Future<List<Movie>> searchMovies(String query) async {
    final Uri url = Uri.https(
      _baseUrl,
      '3/search/movie',
      {'api_key': _apiKey, 'language': _language, 'query': query},
    );
    final response = await http.get(url);
    final searchResponse = SearchResponse.fromJson(response.body);
    return searchResponse.results;
  }

  void getSuggestionsByQuery(String searchTerm) {
    // debounce
  }
}
