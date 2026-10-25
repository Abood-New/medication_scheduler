abstract class Failure {
  final String message;
  const Failure(this.message);
}

class DatabaseFailure extends Failure {
  const DatabaseFailure(super.message);
}

class NotificationFailure extends Failure {
  const NotificationFailure(super.message);
}

class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}

class NotFoundFailure extends Failure {
  const NotFoundFailure(super.message);
}

class ScheduleFailure extends Failure {
  const ScheduleFailure(super.message);
}