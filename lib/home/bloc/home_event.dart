import 'package:equatable/equatable.dart';

abstract class HomeEvent extends Equatable {
  @override
  List<Object> get props => [];
}

class LoadHomeDataEvent extends HomeEvent {}

class RefreshSensorDataEvent extends HomeEvent {}

class RefreshSensorReadingsOnlyEvent extends HomeEvent {}

class MarkNotificationAsReadEvent extends HomeEvent {
  final String notificationId;

  MarkNotificationAsReadEvent({required this.notificationId});

  @override
  List<Object> get props => [notificationId];
}
