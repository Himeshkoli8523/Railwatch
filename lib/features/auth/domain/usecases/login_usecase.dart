import 'package:cctv/features/auth/domain/repositories/auth_repository.dart';

class LoginUseCase {
  const LoginUseCase(this.repository);

  final AuthRepository repository;

  Future<bool> call({required String phoneNo, required String password}) {
    return repository.login(phoneNo: phoneNo, password: password);
  }
}
