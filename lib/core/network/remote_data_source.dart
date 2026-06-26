import 'dio_client.dart';

abstract class RemoteDataSource {
  final DioClient client;
  RemoteDataSource(this.client);
}
