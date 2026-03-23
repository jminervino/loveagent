import 'package:equatable/equatable.dart';

class Surprise extends Equatable {
  const Surprise({
    required this.id,
    required this.partnerId,
    required this.type,
    required this.date,
    this.note,
    this.suggestedByAgent = false,
    this.confirmedByUser = false,
    this.partnerName,
  });

  final String id;
  final String partnerId;
  final String type;
  final DateTime date;
  final String? note;
  final bool suggestedByAgent;
  final bool confirmedByUser;
  final String? partnerName;

  String get typeLabel {
    switch (type) {
      case 'flores':
        return 'Flores';
      case 'jantar':
        return 'Jantar';
      case 'presente':
        return 'Presente';
      case 'carta':
        return 'Carta / Mensagem';
      case 'experiencia':
        return 'Experiência';
      case 'viagem':
        return 'Viagem';
      case 'outro':
        return 'Outro';
      default:
        return type;
    }
  }

  String get typeEmoji {
    switch (type) {
      case 'flores':
        return '💐';
      case 'jantar':
        return '🍽️';
      case 'presente':
        return '🎁';
      case 'carta':
        return '💌';
      case 'experiencia':
        return '🎯';
      case 'viagem':
        return '✈️';
      case 'outro':
        return '❤️';
      default:
        return '❤️';
    }
  }

  @override
  List<Object?> get props => [id, partnerId, type, date];
}

const surpriseTypes = [
  'flores',
  'jantar',
  'presente',
  'carta',
  'experiencia',
  'viagem',
  'outro',
];
