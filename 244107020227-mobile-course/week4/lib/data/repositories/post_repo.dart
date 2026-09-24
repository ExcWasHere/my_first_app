import 'package:dio/dio.dart';
import '../models/post.dart';

class PostRepository {
  PostRepository(this._dio);
  final Dio _dio;

  Future<List<Post>> fetchPosts() async {
    final response = await _dio.get<List>('/posts');
    final data = response.data ?? [];
    return data.whereType<Map<String, dynamic>>().map(Post.fromJson).toList();
  }

  Future<List<Post>> fetchPostsPage({required int page, int limit = 10}) async {
    final response = await _dio.get<List>(
      '/posts',
      queryParameters: {'_page': page, '_limit': limit},
    );
    final data = response.data ?? [];
    return data.whereType<Map<String, dynamic>>().map(Post.fromJson).toList();
  }
  Future<Post> fetchPostById(int id) async {
    final response = await _dio.get<Map<String, dynamic>>('/posts/$id');
    final data = response.data;
    if (data == null) {
      throw DioException(
        requestOptions: RequestOptions(path: '/posts/$id'),
        type: DioExceptionType.badResponse,
        response: Response(
          requestOptions: RequestOptions(path: '/posts/$id'),
          statusCode: 404,
        ),
      );
    }
    return Post.fromJson(data);
  }
}