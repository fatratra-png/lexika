//A message that the user can read
sealed class AppException implements Exception {
  const AppException(this.message);

  final String message;

  @override
  String toString() => message;
}

//Invalid data (HTTP~400)
final class ValidationException extends AppException {
  const ValidationException(super.message);
}

//Not found (HTTP~404)
final class NotFoundException extends AppException {
  const NotFoundException(super.message);
}
